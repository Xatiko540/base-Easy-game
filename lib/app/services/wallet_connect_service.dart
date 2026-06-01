import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3/ethereum.dart';
import 'package:get/get.dart';

class WalletConnectService extends GetxController {
  static const int baseSepoliaChainId = 84532;
  static const String paymentReceiver =
      String.fromEnvironment('PAYMENT_RECEIVER');
  static const String easyGameContractAddress =
      String.fromEnvironment('EASY_GAME_ADDRESS');
  static const String easyGameInviter =
      String.fromEnvironment('EASY_GAME_INVITER');
  static const String _zeroAddress =
      '0x0000000000000000000000000000000000000000';

  final RxString currentAddress = ''.obs;
  final RxBool isConnected = false.obs;
  final RxnInt chainId = RxnInt();
  final RxBool isConnecting = false.obs;
  final RxBool isPaying = false.obs;
  final RxString easyGameAddress = ''.obs;

  bool get isWalletAvailable => ethereum != null;

  String get shortAddress {
    final address = currentAddress.value;
    if (address.length <= 12) {
      return address;
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  void onInit() {
    super.onInit();
    _restoreConnection();
    _listenWalletChanges();
  }

  Future<void> connectWallet() async {
    if (!isWalletAvailable) {
      throw Exception('MetaMask or another Web3 wallet is not installed');
    }

    isConnecting.value = true;
    try {
      final accounts = await ethereum!.requestAccount();
      _setAccounts(accounts);
      await refreshChainId();
    } catch (e) {
      disconnectWallet();
      rethrow;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> ensureBaseSepolia() async {
    if (!isWalletAvailable) {
      throw Exception('MetaMask or another Web3 wallet is not installed');
    }

    await refreshChainId();
    if (chainId.value == baseSepoliaChainId) {
      return;
    }

    await ethereum!.walletSwitchChain(baseSepoliaChainId, () async {
      await ethereum!.walletAddChain(
        chainId: baseSepoliaChainId,
        chainName: 'Base Sepolia',
        nativeCurrency: CurrencyParams(
          name: 'Sepolia Ether',
          symbol: 'ETH',
          decimals: 18,
        ),
        rpcUrls: ['https://sepolia.base.org'],
        blockExplorerUrls: ['https://sepolia.basescan.org'],
      );
    });
    await refreshChainId();
  }

  Future<String> sendNativePayment({
    required double amountEther,
    String? to,
  }) async {
    final receiver = to ?? paymentReceiver;
    if (receiver.isEmpty) {
      throw Exception(
        'Payment receiver is not configured. Build with --dart-define=PAYMENT_RECEIVER=0x...',
      );
    }

    if (!isConnected.value) {
      await connectWallet();
    }
    await ensureBaseSepolia();

    isPaying.value = true;
    try {
      final txHash = await ethereum!.request<String>('eth_sendTransaction', [
        {
          'from': currentAddress.value,
          'to': receiver,
          'value': _etherToHexWei(amountEther),
        }
      ]);
      return txHash;
    } finally {
      isPaying.value = false;
    }
  }

  Future<String> activateEasyGameLevel({
    required int level,
    double? amountEther,
    BigInt? amountWei,
    String? inviter,
  }) async {
    if (level < 1 || level > 17) {
      throw Exception('Invalid Easy Game level');
    }

    if (!isConnected.value) {
      await connectWallet();
    }
    await ensureBaseSepolia();

    final contractAddress = await resolveEasyGameAddress();
    final inviterAddress = _normalizeAddress(
      inviter?.isNotEmpty == true ? inviter! : easyGameInviter,
    );
    final paymentWei = amountWei ?? await getEasyGameLevelPriceWei(level);

    isPaying.value = true;
    try {
      final txHash = await ethereum!.request<String>('eth_sendTransaction', [
        {
          'from': currentAddress.value,
          'to': contractAddress,
          'value': _bigIntToHex(paymentWei),
          'data': _activateLevelCallData(level, inviterAddress),
        }
      ]);
      return txHash;
    } finally {
      isPaying.value = false;
    }
  }

  Future<BigInt> getEasyGameLevelPriceWei(int level) async {
    final response = await _easyGameCall(
      '0x2e50d906${level.toRadixString(16).padLeft(64, '0')}',
    );
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<EasyGameLevelState> getEasyGameLevel({
    String? playerAddress,
    required int level,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final response = await _easyGameCall(
      _encodeAddressUint8Call('a0978ac2', address, level),
    );
    final words = _decodeWords(response);

    return EasyGameLevelState(
      active: _wordToBool(words[0]),
      frozen: _wordToBool(words[1]),
      cycles: _wordToBigInt(words[2]),
      positionId: _wordToBigInt(words[3]),
      earnedWei: _wordToBigInt(words[4]),
    );
  }

  Future<bool> isEasyGameLevelActive({
    String? playerAddress,
    required int level,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final response = await _easyGameCall(
      _encodeAddressUint8Call('75b7d7c1', address, level),
    );
    return _wordToBool(_decodeWords(response).first);
  }

  Future<bool> isEasyGameLevelFrozen({
    String? playerAddress,
    required int level,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final response = await _easyGameCall(
      _encodeAddressUint8Call('0e475efd', address, level),
    );
    return _wordToBool(_decodeWords(response).first);
  }

  Future<EasyGameMatrixStats> getEasyGameMatrixStats(int level) async {
    final response = await _easyGameCall(
      '0xb9aee263${level.toRadixString(16).padLeft(64, '0')}',
    );
    final words = _decodeWords(response);
    return EasyGameMatrixStats(
      size: _wordToBigInt(words[0]),
      nextOpenParentId: _wordToBigInt(words[1]),
    );
  }

  Future<String> resolveEasyGameAddress() async {
    if (easyGameContractAddress.isNotEmpty) {
      easyGameAddress.value = easyGameContractAddress;
      return easyGameContractAddress;
    }

    if (easyGameAddress.value.isNotEmpty) {
      return easyGameAddress.value;
    }

    await refreshChainId();
    try {
      final artifact =
          jsonDecode(await rootBundle.loadString('src/artifacts/EasyGame.json'))
              as Map<String, dynamic>;
      final networks = artifact['networks'] as Map<String, dynamic>? ?? {};
      final chainKey = '${chainId.value ?? baseSepoliaChainId}';
      final network = networks[chainKey] as Map<String, dynamic>?;
      final address = network?['address'] as String?;

      if (address == null || address.isEmpty) {
        throw Exception(
          'EasyGame contract is not deployed for chain $chainKey. Deploy it or build with --dart-define=EASY_GAME_ADDRESS=0x...',
        );
      }

      easyGameAddress.value = address;
      return address;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Unable to load EasyGame artifact. Run hardhat compile/deploy or build with --dart-define=EASY_GAME_ADDRESS=0x...',
      );
    }
  }

  void disconnectWallet() {
    currentAddress.value = '';
    isConnected.value = false;
  }

  Future<void> refreshChainId() async {
    if (!isWalletAvailable) {
      chainId.value = null;
      return;
    }

    try {
      chainId.value = await ethereum!.getChainId();
    } catch (e) {
      if (kDebugMode) {
        print('Unable to read wallet chain id: $e');
      }
    }
  }

  Future<void> _restoreConnection() async {
    if (!isWalletAvailable) {
      return;
    }

    try {
      _setAccounts(await ethereum!.getAccounts());
      await refreshChainId();
    } catch (e) {
      if (kDebugMode) {
        print('Unable to restore wallet connection: $e');
      }
    }
  }

  void _listenWalletChanges() {
    if (!isWalletAvailable) {
      return;
    }

    ethereum!.onAccountsChanged((accounts) {
      _setAccounts(accounts);
    });
    ethereum!.onChainChanged((newChainId) {
      chainId.value = newChainId;
    });
  }

  void _setAccounts(List<String> accounts) {
    if (accounts.isEmpty) {
      disconnectWallet();
      return;
    }

    currentAddress.value = accounts.first;
    isConnected.value = true;
  }

  String _etherToHexWei(double amountEther) {
    final fixed = amountEther.toStringAsFixed(18);
    final parts = fixed.split('.');
    final whole = BigInt.parse(parts.first);
    final fraction = (parts.length > 1 ? parts[1] : '').padRight(18, '0');
    final wei = whole * BigInt.from(10).pow(18) + BigInt.parse(fraction);
    return _bigIntToHex(wei);
  }

  String _bigIntToHex(BigInt value) => '0x${value.toRadixString(16)}';

  String _activateLevelCallData(int level, String inviterAddress) {
    const selector = '48d46be1';
    final encodedLevel = level.toRadixString(16).padLeft(64, '0');
    final encodedInviter =
        inviterAddress.replaceFirst('0x', '').padLeft(64, '0');
    return '0x$selector$encodedLevel$encodedInviter';
  }

  Future<String> _easyGameCall(String data) async {
    if (!isWalletAvailable) {
      throw Exception('MetaMask or another Web3 wallet is not installed');
    }

    final contractAddress = await resolveEasyGameAddress();
    final result = await ethereum!.request<String>('eth_call', [
      {
        'to': contractAddress,
        'data': data,
      },
      'latest',
    ]);

    return result;
  }

  String _encodeAddressUint8Call(String selector, String address, int value) {
    if (value < 0 || value > 255) {
      throw Exception('Invalid uint8 value');
    }

    final encodedAddress = address.replaceFirst('0x', '').padLeft(64, '0');
    final encodedValue = value.toRadixString(16).padLeft(64, '0');
    return '0x$selector$encodedAddress$encodedValue';
  }

  List<String> _decodeWords(String response) {
    final clean = response.replaceFirst('0x', '');
    if (clean.isEmpty || clean.length % 64 != 0) {
      throw Exception('Invalid contract response');
    }

    return [
      for (var i = 0; i < clean.length; i += 64) clean.substring(i, i + 64),
    ];
  }

  bool _wordToBool(String word) => BigInt.parse(word, radix: 16) == BigInt.one;

  BigInt _wordToBigInt(String word) => BigInt.parse(word, radix: 16);

  String _normalizeAddress(String address) {
    if (address.isEmpty) {
      return _zeroAddress;
    }

    final normalized = address.toLowerCase();
    if (!RegExp(r'^0x[a-f0-9]{40}$').hasMatch(normalized)) {
      throw Exception('Invalid inviter address');
    }
    return normalized;
  }
}

class EasyGameLevelState {
  final bool active;
  final bool frozen;
  final BigInt cycles;
  final BigInt positionId;
  final BigInt earnedWei;

  const EasyGameLevelState({
    required this.active,
    required this.frozen,
    required this.cycles,
    required this.positionId,
    required this.earnedWei,
  });
}

class EasyGameMatrixStats {
  final BigInt size;
  final BigInt nextOpenParentId;

  const EasyGameMatrixStats({
    required this.size,
    required this.nextOpenParentId,
  });
}
