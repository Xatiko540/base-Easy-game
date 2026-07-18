import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wagmi_web/wagmi_web.dart' as wagmi;
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';
import 'app_config_service.dart';

class AppNetworkConfig {
  final int chainId;
  final String chainName;
  final String displayName;
  final String currencyName;
  final String currencySymbol;
  final String rpcUrl;
  final String explorerUrl;
  final bool canAddToWallet;

  const AppNetworkConfig({
    required this.chainId,
    required this.chainName,
    required this.displayName,
    required this.currencyName,
    required this.currencySymbol,
    required this.rpcUrl,
    required this.explorerUrl,
    this.canAddToWallet = true,
  });
}

enum EasyGamePaymentAsset { native, usdc }

enum PaymentFlowStatus {
  idle,
  preparing,
  estimatingGas,
  waitingForWallet,
  submitted,
  confirming,
  success,
  failed,
}

extension PaymentFlowStatusLabel on PaymentFlowStatus {
  String get label {
    switch (this) {
      case PaymentFlowStatus.idle:
        return 'Ready';
      case PaymentFlowStatus.preparing:
        return 'Preparing payment';
      case PaymentFlowStatus.estimatingGas:
        return 'Estimating gas';
      case PaymentFlowStatus.waitingForWallet:
        return 'Waiting for wallet';
      case PaymentFlowStatus.submitted:
        return 'Submitted';
      case PaymentFlowStatus.confirming:
        return 'Confirming onchain';
      case PaymentFlowStatus.success:
        return 'Confirmed';
      case PaymentFlowStatus.failed:
        return 'Failed';
    }
  }
}

class WalletConnectService extends GetxService {
  static const int baseMainnetChainId = 8453;
  static const int baseSepoliaChainId = 84532;
  static const int ganacheChainId = 5777;
  static const int ganacheDefaultChainId = 1337;
  static const String _projectId = '31010d956c237bbf1ca5dd9f49c8abfe';

  static int get targetBaseChainId {
    try {
      return Get.find<AppConfigService>()
          .getInt('targetBaseChainId', baseSepoliaChainId);
    } catch (_) {
      return baseSepoliaChainId;
    }
  }

  static String get paymentReceiver {
    try {
      return Get.find<AppConfigService>().get('paymentReceiver');
    } catch (_) {
      return '0x898b367F3f0a6692845D602E44636AB4d38D0918';
    }
  }

  static String get easyGameContractAddress {
    try {
      return Get.find<AppConfigService>().get('easyGameContractAddress');
    } catch (_) {
      return '';
    }
  }

  static String get easyGameRoundManagerAddress {
    try {
      return Get.find<AppConfigService>().get('roundManagerAddress');
    } catch (_) {
      return '';
    }
  }

  static String get easyGameInviter {
    try {
      return Get.find<AppConfigService>().get('easyGameInviter');
    } catch (_) {
      return '';
    }
  }

  static bool isUserRejection(Object error) {
    if (error is wagmi.WagmiError) {
      return error.findError(wagmi.WagmiErrors.UserRejectedRequestError) !=
          null;
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('rejected') ||
        msg.contains('4001') ||
        msg.contains('user cancelled');
  }

  // --- Reactive state ---
  final isConnected = false.obs;
  final currentAddress = ''.obs;
  final chainId = Rx<int?>(null);
  final RxString _shortAddress = ''.obs;
  final nativeBalance = '0'.obs;
  final nativeBalanceWei = Rx<BigInt?>(null);
  final usdcBalance = '0'.obs;
  final RxString _nativeSymbol = 'ETH'.obs;
  final RxString _networkLabel = ''.obs;
  final isConnecting = false.obs;
  final isInitialized = false.obs;
  final initializationError = ''.obs;
  final isPaying = false.obs;
  final connectorId = ''.obs;
  final activeNetwork = Rxn<AppNetworkConfig>();
  final referralInviter = Rx<String?>(null);

  final easyGameAddress = ''.obs;
  final roundManagerAddress = ''.obs;
  final roundSettlementAddress = ''.obs;
  final arenaSkillsAddress = ''.obs;
  final lastPaymentTxHash = ''.obs;
  final lastPaymentReceipt = Rxn<Map<String, dynamic>>();
  final paymentStatus = PaymentFlowStatus.idle.obs;
  final paymentStatusMessage = ''.obs;
  final lastGasEstimate = Rxn<BigInt>();
  final isAppKitModalOpen = false.obs;
  final isOpeningOnRamp = false.obs;

  // --- Public derived properties ---
  bool get hasEthereumInjected => false;
  bool get hasInjectedWallet => isConnected.value;

  // --- String wrappers for Rx fields ---
  String get shortAddress => _shortAddress.value;
  String get nativeSymbol => _nativeSymbol.value;
  String get networkLabel => _networkLabel.value;

  String get paymentStatusLabel => paymentStatus.value.label;

  String get authProviderLabel {
    final id = connectorId.value.toLowerCase();
    if (id.contains('coinbase') || id.contains('base')) {
      return 'Base Account';
    }
    if (id.contains('metamask')) return 'MetaMask';
    if (id.contains('binance')) return 'Binance Wallet';
    if (id.contains('walletconnect')) return 'WalletConnect';
    if (id.isNotEmpty) {
      return 'Connected wallet';
    }
    return 'Wallet';
  }

  bool get isOnSupportedNetwork {
    final id = chainId.value;
    if (id == targetNetwork.chainId) {
      return true;
    }
    return id == ganacheChainId || id == ganacheDefaultChainId;
  }

  String get activeInviter {
    if (referralInviter.value != null && referralInviter.value!.isNotEmpty) {
      return referralInviter.value!;
    }
    return _normalizeAddress(easyGameInviter);
  }

  AppNetworkConfig get targetNetwork => _networkForChainId(targetBaseChainId);

  AppNetworkConfig get currentNetwork =>
      activeNetwork.value ?? _networkForChainId(chainId.value);

  bool get isFiatOnRampAvailable => targetBaseChainId == baseMainnetChainId;

  static const AppNetworkConfig baseMainnet = AppNetworkConfig(
    chainId: baseMainnetChainId,
    chainName: 'Base',
    displayName: 'Base',
    currencyName: 'Ether',
    currencySymbol: 'ETH',
    rpcUrl: 'https://mainnet.base.org',
    explorerUrl: 'https://basescan.org',
    canAddToWallet: true,
  );

  static const AppNetworkConfig baseSepolia = AppNetworkConfig(
    chainId: baseSepoliaChainId,
    chainName: 'Base Sepolia',
    displayName: 'Base Sepolia',
    currencyName: 'Ether',
    currencySymbol: 'ETH',
    rpcUrl: 'https://sepolia.base.org',
    explorerUrl: 'https://sepolia.basescan.org',
    canAddToWallet: true,
  );

  // --- Private ---
  final List<Worker> _balanceIdentityWorkers = [];
  Timer? _balanceRefreshTimer;
  Timer? _receiptPollTimer;
  Future<void>? _wagmiInitialization;
  StreamSubscription<wagmi.AppKitState>? _appKitStateSubscription;

  VoidCallback? _unwatchAccount;
  VoidCallback? _unwatchChainId;
  VoidCallback? _unwatchConnections;

  static AppNetworkConfig _networkForChainId(int? id) {
    switch (id) {
      case baseMainnetChainId:
        return baseMainnet;
      case baseSepoliaChainId:
        return baseSepolia;
      default:
        return baseSepolia;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _balanceIdentityWorkers.addAll([
      ever<bool>(isConnected, (_) => _scheduleBalanceForCurrentIdentity()),
      ever<String>(currentAddress, (_) => _scheduleBalanceForCurrentIdentity()),
      ever<int?>(chainId, (_) => _scheduleBalanceForCurrentIdentity()),
    ]);
    unawaited(ensureInitialized().catchError((Object _) {}));
  }

  @override
  void onClose() {
    _unwatchAccount?.call();
    _unwatchChainId?.call();
    _unwatchConnections?.call();
    unawaited(_appKitStateSubscription?.cancel());
    _balanceRefreshTimer?.cancel();
    _receiptPollTimer?.cancel();
    for (final w in _balanceIdentityWorkers) {
      w.dispose();
    }
    super.onClose();
  }

  // ──────────────────────────────────────
  //   WAGMI INIT
  // ──────────────────────────────────────

  Future<void> _initWagmi() async {
    initializationError.value = '';
    try {
      await wagmi.init();

      wagmi.AppKit.init(
        projectId: _projectId,
        chains: [
          wagmi.Chain.base.id,
          wagmi.Chain.baseSepolia.id,
        ],
        enableAnalytics: false,
        // Fiat on-ramp purchases real assets and must not be exposed while the
        // game targets Base Sepolia. Testnet funding uses the Base faucet.
        enableOnRamp: targetBaseChainId == baseMainnetChainId,
        metadata: wagmi.AppKitMetadata(
          name: 'Easy Game',
          description: 'Easy Game - Decentralized Lottery',
          url: 'https://lottery-advance.web.app',
          icons: [],
        ),
        email: false,
        showWallets: true,
        walletFeatures: true,
        includeWalletIds: [
          'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask
          '8a0ee50d1f22f6651afcae7eb4253e52a3310b90af5daef78a8c4929a9bb99d4', // Binance Wallet
          'fd20dc426fb37566d803205b19bbc1d4096b248ac04548e3cfb6b3a38bd033aa', // Base (Coinbase Wallet)
        ],
        featuredWalletIds: [],
      );

      await _appKitStateSubscription?.cancel();
      _appKitStateSubscription = wagmi.AppKit.state.listen((state) {
        final wasOpen = isAppKitModalOpen.value;
        isAppKitModalOpen.value = state.open;
        if (wasOpen && !state.open && isConnected.value) {
          _scheduleBalanceForCurrentIdentity();
        }
      });

      await _setupWatchers();
      await _restoreConnection();
      isInitialized.value = true;
    } catch (e, st) {
      initializationError.value = e.toString();
      if (kDebugMode) {
        print('[WalletConnectService] Wagmi init error: $e\n$st');
      }
      rethrow;
    }
  }

  Future<void> ensureInitialized() {
    if (isInitialized.value) return Future<void>.value();
    final active = _wagmiInitialization;
    if (active != null) return active;

    late final Future<void> initialization;
    initialization = _initWagmi().whenComplete(() {
      if (!isInitialized.value &&
          identical(_wagmiInitialization, initialization)) {
        _wagmiInitialization = null;
      }
    });
    _wagmiInitialization = initialization;
    return initialization;
  }

  Future<void> openEthOnRamp() async {
    if (isOpeningOnRamp.value) return;
    if (!isFiatOnRampAvailable) {
      throw StateError('Fiat on-ramp is available on Base Mainnet only.');
    }
    await ensureInitialized();
    if (!isConnected.value) {
      await connectWallet();
    }
    await ensureBaseNetwork();

    isOpeningOnRamp.value = true;
    try {
      await wagmi.AppKit.openBuyCrypto();
    } finally {
      isOpeningOnRamp.value = false;
    }
  }

  Future<void> _setupWatchers() async {
    _unwatchAccount = await wagmi.Core.watchAccount(
      wagmi.WatchAccountParameters(
        onChange: (account, prev) => _onAccountChanged(account),
      ),
    );

    _unwatchChainId = await wagmi.Core.watchChainId(
      wagmi.WatchChainIdParameters(
        onChange: (id, prev) => _onChainIdChanged(id),
      ),
    );

    _unwatchConnections = await wagmi.Core.watchConnections(
      wagmi.WatchConnectionsParameters(
        onChange: (_) => _syncState(),
      ),
    );
  }

  void _onAccountChanged(wagmi.Account account) {
    if (account.isConnected &&
        account.address != null &&
        account.address!.isNotEmpty) {
      currentAddress.value = account.address!;
      _shortAddress.value = _formatShort(account.address!);
      isConnected.value = true;
      connectorId.value = account.connector?.id ?? 'unknown';
    } else if (account.isDisconnected) {
      _clearState();
    }
  }

  void _onChainIdChanged(int id) {
    chainId.value = id;
    activeNetwork.value = _networkForChainId(id);
    _networkLabel.value = activeNetwork.value?.displayName ?? 'Unknown';
  }

  void _syncState() {
    final account = wagmi.Core.getAccount();
    final cid = wagmi.Core.getChainId();
    _onAccountChanged(account);
    _onChainIdChanged(cid);
  }

  Future<void> _restoreConnection() async {
    try {
      await wagmi.Core.reconnect(wagmi.ReconnectParameters());
      _syncState();
    } catch (_) {}
  }

  // ──────────────────────────────────────
  //   PUBLIC WALLET METHODS
  // ──────────────────────────────────────

  Future<void> connectWallet() async {
    await ensureInitialized();
    isConnecting.value = true;
    try {
      await wagmi.AppKit.open();
    } catch (e) {
      rethrow;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> reconnectWithSavedProvider() async {
    await ensureInitialized();
    try {
      await wagmi.Core.reconnect(wagmi.ReconnectParameters());
      _syncState();
    } catch (_) {}
  }

  Future<void> disconnectWallet() async {
    await ensureInitialized();
    _clearState();
    await wagmi.Core.disconnect(wagmi.DisconnectParameters());
  }

  void _clearState() {
    isConnected.value = false;
    currentAddress.value = '';
    _shortAddress.value = '';
    chainId.value = null;
    nativeBalance.value = '0';
    usdcBalance.value = '0';
    _networkLabel.value = '';
    connectorId.value = '';
  }

  // ──────────────────────────────────────
  //   SIGNING
  // ──────────────────────────────────────

  Future<String> signMessage(String message) async {
    await ensureInitialized();
    final account = wagmi.Core.getAccount();
    if (account.address == null || account.address!.isEmpty) {
      throw Exception('No wallet connected.');
    }
    final result = await wagmi.Core.signMessage(
      wagmi.SignMessageParameters(
        account: account.address!,
        message: wagmi.MessageToSign.stringMessage(message: message),
      ),
    );
    return result;
  }

  // ──────────────────────────────────────
  //   BALANCE
  // ──────────────────────────────────────

  Future<void> refreshNativeBalance() async {
    final addr = currentAddress.value;
    if (addr.isEmpty) return;
    try {
      final result = await wagmi.Core.getBalance(
        wagmi.GetBalanceParameters(address: addr),
      );
      if (currentAddress.value != addr) return;
      nativeBalance.value = result.formatted;
      nativeBalanceWei.value = result.value;
      _nativeSymbol.value = result.symbol;
    } catch (_) {}
  }

  Future<String> getNativeBalance() async {
    await refreshNativeBalance();
    return nativeBalance.value;
  }

  Future<void> refreshNativeBalanceSilently() async {
    try {
      await refreshNativeBalance();
    } catch (error) {
      if (kDebugMode) {
        print('Unable to refresh native balance: $error');
      }
    }
  }

  Future<String> getUsdcBalance() async {
    final addr = currentAddress.value;
    if (addr.isEmpty) return '0';
    try {
      final usdcAddr = await resolveUsdcAddress();
      if (usdcAddr.isEmpty) return '0';
      if (currentAddress.value != addr) return '0';
      final result = await wagmi.Core.getBalance(
        wagmi.GetBalanceParameters(
          address: addr,
          token: usdcAddr,
        ),
      );
      if (currentAddress.value != addr) return result.formatted;
      usdcBalance.value = result.formatted;
      return result.formatted;
    } catch (_) {
      return '0';
    }
  }

  Future<BigInt> getUsdcBalanceWei() async {
    final addr = currentAddress.value;
    if (addr.isEmpty) return BigInt.zero;
    try {
      final usdcAddr = await resolveUsdcAddress();
      if (usdcAddr.isEmpty) return BigInt.zero;
      if (currentAddress.value != addr) return BigInt.zero;
      final result = await wagmi.Core.getBalance(
        wagmi.GetBalanceParameters(
          address: addr,
          token: usdcAddr,
        ),
      );
      if (currentAddress.value == addr) {
        usdcBalance.value = result.formatted;
      }
      return result.value;
    } catch (_) {
      return BigInt.zero;
    }
  }

  void _scheduleBalanceForCurrentIdentity() {
    _balanceRefreshTimer?.cancel();
    if (isConnected.value && currentAddress.value.isNotEmpty) {
      _balanceRefreshTimer = Timer(const Duration(seconds: 1), () {
        refreshNativeBalance();
      });
    }
  }

  // ──────────────────────────────────────
  //   NETWORK
  // ──────────────────────────────────────

  Future<void> ensureBaseNetwork() async {
    await ensureInitialized();
    final target = targetBaseChainId;
    final current = chainId.value;
    if (current == target) return;

    final account = wagmi.Core.getAccount();
    await wagmi.Core.switchChain(
      wagmi.SwitchChainParameters(
        connector: account.connector,
        chainId: target,
      ),
    );
    _syncState();
    if (chainId.value != target) {
      throw StateError('Wallet did not switch to the configured Base network.');
    }
  }

  Future<void> refreshChainId() async {
    chainId.value = wagmi.Core.getChainId();
  }

  // ──────────────────────────────────────
  //   REFERRAL
  // ──────────────────────────────────────

  void setReferralInviter(String address) {
    referralInviter.value = _normalizeAddress(address);
  }

  void clearReferralInviter() {
    referralInviter.value = null;
  }

  // ──────────────────────────────────────
  //   ADDRESS RESOLUTION
  // ──────────────────────────────────────

  Future<String> resolveEasyGameAddress() async {
    final configured = await _configuredEasyGameAddress();
    if (configured.isNotEmpty) {
      easyGameAddress.value = configured;
      return configured;
    }
    if (easyGameAddress.value.isNotEmpty) return easyGameAddress.value;

    return _resolveFromArtifact('EasyGameAdvance', easyGameAddress);
  }

  Future<String> resolveRoundManagerAddress() async {
    final configured = easyGameRoundManagerAddress;
    if (configured.isNotEmpty) {
      roundManagerAddress.value = configured;
      return configured;
    }
    if (roundManagerAddress.value.isNotEmpty) return roundManagerAddress.value;

    return _resolveFromArtifact('EasyGameRoundManager', roundManagerAddress);
  }

  Future<String> resolveArenaSkillsAddress() async {
    final configured = Get.find<AppConfigService>().get('arenaSkillsAddress');
    if (configured.isNotEmpty) {
      arenaSkillsAddress.value = configured;
      return configured;
    }
    if (arenaSkillsAddress.value.isNotEmpty) return arenaSkillsAddress.value;

    return _resolveFromArtifact('EasyGameArenaSkills', arenaSkillsAddress);
  }

  Future<String> resolveRoundSettlementAddress() async {
    final configured =
        Get.find<AppConfigService>().get('roundSettlementAddress');
    if (configured.isNotEmpty) {
      roundSettlementAddress.value = configured;
      return configured;
    }
    if (roundSettlementAddress.value.isNotEmpty) {
      return roundSettlementAddress.value;
    }

    return _resolveFromArtifact(
        'EasyGameRoundSettlement', roundSettlementAddress);
  }

  Future<String> resolveUsdcAddress() async {
    final config = Get.find<AppConfigService>();
    final configured = config.get(
      'usdcTokenAddress',
      config.get('usdcContractAddress'),
    );
    final effectiveChainId = chainId.value ?? targetBaseChainId;
    final address = configured.isNotEmpty
        ? configured
        : switch (effectiveChainId) {
            baseMainnetChainId => '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
            baseSepoliaChainId => '0x036CbD53842c5426634E7929541eC2318f3dCF7e',
            _ => throw StateError(
                'USDC token is not configured for chain $effectiveChainId.',
              ),
          };
    try {
      final info = await wagmi.Core.getToken(
        wagmi.GetTokenParameters(address: address),
      );
      if (info.symbol != 'USDC') {
        debugPrint(
            '[WalletConnectService] Unexpected token at USDC address ($address): ${info.symbol}');
      }
    } catch (error) {
      debugPrint('[WalletConnectService] USDC token verification: $error');
    }
    return address;
  }

  Future<String> _resolveFromArtifact(String name, RxString cache) async {
    final artifact = jsonDecode(
      await rootBundle.loadString('src/artifacts/$name.json'),
    ) as Map<String, dynamic>;
    final networks = artifact['networks'] as Map<String, dynamic>? ?? {};
    final chainKey = '${chainId.value ?? targetBaseChainId}';
    final network = networks[chainKey] as Map<String, dynamic>?;
    final address = network?['address'] as String?;
    if (address == null || address.isEmpty) {
      throw Exception('$name is not deployed for chain $chainKey.');
    }
    cache.value = address;
    return address;
  }

  Future<String> _configuredEasyGameAddress() async {
    try {
      final config = Get.find<AppConfigService>();
      if (!config.isLoaded.value) await config.fetch();
      return config.get('easyGameContractAddress');
    } catch (_) {
      return easyGameContractAddress;
    }
  }

  // ──────────────────────────────────────
  //   ARTIFACT ABI LOADER
  // ──────────────────────────────────────

  Future<wagmi.Abi> _loadAbi(String artifactName) async {
    final raw = await rootBundle.loadString('src/artifacts/$artifactName.json');
    final artifact = jsonDecode(raw) as Map<String, dynamic>;
    final abiList = artifact['abi'] as List<dynamic>;
    return abiList.cast<Map<String, dynamic>>();
  }

  // ──────────────────────────────────────
  //   CONTRACT READS
  // ──────────────────────────────────────

  Future<dynamic> _readContract({
    required String artifactName,
    required String contractAddress,
    required String functionName,
    List<dynamic> args = const [],
  }) async {
    final abi = await _loadAbi(artifactName);
    final raw = await wagmi.Core.readContract(
      wagmi.ReadContractParameters(
        abi: abi,
        address: contractAddress,
        functionName: functionName,
        args: args,
      ),
    );
    if (raw is Map && raw.containsKey('result')) {
      return raw['result'];
    }
    return raw;
  }

  // ──────────────────────────────────────
  //   CONTRACT WRITES
  // ──────────────────────────────────────

  Future<String> _writeContract({
    required String artifactName,
    required String contractAddress,
    required String functionName,
    List<dynamic> args = const [],
  }) async {
    final accountAddress = await _prepareWriteAccount();
    final account = wagmi.Core.getAccount();
    final abi = await _loadAbi(artifactName);
    return wagmi.Core.writeContract(
      wagmi.WriteContractParameters.legacy(
        abi: abi,
        address: contractAddress,
        functionName: functionName,
        args: args,
        account: accountAddress,
        chainId: account.chain?.id ?? targetBaseChainId,
      ),
    );
  }

  Future<String> _writeContractWithValue({
    required String artifactName,
    required String contractAddress,
    required String functionName,
    List<dynamic> args = const [],
    required BigInt value,
  }) async {
    final accountAddress = await _prepareWriteAccount();
    final account = wagmi.Core.getAccount();
    final abi = await _loadAbi(artifactName);
    return wagmi.Core.writeContract(
      wagmi.WriteContractParameters.legacy(
        abi: abi,
        address: contractAddress,
        functionName: functionName,
        args: args,
        account: accountAddress,
        value: value,
        chainId: account.chain?.id ?? targetBaseChainId,
      ),
    );
  }

  Future<String> _prepareWriteAccount() async {
    await ensureInitialized();
    if (!isConnected.value || currentAddress.value.isEmpty) {
      throw StateError('No wallet connected.');
    }
    await ensureBaseNetwork();
    final account = wagmi.Core.getAccount();
    final address = account.address;
    if (!account.isConnected || address == null || address.isEmpty) {
      throw StateError('Wallet account is unavailable.');
    }
    final activeChainId = account.chain?.id ?? wagmi.Core.getChainId();
    if (activeChainId != targetBaseChainId) {
      throw StateError('Wallet is connected to the wrong network.');
    }
    return address;
  }

  // ──────────────────────────────────────
  //   GAME CONTRACT READ METHODS
  // ──────────────────────────────────────

  Future<BigInt> getArenaFreezeTokenPriceUsdc() async {
    final skills = await resolveArenaSkillsAddress();
    final val = await _readContract(
      artifactName: 'EasyGameArenaSkills',
      contractAddress: skills,
      functionName: 'FREEZE_TOKEN_PRICE_USDC',
    );
    return val as BigInt;
  }

  Future<EasyGamePlayerSummary?> getEasyGamePlayerSummary(
      {String? address}) async {
    final game = await resolveEasyGameAddress();
    final player = address ?? currentAddress.value;
    if (player.isEmpty) return null;

    final values = await Future.wait<dynamic>([
      _readContract(
        artifactName: 'EasyGameAdvance',
        contractAddress: game,
        functionName: 'getPlayer',
        args: [player],
      ),
      _readContract(
        artifactName: 'EasyGameAdvance',
        contractAddress: game,
        functionName: 'claimableReferralBonusUsdc',
        args: [player],
      ),
    ]);
    final result = values[0];
    if (result is List && result.length >= 16) {
      return EasyGamePlayerSummary(
        exists: result[0] as bool,
        wallet: result[1] as String? ?? player,
        inviter: result[2] as String? ?? '',
        secondLine: result[3] as String? ?? '',
        thirdLine: result[4] as String? ?? '',
        totalTickets: result[5] as BigInt? ?? BigInt.zero,
        baseWeight: result[6] as BigInt? ?? BigInt.zero,
        referralWeight: result[7] as BigInt? ?? BigInt.zero,
        loyaltyWeight: BigInt.zero,
        matrixWeight: result[8] as BigInt? ?? BigInt.zero,
        nftWeight: result[9] as BigInt? ?? BigInt.zero,
        totalWeight: result[10] as BigInt? ?? BigInt.zero,
        boxTokens: result[11] as BigInt? ?? BigInt.zero,
        recycleCount: result[12] as BigInt? ?? BigInt.zero,
        claimableReferralBonusWei: result[13] as BigInt? ?? BigInt.zero,
        claimableReferralBonusUsdc: values[1] as BigInt? ?? BigInt.zero,
        claimablePrizeWei: BigInt.zero,
        pendingPrizeWei: BigInt.zero,
        joinedAt: result[14] as BigInt? ?? BigInt.zero,
        lastActiveAt: result[15] as BigInt? ?? BigInt.zero,
      );
    }
    return null;
  }

  Future<bool> isEasyGameLevelAvailable(int level) async {
    final game = await resolveEasyGameAddress();
    final result = await _readContract(
      artifactName: 'EasyGameAdvance',
      contractAddress: game,
      functionName: 'levelAvailable',
      args: [BigInt.from(level)],
    );
    return result as bool? ?? false;
  }

  Future<RoundPlayerState?> getRoundPlayerState(BigInt roundId) async {
    final game = await resolveEasyGameAddress();
    final player = currentAddress.value;
    if (player.isEmpty) return null;

    final result = await _readContract(
      artifactName: 'EasyGameAdvance',
      contractAddress: game,
      functionName: 'getPlayerRound',
      args: [player, roundId],
    );
    if (result is List && result.length >= 9) {
      return RoundPlayerState(
        active: result[0] as bool,
        level: (result[1] as BigInt).toInt(),
        cellId: result[3] as BigInt,
        cycleCount: result[7] as BigInt,
        totalWeight: result[8] as BigInt,
      );
    }
    return null;
  }

  Future<RoundMatrixStats?> getRoundMatrixStats(BigInt roundId) async {
    final game = await resolveEasyGameAddress();
    final result = await _readContract(
      artifactName: 'EasyGameAdvance',
      contractAddress: game,
      functionName: 'getRoundGameStats',
      args: [roundId],
    );
    if (result is List && result.length >= 6) {
      return RoundMatrixStats(
        prizePoolEth: result[0] as BigInt,
        prizePoolUsdc: result[1] as BigInt,
        totalWeight: result[2] as BigInt,
        activeCells: result[3] as BigInt,
        nextCellId: result[4] as BigInt,
        nextOpenParentId: result[5] as BigInt,
      );
    }
    return null;
  }

  Future<RoundMatrixNode?> getRoundMatrixNode(
    BigInt roundId,
    int index,
  ) async {
    final game = await resolveEasyGameAddress();
    final result = await _readContract(
      artifactName: 'EasyGameAdvance',
      contractAddress: game,
      functionName: 'getRoundMatrixNode',
      args: [roundId, BigInt.from(index)],
    );
    if (result is! List || result.length < 7) return null;
    return RoundMatrixNode(
      cellId: result[0] as BigInt,
      player: result[1] as String? ?? '',
      level: (result[2] as BigInt).toInt(),
      parentCellId: result[3] as BigInt,
      leftChildCellId: result[4] as BigInt,
      rightChildCellId: result[5] as BigInt,
      closed: result[6] as bool,
    );
  }

  Future<ArenaSkillStatus?> getArenaSkillStatus(
    BigInt roundId, {
    String? playerAddress,
  }) async {
    final skills = await resolveArenaSkillsAddress();
    final player = playerAddress ?? currentAddress.value;
    if (player.isEmpty) return null;

    final result = await _readContract(
      artifactName: 'EasyGameArenaSkills',
      contractAddress: skills,
      functionName: 'getArenaStatus',
      args: [roundId, player],
    );
    if (result is List && result.length >= 5) {
      final unfreezePrice = await _readContract(
        artifactName: 'EasyGameArenaSkills',
        contractAddress: skills,
        functionName: 'getUnfreezePriceUsdc',
        args: [roundId, player],
      );
      final frozenUntilSeconds = result[2] as BigInt? ?? BigInt.zero;
      return ArenaSkillStatus(
        frozen: result[0] as bool,
        immune: result[1] as bool,
        frozenUntil: frozenUntilSeconds > BigInt.zero
            ? DateTime.fromMillisecondsSinceEpoch(
                frozenUntilSeconds.toInt() * 1000,
                isUtc: true,
              )
            : null,
        freezeHits: (result[3] as BigInt).toInt(),
        freezeTokens: (result[4] as BigInt).toInt(),
        unfreezePriceUsdc: unfreezePrice as BigInt? ?? BigInt.zero,
      );
    }
    return null;
  }

  Future<RoundEntryEligibility> getRoundEntryEligibility({
    required BigInt seasonId,
    required int level,
    String? playerAddress,
  }) async {
    final manager = await resolveRoundManagerAddress();
    final player = _normalizeAddress(playerAddress ?? currentAddress.value);
    final result = await _readContract(
      artifactName: 'EasyGameRoundManager',
      contractAddress: manager,
      functionName: 'getEntryEligibility',
      args: [seasonId, BigInt.from(level), player],
    );
    if (result is List && result.length >= 3) {
      return RoundEntryEligibility(
        reason: roundEntryEligibilityReasonFromContractValue(
          (result[0] as BigInt).toInt(),
        ),
        requiredLevel: (result[1] as BigInt).toInt(),
        blockingRoundId: result[2] as BigInt,
      );
    }
    return RoundEntryEligibility(
      reason: RoundEntryEligibilityReason.unknown,
      requiredLevel: 0,
      blockingRoundId: BigInt.zero,
    );
  }

  Future<SettlementClaimable> getSettlementClaimable(
      {String? playerAddress}) async {
    final requested = playerAddress ?? currentAddress.value;
    if (requested.isEmpty) return SettlementClaimable.zero;
    final settlement = await resolveRoundSettlementAddress();
    final artifact = await _loadAbi('EasyGameRoundSettlement');

    final results = await wagmi.Core.readContracts(
      wagmi.ReadContractsParameters(
        contracts: [
          {
            'abi': artifact,
            'address': settlement,
            'functionName': 'claimableEth',
            'args': [requested],
          },
          {
            'abi': artifact,
            'address': settlement,
            'functionName': 'claimableUsdc',
            'args': [requested],
          },
        ],
      ),
    );

    return SettlementClaimable(
      ethAmount: results.isNotEmpty
          ? results[0]['result'] as BigInt? ?? BigInt.zero
          : BigInt.zero,
      usdcAmount: results.length > 1
          ? results[1]['result'] as BigInt? ?? BigInt.zero
          : BigInt.zero,
    );
  }

  Future<PlayerSeasonProgress> getPlayerSeasonProgress(
    BigInt seasonId, {
    String? playerAddress,
  }) async {
    final manager = await resolveRoundManagerAddress();
    final player = _normalizeAddress(playerAddress ?? currentAddress.value);
    final result = await _readContract(
      artifactName: 'EasyGameRoundManager',
      contractAddress: manager,
      functionName: 'getPlayerSeasonProgress',
      args: [seasonId, player],
    );
    if (result is List && result.length >= 6) {
      return PlayerSeasonProgress(
        started: result[0] as bool,
        startLevel: (result[1] as BigInt).toInt(),
        highestLevel: (result[2] as BigInt).toInt(),
        activatedLevels: (result[3] as BigInt).toInt(),
        directInvites: (result[4] as BigInt).toInt(),
        inviteCapacity: (result[5] as BigInt).toInt(),
      );
    }
    return PlayerSeasonProgress(
      started: false,
      startLevel: 0,
      highestLevel: 0,
      activatedLevels: 0,
      directInvites: 0,
      inviteCapacity: 0,
    );
  }

  Future<GameRoundChainState> getEasyGameRoundState(
    GameRoundSchedule schedule,
  ) async {
    final roundId = BigInt.from(schedule.roundId);
    final manager = await resolveRoundManagerAddress();
    final values = await Future.wait<dynamic>([
      _readContract(
        artifactName: 'EasyGameRoundManager',
        contractAddress: manager,
        functionName: 'getRoundState',
        args: [roundId],
      ),
      _readContract(
        artifactName: 'EasyGameRoundManager',
        contractAddress: manager,
        functionName: 'getRoundPhase',
        args: [roundId],
      ),
      _readContract(
        artifactName: 'EasyGameRoundManager',
        contractAddress: manager,
        functionName: 'getSeasonState',
        args: [BigInt.from(schedule.seasonId)],
      ),
      _readContract(
        artifactName: 'EasyGameRoundManager',
        contractAddress: manager,
        functionName: 'getCommittedRoundHash',
        args: [
          BigInt.from(schedule.seasonId),
          BigInt.from(schedule.level),
        ],
      ),
    ]);
    final state = values[0];
    final season = values[2];
    final initialized = state is List && state.length >= 8 && state[4] == true;
    final config = initialized
        ? await _readContract(
            artifactName: 'EasyGameRoundManager',
            contractAddress: manager,
            functionName: 'getRoundConfig',
            args: [roundId],
          )
        : null;
    if (state is List && state.length >= 8) {
      final initializedAtSeconds = state[1] as BigInt? ?? BigInt.zero;
      return GameRoundChainState(
        roundId: roundId,
        configHash: state[0]?.toString() ?? '',
        committedConfigHash: values[3]?.toString() ?? '',
        seasonConfigRoot:
            season is List && season.isNotEmpty ? '${season[0]}' : '',
        seasonCommitted:
            season is List && season.length >= 4 && season[3] == true,
        initializedAt: initializedAtSeconds > BigInt.zero
            ? DateTime.fromMillisecondsSinceEpoch(
                initializedAtSeconds.toInt() * 1000,
                isUtc: true,
              )
            : null,
        occupiedCells: state[2] as BigInt? ?? BigInt.zero,
        winnersRegistered: state[3] as BigInt? ?? BigInt.zero,
        initialized: state[4] as bool? ?? false,
        settled: state[5] as bool? ?? false,
        cancelled: state[6] as bool? ?? false,
        paused: state[7] as bool? ?? false,
        ethPriceWei: config is List && config.length >= 12
            ? config[10] as BigInt? ?? BigInt.zero
            : BigInt.zero,
        usdcPrice: config is List && config.length >= 12
            ? config[11] as BigInt? ?? BigInt.zero
            : BigInt.zero,
        phase: GameRoundPhase.values[(values[1] as BigInt).toInt()],
      );
    }
    return GameRoundChainState(
      roundId: roundId,
      configHash: '',
      committedConfigHash: values[3]?.toString() ?? '',
      seasonConfigRoot:
          season is List && season.isNotEmpty ? '${season[0]}' : '',
      seasonCommitted:
          season is List && season.length >= 4 && season[3] == true,
      initializedAt: null,
      occupiedCells: BigInt.zero,
      winnersRegistered: BigInt.zero,
      initialized: false,
      settled: false,
      cancelled: false,
      paused: false,
      ethPriceWei: BigInt.zero,
      usdcPrice: BigInt.zero,
      phase: GameRoundPhase.uninitialized,
    );
  }

  // ──────────────────────────────────────
  //   GAME CONTRACT WRITE METHODS
  // ──────────────────────────────────────

  Future<String> buyArenaFreezeToken(BigInt roundId) async {
    final skills = await resolveArenaSkillsAddress();
    final price = await getArenaFreezeTokenPriceUsdc();
    await _ensureUsdcAllowance(spender: skills, amount: price);
    return _writeAndConfirm(
      artifactName: 'EasyGameArenaSkills',
      contractAddress: skills,
      functionName: 'buyFreezeToken',
      args: [roundId],
    );
  }

  Future<String> freezeArenaPlayer(BigInt roundId, String target) async {
    final skills = await resolveArenaSkillsAddress();
    return _writeAndConfirm(
      artifactName: 'EasyGameArenaSkills',
      contractAddress: skills,
      functionName: 'freezePlayer',
      args: [roundId, target],
    );
  }

  Future<String> buyArenaUnfreeze(BigInt roundId) async {
    final skills = await resolveArenaSkillsAddress();
    final status = await getArenaSkillStatus(roundId);
    final price = status?.unfreezePriceUsdc ?? BigInt.zero;
    if (price <= BigInt.zero) {
      throw StateError('Unable to resolve unfreeze price.');
    }
    await _ensureUsdcAllowance(spender: skills, amount: price);
    return _writeAndConfirm(
      artifactName: 'EasyGameArenaSkills',
      contractAddress: skills,
      functionName: 'buyUnfreeze',
      args: [roundId],
    );
  }

  Future<String> settleEasyGameRound(RoundSettlementProofs settlement) async {
    final address = await resolveRoundSettlementAddress();
    return _writeAndConfirm(
      artifactName: 'EasyGameRoundSettlement',
      contractAddress: address,
      functionName: 'settleRound',
      args: [
        settlement.roundId,
        settlement.cells.map((c) => c.cellId).toList(),
        settlement.cells.map((c) => c.proof).toList(),
      ],
    );
  }

  Future<String> claimSettlementPrize() async {
    final address = await resolveRoundSettlementAddress();
    return _writeAndConfirm(
      artifactName: 'EasyGameRoundSettlement',
      contractAddress: address,
      functionName: 'claimPrize',
    );
  }

  Future<String> claimEasyGameReferralBonus() async {
    final game = await resolveEasyGameAddress();
    return _writeAndConfirm(
      artifactName: 'EasyGameAdvance',
      contractAddress: game,
      functionName: 'claimReferralBonus',
    );
  }

  Future<String> claimEasyGameReferralBonusUSDC() async {
    final game = await resolveEasyGameAddress();
    return _writeAndConfirm(
      artifactName: 'EasyGameAdvance',
      contractAddress: game,
      functionName: 'claimReferralBonusUSDC',
    );
  }

  Future<String> activateEasyGameRound({
    required GameRoundSchedule round,
    String? inviter,
  }) async {
    paymentStatus.value = PaymentFlowStatus.preparing;
    paymentStatusMessage.value = '';
    lastPaymentReceipt.value = null;
    if (!isConnected.value) await connectWallet();
    await ensureBaseNetwork();
    final contractAddress = await resolveEasyGameAddress();
    final inviterAddress = _normalizeAddress(
      inviter?.isNotEmpty == true ? inviter! : activeInviter,
    );
    isPaying.value = true;
    try {
      paymentStatus.value = PaymentFlowStatus.waitingForWallet;
      paymentStatusMessage.value = 'Confirm ETH payment in wallet...';
      final txHash = await _writeContractWithValue(
        artifactName: 'EasyGameAdvance',
        contractAddress: contractAddress,
        functionName: 'activateRound',
        args: [
          [
            BigInt.from(round.seasonId),
            BigInt.from(round.roundId),
            BigInt.from(round.level),
            BigInt.from(round.startsAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.entriesCloseAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.endsAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.freezeClosesAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.maxPlayers),
            BigInt.from(round.maxWinners),
            round.winningCellsRoot,
            round.ethPriceWei,
            round.usdcPrice,
            BigInt.from(round.freezeLimit),
            BigInt.from(round.paymentSplitVersion),
          ],
          round.operatorSignature,
          inviterAddress,
        ],
        value: round.ethPriceWei,
      );
      lastPaymentTxHash.value = txHash;
      paymentStatus.value = PaymentFlowStatus.confirming;
      paymentStatusMessage.value = 'Waiting for onchain confirmation...';
      final receipt = await _requireSuccessfulReceipt(txHash);
      lastPaymentReceipt.value = receipt;
      paymentStatus.value = PaymentFlowStatus.success;
      paymentStatusMessage.value = 'ETH payment confirmed';
      await refreshNativeBalanceSilently();
      return txHash;
    } catch (error) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = error.toString();
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<String> activateEasyGameRoundWithUSDC({
    required GameRoundSchedule round,
    String? inviter,
  }) async {
    if (isPaying.value) {
      throw StateError('payment.alreadyProcessing');
    }
    paymentStatus.value = PaymentFlowStatus.preparing;
    paymentStatusMessage.value = '';
    lastPaymentReceipt.value = null;
    if (!isConnected.value) await connectWallet();
    await ensureBaseNetwork();
    final contractAddress = await resolveEasyGameAddress();
    final inviterAddress = _normalizeAddress(
      inviter?.isNotEmpty == true ? inviter! : activeInviter,
    );
    isPaying.value = true;
    try {
      final tokenAddress = await resolveUsdcAddress();
      final allowance = await getUsdcAllowance(
        owner: currentAddress.value,
        spender: contractAddress,
      );
      if (allowance < round.usdcPrice) {
        paymentStatus.value = PaymentFlowStatus.estimatingGas;
        paymentStatusMessage.value = 'Approving USDC...';
        final approveHash = await _writeContract(
          artifactName: 'ERC20',
          contractAddress: tokenAddress,
          functionName: 'approve',
          args: [contractAddress, round.usdcPrice],
        );
        paymentStatus.value = PaymentFlowStatus.confirming;
        paymentStatusMessage.value = 'USDC approval pending...';
        final receipt = await waitForTransactionReceipt(approveHash);
        if (receipt['status'] != 'success') {
          throw Exception('USDC approval reverted');
        }
      }
      paymentStatus.value = PaymentFlowStatus.waitingForWallet;
      paymentStatusMessage.value = 'Confirm USDC payment in wallet...';
      final txHash = await _writeContract(
        artifactName: 'EasyGameAdvance',
        contractAddress: contractAddress,
        functionName: 'activateRoundWithUSDC',
        args: [
          [
            BigInt.from(round.seasonId),
            BigInt.from(round.roundId),
            BigInt.from(round.level),
            BigInt.from(round.startsAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.entriesCloseAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.endsAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.freezeClosesAt.millisecondsSinceEpoch ~/ 1000),
            BigInt.from(round.maxPlayers),
            BigInt.from(round.maxWinners),
            round.winningCellsRoot,
            round.ethPriceWei,
            round.usdcPrice,
            BigInt.from(round.freezeLimit),
            BigInt.from(round.paymentSplitVersion),
          ],
          round.operatorSignature,
          inviterAddress,
        ],
      );
      lastPaymentTxHash.value = txHash;
      paymentStatus.value = PaymentFlowStatus.confirming;
      paymentStatusMessage.value = 'Waiting for onchain confirmation...';
      final receipt = await _requireSuccessfulReceipt(txHash);
      lastPaymentReceipt.value = receipt;
      paymentStatus.value = PaymentFlowStatus.success;
      paymentStatusMessage.value = 'USDC payment confirmed';
      await Future.wait<void>([
        refreshNativeBalanceSilently(),
        getUsdcBalance().then((_) {}),
      ]);
      return txHash;
    } catch (error) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = error.toString();
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<BigInt> getUsdcAllowance(
      {required String owner, required String spender}) async {
    final token = await resolveUsdcAddress();
    final result = await _readContract(
      artifactName: 'ERC20',
      contractAddress: token,
      functionName: 'allowance',
      args: [owner, spender],
    );
    return result as BigInt? ?? BigInt.zero;
  }

  Future<void> _ensureUsdcAllowance({
    required String spender,
    required BigInt amount,
  }) async {
    if (amount <= BigInt.zero) return;
    final owner = await _prepareWriteAccount();
    final allowance = await getUsdcAllowance(owner: owner, spender: spender);
    if (allowance >= amount) return;
    final token = await resolveUsdcAddress();
    final approvalHash = await _writeContract(
      artifactName: 'ERC20',
      contractAddress: token,
      functionName: 'approve',
      args: [spender, amount],
    );
    await _requireSuccessfulReceipt(approvalHash);
  }

  Future<String> _writeAndConfirm({
    required String artifactName,
    required String contractAddress,
    required String functionName,
    List<dynamic> args = const [],
  }) async {
    final hash = await _writeContract(
      artifactName: artifactName,
      contractAddress: contractAddress,
      functionName: functionName,
      args: args,
    );
    lastPaymentTxHash.value = hash;
    lastPaymentReceipt.value = await _requireSuccessfulReceipt(hash);
    await refreshNativeBalanceSilently();
    return hash;
  }

  Future<Map<String, dynamic>> _requireSuccessfulReceipt(String hash) async {
    final receipt = await waitForTransactionReceipt(hash);
    if (receipt['status'] != 'success') {
      throw StateError('Transaction reverted: $hash');
    }
    return receipt;
  }

  // ──────────────────────────────────────
  //   TRANSACTION RECEIPT POLLING
  // ──────────────────────────────────────

  Future<Map<String, dynamic>> waitForTransactionReceipt(String hash) async {
    final result = await wagmi.Core.waitForTransactionReceipt(
      wagmi.WaitForTransactionReceiptParameters(hash: hash),
    );
    return {
      'blockHash': result.blockHash,
      'blockNumber': result.blockNumber,
      'transactionHash': result.transactionHash,
      'from': result.from,
      'to': result.to,
      'gasUsed': result.gasUsed,
      'cumulativeGasUsed': result.cumulativeGasUsed,
      'status': result.status,
    };
  }

  // ──────────────────────────────────────
  //   UTILITY
  // ──────────────────────────────────────

  String _normalizeAddress(String address) {
    final text = address.trim();
    return text.startsWith('0x')
        ? text.toLowerCase()
        : '0x${text.toLowerCase()}';
  }

  String _formatShort(String address) {
    if (address.length < 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }
}

class EasyGamePlayerSummary {
  final bool exists;
  final String wallet;
  final String inviter;
  final String secondLine;
  final String thirdLine;
  final BigInt totalTickets;
  final BigInt baseWeight;
  final BigInt referralWeight;
  final BigInt loyaltyWeight;
  final BigInt matrixWeight;
  final BigInt nftWeight;
  final BigInt totalWeight;
  final BigInt boxTokens;
  final BigInt recycleCount;
  final BigInt claimableReferralBonusWei;
  final BigInt claimableReferralBonusUsdc;
  final BigInt claimablePrizeWei;
  final BigInt pendingPrizeWei;
  final BigInt joinedAt;
  final BigInt lastActiveAt;

  const EasyGamePlayerSummary({
    required this.exists,
    required this.wallet,
    required this.inviter,
    required this.secondLine,
    required this.thirdLine,
    required this.totalTickets,
    required this.baseWeight,
    required this.referralWeight,
    required this.loyaltyWeight,
    required this.matrixWeight,
    required this.nftWeight,
    required this.totalWeight,
    required this.boxTokens,
    required this.recycleCount,
    required this.claimableReferralBonusWei,
    required this.claimableReferralBonusUsdc,
    required this.claimablePrizeWei,
    required this.pendingPrizeWei,
    required this.joinedAt,
    required this.lastActiveAt,
  });
}
