import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3/ethereum.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart' as web3;
import 'package:wallet/wallet.dart' as wallet;
import 'package:lottery_advance/app/services/base_account_bridge.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/models/wallet_session_model.dart';
import 'app_config_service.dart';
import 'wallet_session_store.dart';

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

class WalletConnectService extends GetxService {
  static const int baseMainnetChainId = 8453;
  static const int baseSepoliaChainId = 84532;
  static const int ganacheChainId = 5777;
  static const int ganacheDefaultChainId = 1337;
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
      return '';
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

  static String get usdcTokenAddress {
    try {
      return Get.find<AppConfigService>().get('usdcTokenAddress');
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

  static String get baseBuilderDataSuffix {
    try {
      return Get.find<AppConfigService>().get('baseBuilderDataSuffix');
    } catch (_) {
      return '0x62635f68336c356a6c69790b0080218021802180218021802180218021';
    }
  }

  static bool get allowLocalChains {
    try {
      return Get.find<AppConfigService>().getBool('allowLocalChains', false);
    } catch (_) {
      return false;
    }
  }

  static String get baseAccountAppName {
    try {
      return Get.find<AppConfigService>()
          .get('baseAccountAppName', 'Easy Game');
    } catch (_) {
      return 'Easy Game';
    }
  }

  static String get baseAccountAppLogoUrl {
    try {
      return Get.find<AppConfigService>().get('baseAccountAppLogoUrl');
    } catch (_) {
      return '';
    }
  }

  static const String _zeroAddress =
      '0x0000000000000000000000000000000000000000';

  final RxString currentAddress = ''.obs;
  final RxBool isConnected = false.obs;
  final RxBool isBaseAccountSession = false.obs;
  final RxBool isRestoringSession = true.obs;
  final RxBool isRefreshingBalance = false.obs;
  final RxnInt chainId = RxnInt();
  final RxBool isConnecting = false.obs;
  final RxBool isPaying = false.obs;
  final RxBool isEstimatingPayment = false.obs;
  final Rx<PaymentFlowStatus> paymentStatus = PaymentFlowStatus.idle.obs;
  final RxString paymentStatusMessage = ''.obs;
  final RxString lastPaymentTxHash = ''.obs;
  final Rxn<BigInt> nativeBalanceWei = Rxn<BigInt>();
  final Rxn<BigInt> lastGasEstimate = Rxn<BigInt>();
  final Rxn<BigInt> lastLevelPaymentWei = Rxn<BigInt>();
  final Rxn<EasyGameTransactionReceipt> lastPaymentReceipt =
      Rxn<EasyGameTransactionReceipt>();
  final RxString authProvider = ''.obs;
  final RxString baseAccountMessage = ''.obs;
  final RxString baseAccountSignature = ''.obs;
  final RxString baseAccountNonce = ''.obs;
  final RxString easyGameAddress = ''.obs;
  final RxString roundManagerAddress = ''.obs;
  final RxString arenaSkillsAddress = ''.obs;
  final RxString roundSettlementAddress = ''.obs;
  final RxString referralInviter = ''.obs;
  final Rxn<AppNetworkConfig> activeNetwork = Rxn<AppNetworkConfig>();
  final WalletSessionStore _sessionStore = Get.find<WalletSessionStore>();

  static const AppNetworkConfig baseMainnet = AppNetworkConfig(
    chainId: baseMainnetChainId,
    chainName: 'Base Mainnet',
    displayName: 'Base',
    currencyName: 'Ether',
    currencySymbol: 'ETH',
    rpcUrl: 'https://mainnet.base.org',
    explorerUrl: 'https://basescan.org',
  );

  static const AppNetworkConfig baseSepolia = AppNetworkConfig(
    chainId: baseSepoliaChainId,
    chainName: 'Base Sepolia',
    displayName: 'Base Sepolia',
    currencyName: 'Sepolia Ether',
    currencySymbol: 'ETH',
    rpcUrl: 'https://sepolia.base.org',
    explorerUrl: 'https://sepolia.basescan.org',
  );

  static const AppNetworkConfig ganacheLocal = AppNetworkConfig(
    chainId: ganacheChainId,
    chainName: 'Local Ganache',
    displayName: 'Ganache',
    currencyName: 'Ether',
    currencySymbol: 'ETH',
    rpcUrl: 'http://127.0.0.1:7545',
    explorerUrl: '',
    canAddToWallet: false,
  );

  static const AppNetworkConfig hardhatLocal = AppNetworkConfig(
    chainId: ganacheDefaultChainId,
    chainName: 'Local Hardhat',
    displayName: 'Local',
    currencyName: 'Ether',
    currencySymbol: 'ETH',
    rpcUrl: 'http://127.0.0.1:8545',
    explorerUrl: '',
    canAddToWallet: false,
  );

  bool get hasInjectedWallet => ethereum != null;
  bool get isWalletAvailable =>
      hasInjectedWallet ||
      isBaseAccountSession.value ||
      isBaseAccountBridgeAvailable;
  bool get isSignedInWithBaseAccount => isBaseAccountSession.value;

  AppNetworkConfig get targetNetwork =>
      _networkForChainId(targetBaseChainId) ?? baseSepolia;

  AppNetworkConfig get currentNetwork =>
      activeNetwork.value ?? _networkForChainId(chainId.value) ?? targetNetwork;

  String get networkLabel => currentNetwork.displayName;
  String get nativeSymbol => currentNetwork.currencySymbol;
  String get paymentStatusLabel => paymentStatus.value.label;
  String get authProviderLabel {
    if (isBaseAccountSession.value) {
      return 'Base Account';
    }
    if (authProvider.value == 'injected_wallet') {
      return 'Injected wallet';
    }
    return 'Wallet';
  }

  bool get isOnSupportedNetwork {
    final id = chainId.value;
    if (id == targetNetwork.chainId) {
      return true;
    }
    return allowLocalChains &&
        (id == ganacheChainId || id == ganacheDefaultChainId);
  }

  String get shortAddress {
    final address = currentAddress.value;
    if (address.length <= 12) {
      return address;
    }
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String get activeInviter {
    if (referralInviter.value.isNotEmpty) {
      return referralInviter.value;
    }
    return ReferralLinkService.normalizeAddress(easyGameInviter);
  }

  void setReferralInviter(String inviter) {
    final normalized = ReferralLinkService.normalizeAddress(inviter);
    if (normalized.isNotEmpty) {
      referralInviter.value = normalized;
    }
  }

  void clearReferralInviter() {
    referralInviter.value = '';
  }

  void resetPaymentState() {
    isPaying.value = false;
    isEstimatingPayment.value = false;
    paymentStatus.value = PaymentFlowStatus.idle;
    paymentStatusMessage.value = '';
    lastPaymentTxHash.value = '';
    lastGasEstimate.value = null;
    lastLevelPaymentWei.value = null;
    lastPaymentReceipt.value = null;
  }

  @override
  void onInit() {
    if (kDebugMode) {
      print("[DEBUG] WalletConnectService: onInit started.");
    }
    super.onInit();
    unawaited(_restoreConnection());
    _listenWalletChanges();
    if (kDebugMode) {
      print("[DEBUG] WalletConnectService: onInit completed.");
    }
  }

  Future<void> connectWallet() async {
    if (!hasInjectedWallet) {
      throw Exception(
        'MetaMask is not detected in this Chrome window. If you use flutter run -d chrome, make sure that Chrome profile has the MetaMask extension, or run with web-server and open the app in your normal Chrome.',
      );
    }

    isConnecting.value = true;
    try {
      final accounts = await _requestAccounts();
      final previousSession = _sessionStore.read();
      if (previousSession?.provider == WalletSessionProvider.baseAccount ||
          isBaseAccountSession.value) {
        await _disconnectBaseProvider();
      }
      isBaseAccountSession.value = false;
      authProvider.value = 'injected_wallet';
      baseAccountMessage.value = '';
      baseAccountSignature.value = '';
      baseAccountNonce.value = '';
      _setAccounts(accounts);
      await refreshChainId();
      await _persistSession(WalletSessionProvider.injectedWallet);
    } catch (e) {
      _clearRuntimeWalletState();
      rethrow;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<void> connectBaseAccount(
      {bool fallbackToInjectedWallet = true}) async {
    isConnecting.value = true;
    try {
      final result = await signInWithBaseAccount(
        chainId: targetNetwork.chainId,
        appName: baseAccountAppName,
        appLogoUrl: baseAccountAppLogoUrl,
      );
      if (result.address.isEmpty ||
          result.message.isEmpty ||
          result.signature.isEmpty) {
        throw Exception('Base Account sign-in did not return auth data.');
      }

      isBaseAccountSession.value = true;
      authProvider.value = 'base_account';
      baseAccountMessage.value = result.message;
      baseAccountSignature.value = result.signature;
      baseAccountNonce.value = result.nonce;
      _prepareBalanceForAddress(result.address);
      currentAddress.value = result.address;
      isConnected.value = true;
      chainId.value = result.chainId;
      activeNetwork.value = _networkForChainId(result.chainId);
      await _persistSession(WalletSessionProvider.baseAccount);
      _startBalanceRefresh();
      await refreshNativeBalanceSilently();
    } catch (e) {
      final message = e.toString();
      if (_isBaseAccountCoopError(message)) {
        if (fallbackToInjectedWallet && hasInjectedWallet) {
          await connectWallet();
          return;
        }
        _clearRuntimeWalletState();
        throw Exception('wallet.baseCoopError'.tr);
      }
      if (fallbackToInjectedWallet && hasInjectedWallet) {
        await connectWallet();
        return;
      }
      _clearRuntimeWalletState();
      rethrow;
    } finally {
      isConnecting.value = false;
    }
  }

  Future<List<String>> _requestAccounts() async {
    try {
      final accounts = await ethereum!.request<List<dynamic>>(
        'eth_requestAccounts',
        [],
      );
      return accounts.map((account) => account.toString()).toList();
    } catch (e) {
      final message = e.toString();
      if (message.contains('4001') || message.contains('rejected')) {
        throw Exception('Wallet connection request was rejected in MetaMask.');
      }
      throw Exception('MetaMask eth_requestAccounts failed: $message');
    }
  }

  Future<void> ensureBaseNetwork() async {
    if (!isWalletAvailable) {
      throw Exception('MetaMask or another Web3 wallet is not installed');
    }

    await refreshChainId();
    if (isOnSupportedNetwork) {
      return;
    }

    await _switchToNetwork(targetNetwork);
    await refreshChainId();
  }

  Future<void> ensureBaseSepolia() => ensureBaseNetwork();

  Future<String> sendNativePayment({
    required double amountEther,
    String? to,
    bool waitForReceipt = true,
  }) async {
    final receiver = to ?? paymentReceiver;
    if (receiver.isEmpty) {
      throw Exception(
        'Payment receiver is not configured. Build with --dart-define=PAYMENT_RECEIVER=0x...',
      );
    }

    if (!isConnected.value) {
      await connectBaseAccount();
    }
    await ensureBaseNetwork();

    isPaying.value = true;
    paymentStatus.value = PaymentFlowStatus.waitingForWallet;
    paymentStatusMessage.value = 'Confirm the payment in your wallet.';
    lastPaymentReceipt.value = null;
    try {
      final txHash = await _walletRequest<String>('eth_sendTransaction', [
        {
          'from': currentAddress.value,
          'to': receiver,
          'value': _etherToHexWei(amountEther),
          'data': _appendBuilderDataSuffix('0x'),
        }
      ]);
      lastPaymentTxHash.value = txHash;
      if (waitForReceipt) {
        paymentStatus.value = PaymentFlowStatus.confirming;
        paymentStatusMessage.value = 'Waiting for onchain confirmation.';
        final receipt = await waitForTransactionReceipt(txHash);
        lastPaymentReceipt.value = receipt;
        if (!receipt.success) {
          throw Exception('Transaction reverted onchain: $txHash');
        }
        paymentStatus.value = PaymentFlowStatus.success;
        paymentStatusMessage.value = 'Payment confirmed onchain.';
        await refreshNativeBalanceSilently();
      } else {
        paymentStatus.value = PaymentFlowStatus.submitted;
        paymentStatusMessage.value = 'Payment submitted to the network.';
      }
      return txHash;
    } catch (e) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = e.toString();
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<String> activateEasyGameLevel({
    required int level,
    double? amountEther,
    BigInt? amountWei,
    String? inviter,
    bool waitForReceipt = true,
  }) async {
    if (level < 1 || level > 17) {
      throw Exception('Invalid Easy Game level');
    }

    if (!isConnected.value) {
      await connectBaseAccount();
    }
    await ensureBaseNetwork();

    final contractAddress = await resolveEasyGameAddress();
    final inviterAddress = _normalizeAddress(
      inviter?.isNotEmpty == true ? inviter! : activeInviter,
    );
    final paymentWei = amountWei ??
        (amountEther != null
            ? _etherToWei(amountEther)
            : await getEasyGameLevelPriceWei(level));
    final txParams = _easyGameActivationTxParams(
      contractAddress: contractAddress,
      level: level,
      inviterAddress: inviterAddress,
      paymentWei: paymentWei,
    );

    isPaying.value = true;
    paymentStatus.value = PaymentFlowStatus.preparing;
    paymentStatusMessage.value = 'Preparing contract payment.';
    lastPaymentTxHash.value = '';
    lastPaymentReceipt.value = null;
    lastLevelPaymentWei.value = paymentWei;
    try {
      paymentStatus.value = PaymentFlowStatus.estimatingGas;
      paymentStatusMessage.value =
          'Estimating gas on ${currentNetwork.displayName}.';
      lastGasEstimate.value = await _estimateGas(txParams);

      paymentStatus.value = PaymentFlowStatus.waitingForWallet;
      paymentStatusMessage.value =
          'Confirm the contract transaction in your wallet.';
      final txHash = await _walletRequest<String>('eth_sendTransaction', [
        txParams,
      ]);
      lastPaymentTxHash.value = txHash;

      if (waitForReceipt) {
        paymentStatus.value = PaymentFlowStatus.confirming;
        paymentStatusMessage.value = 'Waiting for onchain confirmation.';
        final receipt = await waitForTransactionReceipt(txHash);
        lastPaymentReceipt.value = receipt;
        if (!receipt.success) {
          throw Exception('Transaction reverted onchain: $txHash');
        }
        paymentStatus.value = PaymentFlowStatus.success;
        paymentStatusMessage.value = 'Level activation confirmed onchain.';
        await refreshNativeBalanceSilently();
      } else {
        paymentStatus.value = PaymentFlowStatus.submitted;
        paymentStatusMessage.value = 'Transaction submitted to the network.';
      }
      return txHash;
    } catch (e) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = e.toString();
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<String> activateEasyGameLevelWithUSDC({
    required int level,
    String? inviter,
    bool waitForReceipt = true,
  }) async {
    if (level < 1 || level > 17) {
      throw Exception('Invalid Easy Game level');
    }

    if (!isConnected.value) {
      await connectBaseAccount();
    }
    await ensureBaseNetwork();

    final contractAddress = await resolveEasyGameAddress();
    final tokenAddress = await resolveUsdcAddress();
    final inviterAddress = _normalizeAddress(
      inviter?.isNotEmpty == true ? inviter! : activeInviter,
    );
    final paymentUsdc = await getEasyGameLevelPriceUsdc(level);

    isPaying.value = true;
    paymentStatus.value = PaymentFlowStatus.preparing;
    paymentStatusMessage.value = 'wallet.usdcPreparing'.tr;
    lastPaymentTxHash.value = '';
    lastPaymentReceipt.value = null;
    lastLevelPaymentWei.value = BigInt.zero;

    try {
      final allowance = await getUsdcAllowance(
        owner: currentAddress.value,
        spender: contractAddress,
      );
      if (allowance < paymentUsdc) {
        paymentStatus.value = PaymentFlowStatus.waitingForWallet;
        paymentStatusMessage.value = 'wallet.usdcApprove'.tr;
        final approveTx = {
          'from': currentAddress.value,
          'to': tokenAddress,
          'value': '0x0',
          'data': _appendBuilderDataSuffix(
            _erc20ApproveCallData(contractAddress, paymentUsdc),
          ),
        };
        paymentStatus.value = PaymentFlowStatus.estimatingGas;
        lastGasEstimate.value = await _estimateGas(approveTx);
        paymentStatus.value = PaymentFlowStatus.waitingForWallet;
        final approveHash = await _walletRequest<String>(
          'eth_sendTransaction',
          [approveTx],
        );
        if (waitForReceipt) {
          paymentStatus.value = PaymentFlowStatus.confirming;
          paymentStatusMessage.value = 'wallet.usdcWaitingApproval'.tr;
          final receipt = await waitForTransactionReceipt(approveHash);
          if (!receipt.success) {
            throw Exception('USDC approval reverted onchain: $approveHash');
          }
        }
      }

      final txParams = {
        'from': currentAddress.value,
        'to': contractAddress,
        'value': '0x0',
        'data': _appendBuilderDataSuffix(
          _activateLevelWithUsdcCallData(level, inviterAddress),
        ),
      };

      paymentStatus.value = PaymentFlowStatus.estimatingGas;
      paymentStatusMessage.value = 'wallet.usdcEstimating'.trParams({
        'network': currentNetwork.displayName,
      });
      lastGasEstimate.value = await _estimateGas(txParams);

      paymentStatus.value = PaymentFlowStatus.waitingForWallet;
      paymentStatusMessage.value = 'wallet.usdcConfirm'.tr;
      final txHash = await _walletRequest<String>('eth_sendTransaction', [
        txParams,
      ]);
      lastPaymentTxHash.value = txHash;

      if (waitForReceipt) {
        paymentStatus.value = PaymentFlowStatus.confirming;
        paymentStatusMessage.value = 'wallet.waitingConfirmation'.tr;
        final receipt = await waitForTransactionReceipt(txHash);
        lastPaymentReceipt.value = receipt;
        if (!receipt.success) {
          throw Exception('USDC activation reverted onchain: $txHash');
        }
        paymentStatus.value = PaymentFlowStatus.success;
        paymentStatusMessage.value = 'wallet.usdcConfirmed'.tr;
        await refreshNativeBalanceSilently();
      } else {
        paymentStatus.value = PaymentFlowStatus.submitted;
        paymentStatusMessage.value = 'wallet.usdcSubmitted'.tr;
      }
      return txHash;
    } catch (e) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = e.toString();
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<String> activateEasyGameRound({
    required GameRoundSchedule round,
    String? inviter,
    bool waitForReceipt = true,
  }) async {
    if (!isConnected.value) await connectBaseAccount();
    await ensureBaseNetwork();
    final contractAddress = await resolveEasyGameAddress();
    final inviterAddress = _normalizeAddress(
      inviter?.isNotEmpty == true ? inviter! : activeInviter,
    );
    final data = await _roundActivationCallData(
      functionName: 'activateRound',
      round: round,
      inviterAddress: inviterAddress,
    );
    return _submitEasyGameTransaction(
      contractAddress: contractAddress,
      data: data,
      paymentWei: round.ethPriceWei,
      waitForReceipt: waitForReceipt,
    );
  }

  Future<String> activateEasyGameRoundWithUSDC({
    required GameRoundSchedule round,
    String? inviter,
    bool waitForReceipt = true,
  }) async {
    if (isPaying.value) {
      throw StateError('payment.alreadyProcessing'.tr);
    }
    if (!isConnected.value) await connectBaseAccount();
    await ensureBaseNetwork();
    final contractAddress = await resolveEasyGameAddress();
    final tokenAddress = await resolveUsdcAddress();
    final inviterAddress = _normalizeAddress(
      inviter?.isNotEmpty == true ? inviter! : activeInviter,
    );
    isPaying.value = true;
    lastPaymentReceipt.value = null;
    try {
      final allowance = await getUsdcAllowance(
        owner: currentAddress.value,
        spender: contractAddress,
      );
      if (allowance < round.usdcPrice) {
        paymentStatus.value = PaymentFlowStatus.estimatingGas;
        paymentStatusMessage.value = 'wallet.usdcApprove'.tr;
        final approveTx = {
          'from': currentAddress.value,
          'to': tokenAddress,
          'value': '0x0',
          'data': _appendBuilderDataSuffix(
            _erc20ApproveCallData(contractAddress, round.usdcPrice),
          ),
        };
        lastGasEstimate.value = await _estimateGas(approveTx);
        paymentStatus.value = PaymentFlowStatus.waitingForWallet;
        final approveHash = await _walletRequest<String>(
          'eth_sendTransaction',
          [approveTx],
        );

        // Activation depends on this state change, so approval must always be
        // confirmed even when the caller does not wait for activation receipt.
        paymentStatus.value = PaymentFlowStatus.confirming;
        paymentStatusMessage.value = 'wallet.usdcWaitingApproval'.tr;
        final receipt = await waitForTransactionReceipt(approveHash);
        if (!receipt.success) {
          throw Exception('USDC approval reverted onchain: $approveHash');
        }
      }
      final data = await _roundActivationCallData(
        functionName: 'activateRoundWithUSDC',
        round: round,
        inviterAddress: inviterAddress,
      );
      return await _submitEasyGameTransaction(
        contractAddress: contractAddress,
        data: data,
        paymentWei: BigInt.zero,
        waitForReceipt: waitForReceipt,
        paymentFlowStarted: true,
      );
    } catch (error) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = error.toString();
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<String> _submitEasyGameTransaction({
    required String contractAddress,
    required String data,
    required BigInt paymentWei,
    required bool waitForReceipt,
    bool paymentFlowStarted = false,
  }) async {
    if (isPaying.value && !paymentFlowStarted) {
      throw StateError('payment.alreadyProcessing'.tr);
    }
    final txParams = {
      'from': currentAddress.value,
      'to': contractAddress,
      'value': '0x${paymentWei.toRadixString(16)}',
      'data': _appendBuilderDataSuffix(data),
    };
    isPaying.value = true;
    paymentStatus.value = PaymentFlowStatus.estimatingGas;
    lastPaymentReceipt.value = null;
    try {
      lastGasEstimate.value = await _estimateGas(txParams);
      paymentStatus.value = PaymentFlowStatus.waitingForWallet;
      final txHash = await _walletRequest<String>(
        'eth_sendTransaction',
        [txParams],
      );
      lastPaymentTxHash.value = txHash;
      if (waitForReceipt) {
        paymentStatus.value = PaymentFlowStatus.confirming;
        final receipt = await waitForTransactionReceipt(txHash);
        lastPaymentReceipt.value = receipt;
        if (!receipt.success) {
          throw Exception('Round activation reverted onchain: $txHash');
        }
        paymentStatus.value = PaymentFlowStatus.success;
        await refreshNativeBalanceSilently();
      } else {
        paymentStatus.value = PaymentFlowStatus.submitted;
      }
      return txHash;
    } catch (error) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = '$error';
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<String> _roundActivationCallData({
    required String functionName,
    required GameRoundSchedule round,
    required String inviterAddress,
  }) async {
    final artifact = jsonDecode(
      await rootBundle.loadString('src/artifacts/EasyGameAdvance.json'),
    ) as Map<String, dynamic>;
    final abi = web3.ContractAbi.fromJson(
      jsonEncode(artifact['abi']),
      'EasyGameAdvance',
    );
    final function = abi.functions.firstWhere(
      (item) => item.name == functionName,
    );
    final encoded = function.encodeCall([
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
        _hexBytes(round.winningCellsRoot),
        round.ethPriceWei,
        round.usdcPrice,
        BigInt.from(round.freezeLimit),
        BigInt.from(round.paymentSplitVersion),
      ],
      _hexBytes(round.operatorSignature),
      wallet.EthereumAddress.fromHex(inviterAddress),
    ]);
    return web3.bytesToHex(encoded, include0x: true);
  }

  Uint8List _hexBytes(String value) {
    final normalized = value.startsWith('0x') ? value.substring(2) : value;
    if (normalized.length.isOdd ||
        !RegExp(r'^[0-9a-fA-F]+$').hasMatch(normalized)) {
      throw const FormatException('Invalid hexadecimal round data');
    }
    return Uint8List.fromList(List.generate(
      normalized.length ~/ 2,
      (index) => int.parse(
        normalized.substring(index * 2, index * 2 + 2),
        radix: 16,
      ),
    ));
  }

  Future<EasyGamePaymentPreview> previewEasyGameLevelPayment({
    required int level,
    String? inviter,
  }) async {
    if (!isConnected.value) {
      await connectBaseAccount();
    }
    await ensureBaseNetwork();

    isEstimatingPayment.value = true;
    try {
      final contractAddress = await resolveEasyGameAddress();
      final inviterAddress = _normalizeAddress(
        inviter?.isNotEmpty == true ? inviter! : activeInviter,
      );
      final paymentWei = await getEasyGameLevelPriceWei(level);
      final txParams = _easyGameActivationTxParams(
        contractAddress: contractAddress,
        level: level,
        inviterAddress: inviterAddress,
        paymentWei: paymentWei,
      );
      final gasEstimate = await _estimateGas(txParams);
      lastGasEstimate.value = gasEstimate;
      lastLevelPaymentWei.value = paymentWei;
      return EasyGamePaymentPreview(
        paymentWei: paymentWei,
        gasEstimate: gasEstimate,
        network: currentNetwork,
      );
    } finally {
      isEstimatingPayment.value = false;
    }
  }

  Future<BigInt> getEasyGameLevelPriceWei(int level) async {
    final response = await _easyGameCall(
      '0x2e50d906${level.toRadixString(16).padLeft(64, '0')}',
    );
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<BigInt> getEasyGameLevelPriceUsdc(int level) async {
    final response = await _easyGameCall(
      '0x04eb2734${level.toRadixString(16).padLeft(64, '0')}',
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

  Future<bool> isEasyGameLevelAvailable(int level) async {
    final response = await _easyGameCall(
      '0x52ebb227${level.toRadixString(16).padLeft(64, '0')}',
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

  Future<EasyGameAdvanceLevelStats> getEasyGameAdvanceLevelStats(
    int level,
  ) async {
    final response = await _easyGameCall(
      '0x22fbfe80${level.toRadixString(16).padLeft(64, '0')}',
    );
    final words = _decodeWords(response);
    return EasyGameAdvanceLevelStats(
      prizePoolWei: _wordToBigInt(words[0]),
      totalWeight: _wordToBigInt(words[1]),
      activeCells: _wordToBigInt(words[2]),
      nextOpenParentId: _wordToBigInt(words[3]),
      nextCellId: _wordToBigInt(words[4]),
    );
  }

  Future<GameRoundPhase> getEasyGameRoundPhase(BigInt roundId) async {
    final response = await _roundManagerCall(
      '0xdfa0ec76${roundId.toRadixString(16).padLeft(64, '0')}',
    );
    final value = _wordToBigInt(_decodeWords(response).first).toInt();
    if (value < 0 || value >= GameRoundPhase.values.length) {
      throw Exception('Invalid on-chain round phase: $value');
    }
    return GameRoundPhase.values[value];
  }

  Future<GameRoundChainState> getEasyGameRoundState(BigInt roundId) async {
    final encodedRoundId = roundId.toRadixString(16).padLeft(64, '0');
    final responses = await Future.wait([
      _roundManagerCall('0xc642e7bf$encodedRoundId'),
      getEasyGameRoundPhase(roundId),
    ]);
    final words = _decodeWords(responses[0] as String);
    final initializedAtSeconds = _wordToBigInt(words[1]);
    final initialized = _wordToBool(words[4]);
    var ethPriceWei = BigInt.zero;
    var usdcPrice = BigInt.zero;
    if (initialized) {
      final configValues = await _abiCall(
        artifactName: 'EasyGameRoundManager',
        contractAddress: await resolveRoundManagerAddress(),
        functionName: 'getRoundConfig',
        parameters: [roundId],
      );
      final tuple = configValues.length == 1 && configValues.first is List
          ? List<dynamic>.from(configValues.first as List)
          : configValues;
      if (tuple.length < 12) {
        throw Exception('Invalid on-chain round config response');
      }
      ethPriceWei = tuple[10] as BigInt;
      usdcPrice = tuple[11] as BigInt;
    }
    return GameRoundChainState(
      roundId: roundId,
      configHash: '0x${words[0]}',
      initializedAt: initializedAtSeconds == BigInt.zero
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              initializedAtSeconds.toInt() * 1000,
              isUtc: true,
            ),
      occupiedCells: _wordToBigInt(words[2]),
      winnersRegistered: _wordToBigInt(words[3]),
      initialized: initialized,
      settled: _wordToBool(words[5]),
      cancelled: _wordToBool(words[6]),
      paused: _wordToBool(words[7]),
      prizePoolEth: _wordToBigInt(words[8]),
      prizePoolUsdc: _wordToBigInt(words[9]),
      ethPriceWei: ethPriceWei,
      usdcPrice: usdcPrice,
      phase: responses[1] as GameRoundPhase,
    );
  }

  Future<RoundMatrixStats> getRoundMatrixStats(BigInt roundId) async {
    final values = await _abiCall(
      artifactName: 'EasyGameAdvance',
      contractAddress: await resolveEasyGameAddress(),
      functionName: 'getRoundGameStats',
      parameters: [roundId],
    );
    return RoundMatrixStats(
      prizePoolEth: values[0] as BigInt,
      prizePoolUsdc: values[1] as BigInt,
      totalWeight: values[2] as BigInt,
      activeCells: values[3] as BigInt,
      nextCellId: values[4] as BigInt,
      nextOpenParentId: values[5] as BigInt,
    );
  }

  Future<RoundPlayerState> getRoundPlayerState(
    BigInt roundId, {
    String? playerAddress,
  }) async {
    final values = await _abiCall(
      artifactName: 'EasyGameAdvance',
      contractAddress: await resolveEasyGameAddress(),
      functionName: 'getPlayerRound',
      parameters: [
        wallet.EthereumAddress.fromHex(
          _normalizeAddress(playerAddress ?? currentAddress.value),
        ),
        roundId,
      ],
    );
    final tuple = List<dynamic>.from(values.first as List);
    return RoundPlayerState(
      active: tuple[0] as bool,
      frozen: tuple[1] as bool,
      level: (tuple[2] as BigInt).toInt(),
      cellId: tuple[4] as BigInt,
      cycleCount: tuple[8] as BigInt,
      totalWeight: tuple[9] as BigInt,
    );
  }

  Future<RoundMatrixNode> getRoundMatrixNode(
    BigInt roundId,
    BigInt cellId,
  ) async {
    final values = await _abiCall(
      artifactName: 'EasyGameAdvance',
      contractAddress: await resolveEasyGameAddress(),
      functionName: 'getRoundMatrixNode',
      parameters: [roundId, cellId],
    );
    final tuple = List<dynamic>.from(values.first as List);
    return RoundMatrixNode(
      cellId: tuple[0] as BigInt,
      player: _addressText(tuple[1]),
      parentCellId: tuple[3] as BigInt,
      closed: tuple[6] as bool,
    );
  }

  Future<ArenaSkillStatus> getArenaSkillStatus(
    BigInt roundId, {
    String? playerAddress,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final contract = await resolveArenaSkillsAddress();
    final results = await Future.wait([
      _abiCall(
        artifactName: 'EasyGameArenaSkills',
        contractAddress: contract,
        functionName: 'getArenaStatus',
        parameters: [roundId, wallet.EthereumAddress.fromHex(address)],
      ),
      _abiCall(
        artifactName: 'EasyGameArenaSkills',
        contractAddress: contract,
        functionName: 'getUnfreezePriceUsdc',
        parameters: [roundId, wallet.EthereumAddress.fromHex(address)],
      ),
    ]);
    final status = results[0];
    final until = status[2] as BigInt;
    return ArenaSkillStatus(
      frozen: status[0] as bool,
      immune: status[1] as bool,
      frozenUntil: until == BigInt.zero
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              until.toInt() * 1000,
              isUtc: true,
            ),
      freezeHits: (status[3] as BigInt).toInt(),
      freezeTokens: (status[4] as BigInt).toInt(),
      unfreezePriceUsdc: results[1].first as BigInt,
    );
  }

  Future<EasyGameAdvanceLevelStats> getEasyGameAdvanceLevelStatsUsdc(
    int level,
  ) async {
    final response = await _easyGameCall(
      '0x26e0cfe7${level.toRadixString(16).padLeft(64, '0')}',
    );
    final words = _decodeWords(response);
    return EasyGameAdvanceLevelStats(
      prizePoolWei: _wordToBigInt(words[0]),
      totalWeight: _wordToBigInt(words[1]),
      activeCells: _wordToBigInt(words[2]),
      nextOpenParentId: _wordToBigInt(words[3]),
      nextCellId: _wordToBigInt(words[4]),
    );
  }

  Future<EasyGameTokenRewards> getEasyGameTokenRewards({
    String? playerAddress,
    required int level,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final response = await _easyGameCall(
      _encodeAddressUint8Call('4ca3696c', address, level),
    );
    final words = _decodeWords(response);
    return EasyGameTokenRewards(
      referralBonusUsdc: _wordToBigInt(words[0]),
      claimablePrizeUsdc: _wordToBigInt(words[1]),
      pendingPrizeUsdc: _wordToBigInt(words[2]),
    );
  }

  Future<BigInt> getEasyGamePlayerWeight({
    String? playerAddress,
    required int level,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final response = await _easyGameCall(
      _encodeAddressUint8Call('03a65dfa', address, level),
    );
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<BigInt> getEasyGamePlayerChanceBps({
    String? playerAddress,
    required int level,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final response = await _easyGameCall(
      _encodeAddressUint8Call('7dcda2d4', address, level),
    );
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<BigInt> getEasyGameMatrixPrizePoolWei(int level) async {
    final response = await _easyGameCall(
      '0x8c5b8ea5${level.toRadixString(16).padLeft(64, '0')}',
    );
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<BigInt> getEasyGameProjectFeesAccruedWei() async {
    final response = await _easyGameCall('0x19a08594');
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<BigInt> getEasyGameProjectFeesAccruedUsdc() async {
    final response = await _easyGameCall('0xe26f7c46');
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<String> resolveUsdcAddress() async {
    final configured = ReferralLinkService.normalizeAddress(usdcTokenAddress);
    final response = await _easyGameCall('0x11eac855');
    final onChain = _wordToAddress(_decodeWords(response).first);
    if (onChain == _zeroAddress) {
      throw Exception(
        'USDC token is not configured. Deploy with USDC_ADDRESS=0x... or call setUsdcToken.',
      );
    }
    if (configured.isNotEmpty && configured.toLowerCase() != onChain) {
      throw StateError('payment.usdcConfigurationMismatch'.tr);
    }
    return onChain;
  }

  Future<String> resolveBasePayGatewayAddress() async {
    final values = await _abiCall(
      artifactName: 'EasyGameAdvance',
      contractAddress: await resolveEasyGameAddress(),
      functionName: 'basePayGateway',
      parameters: const [],
    );
    final onChain = _addressText(values.first).toLowerCase();
    if (onChain == _zeroAddress) {
      throw StateError('payment.basePayUnavailable'.tr);
    }
    final configured = ReferralLinkService.normalizeAddress(
      Get.find<AppConfigService>().get('basePayGatewayAddress'),
    );
    if (configured.isNotEmpty && configured.toLowerCase() != onChain) {
      throw StateError('payment.basePayConfigurationMismatch'.tr);
    }
    return onChain;
  }

  Future<BigInt> getUsdcBalance({String? owner}) async {
    final tokenAddress = await resolveUsdcAddress();
    final address = _normalizeAddress(owner ?? currentAddress.value);
    final response = await _ethCall(
      to: tokenAddress,
      data: _encodeAddressCall('70a08231', address),
    );
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<BigInt> getUsdcAllowance({
    required String owner,
    required String spender,
  }) async {
    final tokenAddress = await resolveUsdcAddress();
    final response = await _ethCall(
      to: tokenAddress,
      data: _encodeAddressAddressCall(
        'dd62ed3e',
        _normalizeAddress(owner),
        _normalizeAddress(spender),
      ),
    );
    return _wordToBigInt(_decodeWords(response).first);
  }

  Future<EasyGamePlayerSummary> getEasyGamePlayerSummary({
    String? playerAddress,
  }) async {
    final address = _normalizeAddress(playerAddress ?? currentAddress.value);
    final response =
        await _easyGameCall(_encodeAddressCall('5c12cd4b', address));
    final words = _decodeWords(response);

    return EasyGamePlayerSummary(
      exists: _wordToBool(words[0]),
      wallet: _wordToAddress(words[1]),
      inviter: _wordToAddress(words[2]),
      secondLine: _wordToAddress(words[3]),
      thirdLine: _wordToAddress(words[4]),
      totalTickets: _wordToBigInt(words[5]),
      baseWeight: _wordToBigInt(words[6]),
      referralWeight: _wordToBigInt(words[7]),
      loyaltyWeight: _wordToBigInt(words[8]),
      matrixWeight: _wordToBigInt(words[9]),
      nftWeight: _wordToBigInt(words[10]),
      totalWeight: _wordToBigInt(words[11]),
      boxTokens: _wordToBigInt(words[12]),
      recycleCount: _wordToBigInt(words[13]),
      claimableReferralBonusWei: _wordToBigInt(words[14]),
      claimablePrizeWei: _wordToBigInt(words[15]),
      pendingPrizeWei: _wordToBigInt(words[16]),
      joinedAt: _wordToBigInt(words[17]),
      lastActiveAt: _wordToBigInt(words[18]),
    );
  }

  Future<String> claimEasyGameReferralBonus({
    bool waitForReceipt = true,
  }) {
    return _sendEasyGameContractTransaction(
      data: '0x1e375ab9',
      paymentWei: BigInt.zero,
      preparingMessage: 'Preparing referral bonus claim.',
      successMessage: 'Referral bonus claim confirmed onchain.',
      submittedMessage: 'Referral bonus claim submitted to the network.',
      waitForReceipt: waitForReceipt,
    );
  }

  Future<String> claimEasyGameReferralBonusUSDC({
    bool waitForReceipt = true,
  }) {
    return _sendEasyGameContractTransaction(
      data: '0xedfae883',
      paymentWei: BigInt.zero,
      preparingMessage: 'wallet.usdcReferralPreparing'.tr,
      successMessage: 'wallet.usdcReferralConfirmed'.tr,
      submittedMessage: 'wallet.usdcReferralSubmitted'.tr,
      waitForReceipt: waitForReceipt,
    );
  }

  Future<String> claimEasyGamePrize({
    required int level,
    bool waitForReceipt = true,
  }) {
    if (level < 1 || level > 17) {
      throw Exception('Invalid Easy Game level');
    }
    final encodedLevel = level.toRadixString(16).padLeft(64, '0');
    return _sendEasyGameContractTransaction(
      data: '0xc864ce56$encodedLevel',
      paymentWei: BigInt.zero,
      preparingMessage: 'Preparing prize claim.',
      successMessage: 'Prize claim confirmed onchain.',
      submittedMessage: 'Prize claim submitted to the network.',
      waitForReceipt: waitForReceipt,
    );
  }

  Future<String> claimEasyGamePrizeUSDC({
    required int level,
    bool waitForReceipt = true,
  }) {
    if (level < 1 || level > 17) {
      throw Exception('Invalid Easy Game level');
    }
    final encodedLevel = level.toRadixString(16).padLeft(64, '0');
    return _sendEasyGameContractTransaction(
      data: '0x3f896dd9$encodedLevel',
      paymentWei: BigInt.zero,
      preparingMessage: 'wallet.usdcPrizePreparing'.tr,
      successMessage: 'wallet.usdcPrizeConfirmed'.tr,
      submittedMessage: 'wallet.usdcPrizeSubmitted'.tr,
      waitForReceipt: waitForReceipt,
    );
  }

  Future<String> resolveEasyGameAddress() async {
    final configuredAddress = await _configuredEasyGameAddress();
    if (configuredAddress.isNotEmpty) {
      easyGameAddress.value = configuredAddress;
      return configuredAddress;
    }

    if (easyGameAddress.value.isNotEmpty) {
      return easyGameAddress.value;
    }

    if (isConnected.value) {
      await refreshChainId();
    }
    try {
      final artifact = jsonDecode(
        await rootBundle.loadString('src/artifacts/EasyGameAdvance.json'),
      ) as Map<String, dynamic>;
      final networks = artifact['networks'] as Map<String, dynamic>? ?? {};
      final chainKey = '${chainId.value ?? targetNetwork.chainId}';
      final network = networks[chainKey] as Map<String, dynamic>?;
      final address = network?['address'] as String?;

      if (address == null || address.isEmpty) {
        throw Exception(
          'EasyGameAdvance contract is not deployed for chain $chainKey. Deploy it or build with --dart-define=EASY_GAME_ADDRESS=0x...',
        );
      }

      easyGameAddress.value = address;
      return address;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        'Unable to load EasyGameAdvance artifact. Run hardhat compile/deploy or build with --dart-define=EASY_GAME_ADDRESS=0x...',
      );
    }
  }

  Future<String> resolveRoundManagerAddress() async {
    final configuredAddress = easyGameRoundManagerAddress;
    if (configuredAddress.isNotEmpty) {
      roundManagerAddress.value = configuredAddress;
      return configuredAddress;
    }
    if (roundManagerAddress.value.isNotEmpty) return roundManagerAddress.value;

    if (isConnected.value) await refreshChainId();
    try {
      final artifact = jsonDecode(
        await rootBundle.loadString('src/artifacts/EasyGameRoundManager.json'),
      ) as Map<String, dynamic>;
      final networks = artifact['networks'] as Map<String, dynamic>? ?? {};
      final chainKey = '${chainId.value ?? targetNetwork.chainId}';
      final network = networks[chainKey] as Map<String, dynamic>?;
      final address = network?['address'] as String?;
      if (address == null || address.isEmpty) {
        throw Exception(
          'EasyGameRoundManager is not deployed for chain $chainKey.',
        );
      }
      roundManagerAddress.value = address;
      return address;
    } catch (error) {
      if (error is Exception) rethrow;
      throw Exception('Unable to load EasyGameRoundManager artifact.');
    }
  }

  Future<String> resolveArenaSkillsAddress() async {
    final configured = Get.find<AppConfigService>().get('arenaSkillsAddress');
    if (configured.isNotEmpty) {
      arenaSkillsAddress.value = configured;
      return configured;
    }
    if (arenaSkillsAddress.value.isNotEmpty) return arenaSkillsAddress.value;
    final artifact = jsonDecode(
      await rootBundle.loadString('src/artifacts/EasyGameArenaSkills.json'),
    ) as Map<String, dynamic>;
    final networks = artifact['networks'] as Map<String, dynamic>? ?? {};
    final chainKey = '${chainId.value ?? targetNetwork.chainId}';
    final address =
        (networks[chainKey] as Map<String, dynamic>?)?['address'] as String?;
    if (address == null || address.isEmpty) {
      throw Exception(
          'EasyGameArenaSkills is not deployed for chain $chainKey.');
    }
    arenaSkillsAddress.value = address;
    return address;
  }

  Future<String> buyArenaFreezeToken(BigInt roundId) async {
    const price = 300000;
    final skills = await resolveArenaSkillsAddress();
    await _ensureUsdcAllowance(skills, BigInt.from(price));
    final data = await _abiCallData(
      artifactName: 'EasyGameArenaSkills',
      functionName: 'buyFreezeToken',
      parameters: [roundId],
    );
    return _submitEasyGameTransaction(
      contractAddress: skills,
      data: data,
      paymentWei: BigInt.zero,
      waitForReceipt: true,
    );
  }

  Future<String> freezeArenaPlayer(BigInt roundId, String target) async {
    final skills = await resolveArenaSkillsAddress();
    final data = await _abiCallData(
      artifactName: 'EasyGameArenaSkills',
      functionName: 'freezePlayer',
      parameters: [
        roundId,
        wallet.EthereumAddress.fromHex(_normalizeAddress(target))
      ],
    );
    return _submitEasyGameTransaction(
      contractAddress: skills,
      data: data,
      paymentWei: BigInt.zero,
      waitForReceipt: true,
    );
  }

  Future<String> buyArenaUnfreeze(BigInt roundId) async {
    final skills = await resolveArenaSkillsAddress();
    final status = await getArenaSkillStatus(roundId);
    await _ensureUsdcAllowance(skills, status.unfreezePriceUsdc);
    final data = await _abiCallData(
      artifactName: 'EasyGameArenaSkills',
      functionName: 'buyUnfreeze',
      parameters: [roundId],
    );
    return _submitEasyGameTransaction(
      contractAddress: skills,
      data: data,
      paymentWei: BigInt.zero,
      waitForReceipt: true,
    );
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
    final artifact = jsonDecode(
      await rootBundle.loadString(
        'src/artifacts/EasyGameRoundSettlement.json',
      ),
    ) as Map<String, dynamic>;
    final networks = artifact['networks'] as Map<String, dynamic>? ?? {};
    final chainKey = '${chainId.value ?? targetNetwork.chainId}';
    final address =
        (networks[chainKey] as Map<String, dynamic>?)?['address'] as String?;
    if (address == null || address.isEmpty) {
      throw Exception(
        'EasyGameRoundSettlement is not deployed for chain $chainKey.',
      );
    }
    roundSettlementAddress.value = address;
    return address;
  }

  Future<SettlementClaimable> getSettlementClaimable() async {
    if (currentAddress.value.isEmpty) return SettlementClaimable.zero;
    final settlement = await resolveRoundSettlementAddress();
    final player = wallet.EthereumAddress.fromHex(
      _normalizeAddress(currentAddress.value),
    );
    final values = await Future.wait([
      _abiCall(
        artifactName: 'EasyGameRoundSettlement',
        contractAddress: settlement,
        functionName: 'claimableEth',
        parameters: [player],
      ),
      _abiCall(
        artifactName: 'EasyGameRoundSettlement',
        contractAddress: settlement,
        functionName: 'claimableUsdc',
        parameters: [player],
      ),
    ]);
    return SettlementClaimable(
      ethAmount: values[0].first as BigInt,
      usdcAmount: values[1].first as BigInt,
    );
  }

  Future<String> settleEasyGameRound(RoundSettlementProofs settlement) async {
    final address = await resolveRoundSettlementAddress();
    final data = await _abiCallData(
      artifactName: 'EasyGameRoundSettlement',
      functionName: 'settleRound',
      parameters: [
        settlement.roundId,
        settlement.cells.map((cell) => cell.cellId).toList(growable: false),
        settlement.cells
            .map(
              (cell) => cell.proof.map(_hexBytes).toList(growable: false),
            )
            .toList(growable: false),
      ],
    );
    return _submitEasyGameTransaction(
      contractAddress: address,
      data: data,
      paymentWei: BigInt.zero,
      waitForReceipt: true,
    );
  }

  Future<String> claimSettlementPrize() async {
    final address = await resolveRoundSettlementAddress();
    final data = await _abiCallData(
      artifactName: 'EasyGameRoundSettlement',
      functionName: 'claimPrize',
      parameters: const [],
    );
    return _submitEasyGameTransaction(
      contractAddress: address,
      data: data,
      paymentWei: BigInt.zero,
      waitForReceipt: true,
    );
  }

  Future<void> _ensureUsdcAllowance(String spender, BigInt amount) async {
    final allowance = await getUsdcAllowance(
      owner: currentAddress.value,
      spender: spender,
    );
    if (allowance >= amount) return;
    final tokenAddress = await resolveUsdcAddress();
    final transaction = {
      'from': currentAddress.value,
      'to': tokenAddress,
      'value': '0x0',
      'data': _appendBuilderDataSuffix(_erc20ApproveCallData(spender, amount)),
    };
    final hash =
        await _walletRequest<String>('eth_sendTransaction', [transaction]);
    final receipt = await waitForTransactionReceipt(hash);
    if (!receipt.success) throw Exception('USDC approval reverted: $hash');
  }

  Future<String> _configuredEasyGameAddress() async {
    try {
      final config = Get.find<AppConfigService>();
      if (!config.isLoaded.value) {
        await config.fetch();
      }
      return config.get('easyGameContractAddress');
    } catch (_) {
      return easyGameContractAddress;
    }
  }

  void disconnectWallet() {
    final shouldDisconnectBase = isBaseAccountSession.value ||
        _sessionStore.read()?.provider == WalletSessionProvider.baseAccount;
    _clearRuntimeWalletState();
    unawaited(_sessionStore.clear());
    if (shouldDisconnectBase) {
      unawaited(_disconnectBaseProvider());
    }
  }

  void _clearRuntimeWalletState() {
    _invalidateBalanceRefresh();
    currentAddress.value = '';
    isConnected.value = false;
    isBaseAccountSession.value = false;
    authProvider.value = '';
    baseAccountMessage.value = '';
    baseAccountSignature.value = '';
    baseAccountNonce.value = '';
    resetPaymentState();
  }

  Future<void> refreshChainId() async {
    if (!isWalletAvailable) {
      chainId.value = null;
      activeNetwork.value = null;
      return;
    }

    try {
      final walletChainId = isBaseAccountSession.value
          ? _hexToBigInt(
              await _walletRequest<String>('eth_chainId', []),
            ).toInt()
          : await ethereum!.getChainId();
      chainId.value = walletChainId;
      activeNetwork.value = _networkForChainId(chainId.value);
      if (isConnected.value) {
        await refreshNativeBalanceSilently();
      }
    } catch (e) {
      if (kDebugMode && isConnected.value) {
        if (kDebugMode) {
          print('Unable to read wallet chain id: $e');
        }
      }
    }
  }

  Future<BigInt> refreshNativeBalance() {
    if (!isWalletAvailable || currentAddress.value.isEmpty) {
      nativeBalanceWei.value = null;
      return Future<BigInt>.value(BigInt.zero);
    }

    final activeRefresh = _balanceRefreshFuture;
    if (activeRefresh != null) return activeRefresh;

    isRefreshingBalance.value = true;
    late final Future<BigInt> operation;
    operation = _readNativeBalance().whenComplete(() {
      if (identical(_balanceRefreshFuture, operation)) {
        _balanceRefreshFuture = null;
        isRefreshingBalance.value = false;
      }
    });
    _balanceRefreshFuture = operation;
    return operation;
  }

  Future<BigInt> _readNativeBalance() async {
    final address = currentAddress.value;
    final balanceEpoch = _balanceEpoch;
    final result = await _readOnlyRequest<String>('eth_getBalance', [
      address,
      'latest',
    ]);
    final balance = _hexToBigInt(result);
    if (balanceEpoch == _balanceEpoch && currentAddress.value == address) {
      nativeBalanceWei.value = balance;
    }
    return balance;
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

  void _startBalanceRefresh() {
    _balanceRefreshTimer?.cancel();
    if (!isConnected.value || currentAddress.value.isEmpty) return;
    _balanceRefreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (isConnected.value) {
        unawaited(refreshNativeBalanceSilently());
      }
    });
  }

  Timer? _receiptPollTimer;
  Timer? _balanceRefreshTimer;
  Future<BigInt>? _balanceRefreshFuture;
  int _balanceEpoch = 0;

  void _prepareBalanceForAddress(String address) {
    if (currentAddress.value.toLowerCase() == address.toLowerCase()) return;
    _invalidateBalanceRefresh();
  }

  void _invalidateBalanceRefresh() {
    _balanceEpoch++;
    _balanceRefreshTimer?.cancel();
    _balanceRefreshTimer = null;
    _balanceRefreshFuture = null;
    isRefreshingBalance.value = false;
    nativeBalanceWei.value = null;
  }

  Future<EasyGameTransactionReceipt> waitForTransactionReceipt(
    String txHash, {
    Duration pollInterval = const Duration(seconds: 2),
    int maxAttempts = 90,
  }) async {
    final completer = Completer<EasyGameTransactionReceipt>();
    var attempt = 0;

    _receiptPollTimer?.cancel();
    _receiptPollTimer = Timer.periodic(pollInterval, (timer) async {
      if (completer.isCompleted) return;
      attempt++;
      try {
        final receipt = await getTransactionReceipt(txHash);
        if (receipt != null) {
          timer.cancel();
          completer.complete(receipt);
          return;
        }
      } catch (_) {
        // Ignore intermediate errors, keep polling
      }
      if (attempt >= maxAttempts) {
        timer.cancel();
        completer.completeError(Exception(
          'Transaction receipt was not available after ${maxAttempts * pollInterval.inSeconds}s: $txHash',
        ));
      }
    });

    return completer.future;
  }

  Future<EasyGameTransactionReceipt?> getTransactionReceipt(
    String txHash,
  ) async {
    final response = await _walletRequest<dynamic>(
      'eth_getTransactionReceipt',
      [txHash],
    );
    if (response == null) {
      return null;
    }
    if (response is! Map) {
      throw Exception('Invalid transaction receipt response');
    }

    final data = Map<String, dynamic>.from(response);
    return EasyGameTransactionReceipt(
      transactionHash: data['transactionHash']?.toString() ?? txHash,
      status: data['status']?.toString() ?? '0x0',
      blockNumber: _nullableHexToBigInt(data['blockNumber']?.toString()),
      gasUsed: _nullableHexToBigInt(data['gasUsed']?.toString()),
      effectiveGasPrice:
          _nullableHexToBigInt(data['effectiveGasPrice']?.toString()),
      to: data['to']?.toString(),
      from: data['from']?.toString(),
    );
  }

  Future<void> _restoreConnection() async {
    if (kDebugMode) {
      print("[DEBUG] WalletConnectService: _restoreConnection started.");
    }
    isRestoringSession.value = true;
    try {
      final saved = _sessionStore.read();
      var restored = false;

      if (saved?.provider == WalletSessionProvider.baseAccount) {
        restored = await _restoreBaseAccountConnection();
      } else if (saved?.provider == WalletSessionProvider.injectedWallet) {
        restored = await _restoreInjectedConnection();
      } else {
        // Backward compatibility for users who signed in before the app began
        // storing the preferred provider. Base Account keeps authorization in
        // its own SDK store, so this call does not open a popup.
        restored = await _restoreBaseAccountConnection();
        if (!restored) restored = await _restoreInjectedConnection();
      }

      if (!restored) _clearRuntimeWalletState();
    } catch (e) {
      if (kDebugMode) {
        print("[DEBUG] WalletConnectService: _restoreConnection - error: $e");
      }
      if (kDebugMode) {
        print('Unable to restore wallet connection: $e');
      }
    } finally {
      isRestoringSession.value = false;
      if (kDebugMode) {
        print("[DEBUG] WalletConnectService: _restoreConnection completed.");
      }
    }
  }

  Future<bool> _restoreBaseAccountConnection() async {
    if (!isBaseAccountBridgeAvailable) return false;
    try {
      final result = await restoreBaseAccountSession(
        chainId: targetNetwork.chainId,
        appName: baseAccountAppName,
        appLogoUrl: baseAccountAppLogoUrl,
      );
      if (result.address.isEmpty) return false;

      isBaseAccountSession.value = true;
      authProvider.value = 'base_account';
      baseAccountMessage.value = '';
      baseAccountSignature.value = '';
      baseAccountNonce.value = '';
      _prepareBalanceForAddress(result.address);
      currentAddress.value = result.address;
      isConnected.value = true;
      chainId.value = result.chainId;
      activeNetwork.value = _networkForChainId(result.chainId);
      await _persistSession(WalletSessionProvider.baseAccount);
      _startBalanceRefresh();
      await refreshNativeBalanceSilently();
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Unable to restore Base Account session: $error');
      }
      return false;
    }
  }

  Future<bool> _restoreInjectedConnection() async {
    if (!hasInjectedWallet) return false;
    try {
      final accounts = await ethereum!.getAccounts();
      if (accounts.isEmpty) return false;
      isBaseAccountSession.value = false;
      authProvider.value = 'injected_wallet';
      baseAccountMessage.value = '';
      baseAccountSignature.value = '';
      baseAccountNonce.value = '';
      _setAccounts(accounts);
      await refreshChainId();
      await _persistSession(WalletSessionProvider.injectedWallet);
      return true;
    } catch (error) {
      if (kDebugMode) {
        print('Unable to restore injected wallet session: $error');
      }
      return false;
    }
  }

  Future<void> _persistSession(WalletSessionProvider provider) async {
    final address = currentAddress.value;
    final currentChainId = chainId.value;
    if (address.isEmpty || currentChainId == null) return;
    await _sessionStore.save(WalletSessionSnapshot(
      provider: provider,
      address: address,
      chainId: currentChainId,
    ));
  }

  Future<void> _disconnectBaseProvider() async {
    if (!isBaseAccountBridgeAvailable) return;
    try {
      await disconnectBaseAccount(
        chainId: targetNetwork.chainId,
        appName: baseAccountAppName,
        appLogoUrl: baseAccountAppLogoUrl,
      );
    } catch (error) {
      if (kDebugMode) {
        print('Unable to disconnect Base Account provider: $error');
      }
    }
  }

  void _listenWalletChanges() {
    if (!hasInjectedWallet) {
      return;
    }

    ethereum!.onAccountsChanged((accounts) {
      _setAccounts(accounts);
    });
    ethereum!.onChainChanged((newChainId) {
      chainId.value = newChainId;
      activeNetwork.value = _networkForChainId(newChainId);
      isBaseAccountSession.value = false;
      authProvider.value = isConnected.value ? 'injected_wallet' : '';
      if (isConnected.value) {
        unawaited(_persistSession(WalletSessionProvider.injectedWallet));
        unawaited(refreshNativeBalanceSilently());
      }
    });
  }

  void _setAccounts(List<String> accounts) {
    if (accounts.isEmpty) {
      disconnectWallet();
      return;
    }

    _prepareBalanceForAddress(accounts.first);
    currentAddress.value = accounts.first;
    isConnected.value = true;
    _startBalanceRefresh();
    unawaited(refreshNativeBalanceSilently());
  }

  Future<T> _walletRequest<T>(String method, List<dynamic> params) async {
    if (isBaseAccountSession.value) {
      final result = await baseAccountRequest(method, params);
      return result as T;
    }

    if (!hasInjectedWallet) {
      throw Exception(
          'MetaMask, Base Account, or another Web3 wallet is not connected');
    }

    return ethereum!.request<T>(method, params);
  }

  Future<T> _readOnlyRequest<T>(
    String method,
    List<dynamic> params,
  ) async {
    final currentChainId = chainId.value;
    final useBaseRpc =
        currentChainId == null || currentChainId == targetNetwork.chainId;
    if (useBaseRpc) {
      try {
        return await _publicRpcRequest<T>(method, params);
      } catch (error) {
        if (kDebugMode) {
          print(
              'Base RPC read failed for $method, using wallet provider: $error');
        }
      }
    }
    return _walletRequest<T>(method, params);
  }

  Future<String> signMessage(String message) async {
    if (!isConnected.value || currentAddress.value.isEmpty) {
      await connectBaseAccount();
    }
    final encoded =
        '0x${utf8.encode(message).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join()}';
    return _walletRequest<String>('personal_sign', [
      encoded,
      currentAddress.value,
    ]);
  }

  Future<void> _switchToNetwork(AppNetworkConfig network) async {
    final chainHex = _intToHex(network.chainId);
    try {
      await _walletRequest<dynamic>('wallet_switchEthereumChain', [
        {'chainId': chainHex},
      ]);
      return;
    } catch (e) {
      if (isBaseAccountSession.value || !network.canAddToWallet) {
        rethrow;
      }
    }

    await _walletRequest<dynamic>('wallet_addEthereumChain', [
      {
        'chainId': chainHex,
        'chainName': network.chainName,
        'nativeCurrency': {
          'name': network.currencyName,
          'symbol': network.currencySymbol,
          'decimals': 18,
        },
        'rpcUrls': [network.rpcUrl],
        'blockExplorerUrls':
            network.explorerUrl.isEmpty ? [] : [network.explorerUrl],
      },
    ]);
    await _walletRequest<dynamic>('wallet_switchEthereumChain', [
      {'chainId': chainHex},
    ]);
  }

  String _etherToHexWei(double amountEther) {
    return _bigIntToHex(_etherToWei(amountEther));
  }

  BigInt _etherToWei(double amountEther) {
    final fixed = amountEther.toStringAsFixed(18);
    final parts = fixed.split('.');
    final whole = BigInt.parse(parts.first);
    final fraction = (parts.length > 1 ? parts[1] : '').padRight(18, '0');
    return whole * BigInt.from(10).pow(18) + BigInt.parse(fraction);
  }

  String _bigIntToHex(BigInt value) => '0x${value.toRadixString(16)}';

  String _intToHex(int value) => '0x${value.toRadixString(16)}';

  BigInt _hexToBigInt(String value) {
    final clean = value.toLowerCase().replaceFirst('0x', '');
    if (clean.isEmpty) {
      return BigInt.zero;
    }
    return BigInt.parse(clean, radix: 16);
  }

  BigInt? _nullableHexToBigInt(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return _hexToBigInt(value);
  }

  static AppNetworkConfig? _networkForChainId(int? id) {
    switch (id) {
      case baseMainnetChainId:
        return baseMainnet;
      case baseSepoliaChainId:
        return baseSepolia;
      case ganacheChainId:
        return ganacheLocal;
      case ganacheDefaultChainId:
        return hardhatLocal;
      default:
        return null;
    }
  }

  String _activateLevelCallData(int level, String inviterAddress) {
    const selector = '48d46be1';
    final encodedLevel = level.toRadixString(16).padLeft(64, '0');
    final encodedInviter =
        inviterAddress.replaceFirst('0x', '').padLeft(64, '0');
    return '0x$selector$encodedLevel$encodedInviter';
  }

  String _activateLevelWithUsdcCallData(int level, String inviterAddress) {
    const selector = 'f4f5058d';
    final encodedLevel = level.toRadixString(16).padLeft(64, '0');
    final encodedInviter =
        inviterAddress.replaceFirst('0x', '').padLeft(64, '0');
    return '0x$selector$encodedLevel$encodedInviter';
  }

  String _erc20ApproveCallData(String spender, BigInt amount) {
    return _encodeAddressUint256Call(
      '095ea7b3',
      _normalizeAddress(spender),
      amount,
    );
  }

  Map<String, dynamic> _easyGameActivationTxParams({
    required String contractAddress,
    required int level,
    required String inviterAddress,
    required BigInt paymentWei,
  }) {
    return {
      'from': currentAddress.value,
      'to': contractAddress,
      'value': _bigIntToHex(paymentWei),
      'data': _appendBuilderDataSuffix(
        _activateLevelCallData(level, inviterAddress),
      ),
    };
  }

  Future<String> _sendEasyGameContractTransaction({
    required String data,
    required BigInt paymentWei,
    required String preparingMessage,
    required String successMessage,
    required String submittedMessage,
    bool waitForReceipt = true,
  }) async {
    if (!isConnected.value) {
      await connectBaseAccount();
    }
    await ensureBaseNetwork();

    final contractAddress = await resolveEasyGameAddress();
    final txParams = {
      'from': currentAddress.value,
      'to': contractAddress,
      'value': _bigIntToHex(paymentWei),
      'data': _appendBuilderDataSuffix(data),
    };

    isPaying.value = true;
    paymentStatus.value = PaymentFlowStatus.preparing;
    paymentStatusMessage.value = preparingMessage;
    lastPaymentTxHash.value = '';
    lastPaymentReceipt.value = null;
    lastLevelPaymentWei.value = paymentWei;

    try {
      paymentStatus.value = PaymentFlowStatus.estimatingGas;
      paymentStatusMessage.value =
          'Estimating gas on ${currentNetwork.displayName}.';
      lastGasEstimate.value = await _estimateGas(txParams);

      paymentStatus.value = PaymentFlowStatus.waitingForWallet;
      paymentStatusMessage.value =
          'Confirm the contract transaction in your wallet.';
      final txHash = await _walletRequest<String>('eth_sendTransaction', [
        txParams,
      ]);
      lastPaymentTxHash.value = txHash;

      if (waitForReceipt) {
        paymentStatus.value = PaymentFlowStatus.confirming;
        paymentStatusMessage.value = 'Waiting for onchain confirmation.';
        final receipt = await waitForTransactionReceipt(txHash);
        lastPaymentReceipt.value = receipt;
        if (!receipt.success) {
          throw Exception('Transaction reverted onchain: $txHash');
        }
        paymentStatus.value = PaymentFlowStatus.success;
        paymentStatusMessage.value = successMessage;
        await refreshNativeBalanceSilently();
      } else {
        paymentStatus.value = PaymentFlowStatus.submitted;
        paymentStatusMessage.value = submittedMessage;
      }
      return txHash;
    } catch (e) {
      paymentStatus.value = PaymentFlowStatus.failed;
      paymentStatusMessage.value = e.toString();
      rethrow;
    } finally {
      isPaying.value = false;
    }
  }

  Future<BigInt> _estimateGas(Map<String, dynamic> txParams) async {
    final gas = await _walletRequest<String>('eth_estimateGas', [txParams]);
    return _hexToBigInt(gas);
  }

  String _appendBuilderDataSuffix(String data) {
    final suffix = baseBuilderDataSuffix.trim();
    if (suffix.isEmpty) {
      return data;
    }
    if (!RegExp(r'^0x[a-fA-F0-9]*$').hasMatch(suffix)) {
      throw Exception('Invalid BASE_BUILDER_DATA_SUFFIX hex value');
    }
    return '$data${suffix.substring(2)}';
  }

  bool _isBaseAccountCoopError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('cross-origin-opener-policy') ||
        normalized.contains('coop') ||
        normalized.contains('same-origin-allow-popups');
  }

  Future<String> _easyGameCall(String data) async {
    final contractAddress = await resolveEasyGameAddress();
    return _ethCall(to: contractAddress, data: data);
  }

  Future<String> _roundManagerCall(String data) async {
    final contractAddress = await resolveRoundManagerAddress();
    return _ethCall(to: contractAddress, data: data);
  }

  Future<List<dynamic>> _abiCall({
    required String artifactName,
    required String contractAddress,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    final function = await _artifactFunction(artifactName, functionName);
    final response = await _ethCall(
      to: contractAddress,
      data: web3.bytesToHex(
        function.encodeCall(parameters),
        include0x: true,
      ),
    );
    return function.decodeReturnValues(response);
  }

  Future<String> _abiCallData({
    required String artifactName,
    required String functionName,
    required List<dynamic> parameters,
  }) async {
    final function = await _artifactFunction(artifactName, functionName);
    return web3.bytesToHex(function.encodeCall(parameters), include0x: true);
  }

  Future<web3.ContractFunction> _artifactFunction(
    String artifactName,
    String functionName,
  ) async {
    final artifact = jsonDecode(
      await rootBundle.loadString('src/artifacts/$artifactName.json'),
    ) as Map<String, dynamic>;
    final abi = web3.ContractAbi.fromJson(
      jsonEncode(artifact['abi']),
      artifactName,
    );
    return abi.functions.firstWhere((item) => item.name == functionName);
  }

  String _addressText(dynamic value) {
    final text = '$value';
    return text.startsWith('0x')
        ? text.toLowerCase()
        : '0x${text.toLowerCase()}';
  }

  Future<String> _ethCall({
    required String to,
    required String data,
  }) async {
    final params = [
      {'to': to, 'data': data},
      'latest',
    ];
    final result = isWalletAvailable
        ? await _readOnlyRequest<String>('eth_call', params)
        : await _publicRpcRequest<String>('eth_call', params);

    return result;
  }

  Future<T> _publicRpcRequest<T>(String method, List<dynamic> params) async {
    final configuredRpc = Get.find<AppConfigService>().get('web3PublicRpcUrl');
    final rpcUrl =
        configuredRpc.isNotEmpty ? configuredRpc : currentNetwork.rpcUrl;
    final response = await http.post(
      Uri.parse(rpcUrl),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
        'params': params,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('RPC request failed: HTTP ${response.statusCode}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['error'] != null) {
      throw Exception('RPC request failed: ${payload['error']}');
    }
    return payload['result'] as T;
  }

  String _encodeAddressUint8Call(String selector, String address, int value) {
    if (value < 0 || value > 255) {
      throw Exception('Invalid uint8 value');
    }

    final encodedAddress = address.replaceFirst('0x', '').padLeft(64, '0');
    final encodedValue = value.toRadixString(16).padLeft(64, '0');
    return '0x$selector$encodedAddress$encodedValue';
  }

  String _encodeAddressCall(String selector, String address) {
    final encodedAddress = address.replaceFirst('0x', '').padLeft(64, '0');
    return '0x$selector$encodedAddress';
  }

  String _encodeAddressAddressCall(
    String selector,
    String firstAddress,
    String secondAddress,
  ) {
    final encodedFirst = firstAddress.replaceFirst('0x', '').padLeft(64, '0');
    final encodedSecond = secondAddress.replaceFirst('0x', '').padLeft(64, '0');
    return '0x$selector$encodedFirst$encodedSecond';
  }

  String _encodeAddressUint256Call(
    String selector,
    String address,
    BigInt value,
  ) {
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

  String _wordToAddress(String word) {
    final clean = word.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
    return '0x${clean.substring(24)}';
  }

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

  @override
  void onClose() {
    _receiptPollTimer?.cancel();
    _balanceRefreshTimer?.cancel();
    super.onClose();
  }
}

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

enum EasyGamePaymentAsset { native, usdc, basePay }

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

class EasyGamePaymentPreview {
  final BigInt paymentWei;
  final BigInt gasEstimate;
  final AppNetworkConfig network;

  const EasyGamePaymentPreview({
    required this.paymentWei,
    required this.gasEstimate,
    required this.network,
  });
}

class EasyGameTransactionReceipt {
  final String transactionHash;
  final String status;
  final BigInt? blockNumber;
  final BigInt? gasUsed;
  final BigInt? effectiveGasPrice;
  final String? to;
  final String? from;

  const EasyGameTransactionReceipt({
    required this.transactionHash,
    required this.status,
    required this.blockNumber,
    required this.gasUsed,
    required this.effectiveGasPrice,
    required this.to,
    required this.from,
  });

  bool get success => status.toLowerCase() == '0x1';
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

class EasyGameAdvanceLevelStats {
  final BigInt prizePoolWei;
  final BigInt totalWeight;
  final BigInt activeCells;
  final BigInt nextOpenParentId;
  final BigInt nextCellId;

  const EasyGameAdvanceLevelStats({
    required this.prizePoolWei,
    required this.totalWeight,
    required this.activeCells,
    required this.nextOpenParentId,
    required this.nextCellId,
  });
}

class EasyGameTokenRewards {
  final BigInt referralBonusUsdc;
  final BigInt claimablePrizeUsdc;
  final BigInt pendingPrizeUsdc;

  const EasyGameTokenRewards({
    required this.referralBonusUsdc,
    required this.claimablePrizeUsdc,
    required this.pendingPrizeUsdc,
  });
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
    required this.claimablePrizeWei,
    required this.pendingPrizeWei,
    required this.joinedAt,
    required this.lastActiveAt,
  });
}
