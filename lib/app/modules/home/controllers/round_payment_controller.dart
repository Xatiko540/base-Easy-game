import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/round_payment_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/modules/home/controllers/wallet_auth_controller.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';

class RoundPaymentController extends GetxController {
  RoundPaymentController({
    required this.level,
    required this.inviter,
    required this.paymentAsset,
    required GameRoundViewState initialRound,
  }) : round = Rx<GameRoundViewState>(initialRound);

  final int level;
  final String inviter;
  final EasyGamePaymentAsset paymentAsset;
  final Rx<GameRoundViewState> round;

  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final GameRoundsController _rounds = Get.find<GameRoundsController>();

  final Rxn<BigInt> availableBalanceUnits = Rxn<BigInt>();
  final Rxn<RoundPaymentGasQuote> gasQuote = Rxn<RoundPaymentGasQuote>();
  final RxnBool contractLevelAvailable = RxnBool();
  final isBalanceLoading = false.obs;
  final isPreflightLoading = false.obs;
  final balanceError = ''.obs;
  final preflightError = ''.obs;

  final List<Worker> _workers = [];
  int _balanceRequestId = 0;
  bool _walletRefreshInFlight = false;
  bool _walletRefreshQueued = false;

  bool get paysWithUsdc => paymentAsset == EasyGamePaymentAsset.usdc;
  String get currency => paysWithUsdc ? 'USDC' : walletService.nativeSymbol;
  BigInt get amountUnits =>
      paysWithUsdc ? round.value.usdcPrice : round.value.ethPriceWei;

  String get amountLabel => paysWithUsdc
      ? formatUsdc(amountUnits, decimals: 6)
      : formatWeiToEth(amountUnits, decimals: 8);
  String get availableBalanceLabel {
    final balance = availableBalanceUnits.value;
    if (balance == null) return '--';
    return paysWithUsdc
        ? formatUsdc(balance, decimals: 6)
        : formatWeiToEth(balance, decimals: 8);
  }

  BigInt get estimatedGasFeeWei => gasQuote.value?.feeReserveWei ?? BigInt.zero;

  String get estimatedGasFeeLabel =>
      formatWeiToEth(estimatedGasFeeWei, decimals: 8);

  BigInt get totalNativeRequiredWei {
    final quote = gasQuote.value;
    if (quote == null) return paysWithUsdc ? BigInt.zero : amountUnits;
    return quote.requiredNativeWei(
      ticketPriceWei: round.value.ethPriceWei,
      paysWithUsdc: paysWithUsdc,
    );
  }

  String get totalRequiredLabel => paysWithUsdc
      ? '$amountLabel USDC + $estimatedGasFeeLabel ${walletService.nativeSymbol}'
      : '${formatWeiToEth(totalNativeRequiredWei, decimals: 8)} ${walletService.nativeSymbol}';

  bool? get hasEnoughBalance {
    final balance = availableBalanceUnits.value;
    if (balance == null) return null;
    if (paysWithUsdc) return balance >= amountUnits;
    if (gasQuote.value == null) return null;
    return balance >= totalNativeRequiredWei;
  }

  bool? get hasEnoughNativeGas {
    final nativeWei = walletService.nativeBalanceWei.value;
    if (nativeWei == null || gasQuote.value == null) return null;
    return nativeWei >= totalNativeRequiredWei;
  }

  bool get needsEthFunding {
    if (!walletService.isConnected.value) return false;
    final nativeWei = walletService.nativeBalanceWei.value;
    if (nativeWei == null) return false;
    if (gasQuote.value == null) return false;
    return nativeWei < totalNativeRequiredWei;
  }

  bool get usesTestnetFaucet => !walletService.isFiatOnRampAvailable;

  String get fundingButtonTranslationKey =>
      usesTestnetFaucet ? 'payment.getTestEth' : 'payment.buyEth';

  String get fundingHintTranslationKey =>
      usesTestnetFaucet ? 'payment.getTestEthHint' : 'payment.buyEthHint';

  Future<void> openEthFunding() async {
    try {
      if (usesTestnetFaucet) {
        await UiNavigationService.openExternal(
          'https://www.ethereum-ecosystem.com/faucets/base-sepolia',
        );
        return;
      }
      await walletService.openEthOnRamp();
    } catch (error) {
      Get.snackbar(
        'payment.onRampUnavailable'.tr,
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool get isProcessing => walletService.isPaying.value;
  bool get canSubmit =>
      !isProcessing &&
      !isPreflightLoading.value &&
      round.value.canEnter &&
      _isSelectedRoundCurrent &&
      contractLevelAvailable.value == true &&
      preflightError.value.isEmpty &&
      gasQuote.value != null &&
      hasEnoughBalance == true &&
      hasEnoughNativeGas == true;

  bool get _isSelectedRoundCurrent {
    final latest = _rounds.roundForLevel(level);
    return latest != null &&
        latest.schedule.roundId == round.value.schedule.roundId;
  }

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever<Map<int, GameRoundViewState>>(
        _rounds.roundsByLevel,
        (_) {
          _refreshRound();
        },
      ),
      ever<String>(walletService.currentAddress, (_) => _refreshWalletState()),
      ever<bool>(walletService.isConnected, (_) => _refreshWalletState()),
      ever<int?>(walletService.chainId, (_) => _refreshWalletState()),
      ever<BigInt?>(walletService.nativeBalanceWei, (balance) {
        if (!paysWithUsdc) availableBalanceUnits.value = balance;
      }),
      ever<bool>(walletService.isAppKitModalOpen, (isOpen) {
        if (!isOpen && walletService.isConnected.value) {
          _refreshWalletState();
        }
      }),
    ]);
    _refreshRound();
    _refreshWalletState();
  }

  Future<void> _refreshWalletState() async {
    if (_walletRefreshInFlight) {
      _walletRefreshQueued = true;
      return;
    }
    _walletRefreshInFlight = true;
    try {
      do {
        _walletRefreshQueued = false;
        gasQuote.value = null;
        await refreshBalance();
        await refreshPaymentReadiness();
      } while (_walletRefreshQueued && !isClosed);
    } finally {
      _walletRefreshInFlight = false;
    }
  }

  void _refreshRound() {
    final latest = _rounds.roundForLevel(level);
    if (latest != null &&
        latest.schedule.roundId == round.value.schedule.roundId) {
      round.value = latest;
    }
  }

  Future<void> refreshBalance() async {
    final requestId = ++_balanceRequestId;
    if (!walletService.isConnected.value ||
        walletService.currentAddress.value.isEmpty) {
      availableBalanceUnits.value = null;
      balanceError.value = '';
      return;
    }

    isBalanceLoading.value = true;
    balanceError.value = '';
    try {
      await walletService.ensureBaseNetwork();
      if (paysWithUsdc) {
        final usdcWei = await walletService.getUsdcBalanceWei();
        if (requestId == _balanceRequestId) {
          availableBalanceUnits.value = usdcWei;
        }
      } else {
        await walletService.refreshNativeBalance();
        if (requestId == _balanceRequestId) {
          availableBalanceUnits.value = walletService.nativeBalanceWei.value;
        }
      }
    } catch (error) {
      if (requestId == _balanceRequestId) {
        availableBalanceUnits.value = null;
        balanceError.value = error.toString();
      }
    } finally {
      if (requestId == _balanceRequestId) {
        isBalanceLoading.value = false;
      }
    }
  }

  Future<void> submitPayment() async {
    _refreshRound();
    final current = round.value;
    if (current.phase != GameRoundPhase.open) {
      throw StateError('round.actionsUnavailable'.tr);
    }
    await Get.find<WalletAuthController>().ensureAuthenticated();
    await refreshBalance();
    await refreshPaymentReadiness(throwOnFailure: true);

    final String txHash;
    if (paymentAsset == EasyGamePaymentAsset.usdc) {
      txHash = await walletService.activateEasyGameRoundWithUSDC(
        round: current.schedule,
        inviter: inviter,
      );
    } else {
      txHash = await walletService.activateEasyGameRound(
        round: current.schedule,
        inviter: inviter,
      );
    }

    Get.snackbar(
      'payment.confirmed'.tr,
      '${'payment.transaction'.tr}: $txHash',
      snackPosition: SnackPosition.BOTTOM,
    );
    await refreshBalance();
    Get.offAllNamed('/levels');
  }

  Future<void> refreshPaymentReadiness({bool throwOnFailure = false}) async {
    isPreflightLoading.value = true;
    preflightError.value = '';
    try {
      final latest = _rounds.roundForLevel(level);
      if (latest == null ||
          latest.schedule.roundId != round.value.schedule.roundId) {
        throw StateError('round.actionsUnavailable'.tr);
      }
      round.value = latest;
      if (latest.phase != GameRoundPhase.open) {
        throw StateError('round.actionsUnavailable'.tr);
      }
      if (walletService.isConnected.value) {
        await walletService.ensureBaseNetwork();
      }
      contractLevelAvailable.value = true;

      if (round.value.chainState != null && !round.value.isConfigurationTrusted) {
        throw StateError('round.configMismatch'.tr);
      }

      if (walletService.isConnected.value) {
        gasQuote.value = await walletService.estimateRoundActivationGas(
          round: latest.schedule,
          paysWithUsdc: paysWithUsdc,
        );
      }

      if (walletService.isConnected.value) {
        final balance = availableBalanceUnits.value;
        if (balance == null || balance < amountUnits) {
          throw StateError('payment.insufficientBalance'.tr);
        }
        if (hasEnoughNativeGas != true) {
          if (paymentAsset == EasyGamePaymentAsset.usdc) {
            throw StateError('payment.usdcGasRequired'.tr);
          }
          throw StateError('payment.nativeGasRequired'.tr);
        }
      }
    } catch (error) {
      preflightError.value = error.toString();
      if (throwOnFailure) rethrow;
    } finally {
      isPreflightLoading.value = false;
    }
  }

  @override
  void onClose() {
    _balanceRequestId++;
    _walletRefreshQueued = false;
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
