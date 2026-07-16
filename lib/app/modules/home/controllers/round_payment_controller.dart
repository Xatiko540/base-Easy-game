import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/repositories/round_levels_repository.dart';
import 'package:lottery_advance/app/services/base_pay_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

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
  final BasePayService basePayService = Get.find<BasePayService>();
  final GameRoundsController _rounds = Get.find<GameRoundsController>();
  final RoundLevelsRepository _levelPrices = Get.find<RoundLevelsRepository>();

  final Rxn<BigInt> availableBalanceUnits = Rxn<BigInt>();
  final Rxn<ContractLevelPrice> contractPrice = Rxn<ContractLevelPrice>();
  final RxnBool contractLevelAvailable = RxnBool();
  final isBalanceLoading = false.obs;
  final isPreflightLoading = false.obs;
  final balanceError = ''.obs;
  final preflightError = ''.obs;

  final List<Worker> _workers = [];
  int _balanceRequestId = 0;

  bool get paysWithUsdc => paymentAsset != EasyGamePaymentAsset.native;
  bool get usesBasePay => paymentAsset == EasyGamePaymentAsset.basePay;
  String get currency => paysWithUsdc ? 'USDC' : walletService.nativeSymbol;
  BigInt get amountUnits {
    final onchain = contractPrice.value;
    if (onchain != null) {
      return paysWithUsdc ? onchain.usdcPrice : onchain.ethPriceWei;
    }
    return paysWithUsdc ? round.value.usdcPrice : round.value.ethPriceWei;
  }

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

  bool? get hasEnoughBalance {
    final balance = availableBalanceUnits.value;
    if (balance == null || usesBasePay) return null;
    return balance >= amountUnits;
  }

  bool get isProcessing =>
      usesBasePay ? basePayService.isProcessing : walletService.isPaying.value;
  bool get canSubmit =>
      !isProcessing &&
      !isPreflightLoading.value &&
      contractPrice.value != null &&
      contractLevelAvailable.value == true &&
      preflightError.value.isEmpty &&
      (usesBasePay || hasEnoughBalance != false);

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
    ]);
    _refreshRound();
    _refreshWalletState();
  }

  Future<void> _refreshWalletState() async {
    await refreshBalance();
    await refreshPaymentReadiness();
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
      final balance = paysWithUsdc
          ? await walletService.getUsdcBalance()
          : await walletService.refreshNativeBalance();
      if (requestId == _balanceRequestId) {
        availableBalanceUnits.value = balance;
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
    if (!current.canEnter) {
      throw StateError('round.actionsUnavailable'.tr);
    }
    if (!walletService.isConnected.value) {
      await walletService.connectBaseAccount();
    }
    await refreshBalance();
    await refreshPaymentReadiness(throwOnFailure: true);

    final String txHash;
    if (usesBasePay) {
      txHash = await basePayService.payRound(
        round: current.schedule,
        inviter: inviter,
      );
    } else if (paymentAsset == EasyGamePaymentAsset.usdc) {
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
      if (walletService.isConnected.value) {
        await walletService.ensureBaseNetwork();
      }
      final available = await walletService.isEasyGameLevelAvailable(level);
      contractLevelAvailable.value = available;
      if (!available) {
        throw StateError('payment.levelEmergencyPausedHint'.tr);
      }

      final onchainPrice = await _levelPrices.loadContractPrice(level);
      contractPrice.value = onchainPrice;
      if (onchainPrice.ethPriceWei != round.value.ethPriceWei ||
          onchainPrice.usdcPrice != round.value.usdcPrice) {
        throw StateError('payment.contractPriceMismatch'.tr);
      }

      if (!usesBasePay && walletService.isConnected.value) {
        final balance = availableBalanceUnits.value;
        if (balance == null || balance < amountUnits) {
          throw StateError('payment.insufficientBalance'.tr);
        }
        if (paymentAsset == EasyGamePaymentAsset.usdc) {
          final nativeBalance = await walletService.refreshNativeBalance();
          if (nativeBalance <= BigInt.zero) {
            throw StateError('payment.usdcGasRequired'.tr);
          }
        } else if (balance <= amountUnits) {
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
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
