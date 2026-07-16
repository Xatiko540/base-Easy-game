import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/modules/home/views/activate_express_game_screen.dart';
import 'package:lottery_advance/app/repositories/round_levels_repository.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/services/base_pay_service.dart';

class RegistrationController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final GameRoundsController _rounds = Get.find<GameRoundsController>();
  final RoundLevelsRepository _levelPrices = Get.find<RoundLevelsRepository>();

  RegistrationController();

  final uplineController = TextEditingController();
  final selectedLevel = 3.obs;
  final selectedPriceUnits = BigInt.zero.obs;
  final RxMap<int, ContractLevelPrice> contractPrices =
      <int, ContractLevelPrice>{}.obs;
  final RxMap<int, bool> contractAvailability = <int, bool>{}.obs;
  final paymentAsset = EasyGamePaymentAsset.native.obs;
  final Rxn<GameRoundViewState> selectedRound = Rxn<GameRoundViewState>();
  final networkChecked = false.obs;
  final balanceChecked = false.obs;
  final balanceMessage = ''.obs;
  final List<Worker> _workers = [];

  void configure({
    required int level,
    String? inviter,
    GameRoundViewState? round,
  }) {
    selectedLevel.value = level;
    paymentAsset.value = EasyGamePaymentAsset.native;
    networkChecked.value = false;
    balanceChecked.value = false;
    balanceMessage.value = '';
    uplineController.text = inviter ?? '';
    selectedRound.value = round ?? _roundForLevel(level);
    _applyRoundPrice();
  }

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever<Map<int, GameRoundViewState>>(_rounds.roundsByLevel, (_) {
        selectedRound.value = _roundForLevel(selectedLevel.value);
        _applyRoundPrice();
      }),
      ever<int?>(walletService.chainId, (_) => _loadContractPrices()),
    ]);
    _loadContractPrices();
  }

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    uplineController.dispose();
    super.onClose();
  }

  String get uplineLabel {
    final value = uplineController.text.trim();
    return value.isEmpty ? 'registration.noUpline'.tr : value;
  }

  bool get paysWithUsdc => paymentAsset.value != EasyGamePaymentAsset.native;

  String get currencySymbol =>
      paysWithUsdc ? 'USDC' : walletService.nativeSymbol;

  String get selectedPriceLabel => formatAssetAmount(selectedPriceUnits.value);

  BigInt priceForLevel(int level) {
    final contractPrice = contractPrices[level];
    if (contractPrice != null) {
      return paysWithUsdc ? contractPrice.usdcPrice : contractPrice.ethPriceWei;
    }
    final round = _roundForLevel(level);
    return paysWithUsdc
        ? round?.usdcPrice ?? BigInt.zero
        : round?.ethPriceWei ?? BigInt.zero;
  }

  bool canEnterLevel(int level) =>
      _roundForLevel(level)?.canEnter == true &&
      contractAvailability[level] != false;

  void selectPaymentAsset(EasyGamePaymentAsset asset) {
    paymentAsset.value = asset;
    _applyRoundPrice();
    balanceChecked.value = false;
    balanceMessage.value = '';
  }

  void selectLevel(int level) {
    selectedLevel.value = level;
    selectedRound.value = _roundForLevel(level);
    _applyRoundPrice();
    networkChecked.value = false;
    balanceChecked.value = false;
    balanceMessage.value = '';
  }

  Future<void> checkNetwork() async {
    try {
      await walletService.ensureBaseNetwork();
      networkChecked.value = true;
      Get.snackbar(
        'payment.networkOk'.tr,
        '${'common.ready'.tr}: ${walletService.networkLabel}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      networkChecked.value = false;
      Get.snackbar(
        'registration.networkCheck'.tr,
        '$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> checkBalance() async {
    if (!walletService.isConnected.value) {
      Get.snackbar(
        'common.walletNotConnected'.tr,
        'registration.walletNotConnected'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await walletService.ensureBaseNetwork();
      await _requireOpenRound();
      final price = priceForLevel(selectedLevel.value);
      if (paymentAsset.value == EasyGamePaymentAsset.basePay) {
        final basePay = Get.find<BasePayService>();
        if (!basePay.isAvailable) {
          throw StateError('payment.basePayUnavailable'.tr);
        }
        balanceChecked.value = true;
        balanceMessage.value = '';
        selectedPriceUnits.value = price;
        Get.snackbar(
          'registration.balanceOk'.tr,
          'payment.basePayBalanceHint'.tr,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      final balance = paymentAsset.value == EasyGamePaymentAsset.usdc
          ? await walletService.getUsdcBalance()
          : await walletService.refreshNativeBalance();
      final hasEnoughBalance = balance >= price;
      balanceChecked.value = hasEnoughBalance;
      balanceMessage.value = hasEnoughBalance
          ? ''
          : '${'registration.balanceLow'.tr}: ${formatAssetAmount(price)} $currencySymbol';
      selectedPriceUnits.value = price;
      Get.snackbar(
        hasEnoughBalance
            ? 'registration.balanceOk'.tr
            : 'registration.balanceLow'.tr,
        hasEnoughBalance
            ? '${'common.level'.tr} ${selectedLevel.value}: ${'registration.balanceOk'.tr}'
            : '${formatAssetAmount(price)} $currencySymbol / ${formatAssetAmount(balance)} $currencySymbol',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      balanceChecked.value = false;
      balanceMessage.value = 'registration.checkFailed'.tr;
      Get.snackbar(
        'registration.checkFailed'.tr,
        '$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void approveUpline() {
    final entered = uplineController.text.trim();
    if (entered.isEmpty) {
      walletService.clearReferralInviter();
      Get.snackbar(
        'registration.uplineCleared'.tr,
        'registration.noUplineUsed'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final normalized = ReferralLinkService.normalizeAddress(entered);
    if (normalized.isEmpty) {
      Get.snackbar(
        'registration.invalidUpline'.tr,
        'registration.enterWallet'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    walletService.setReferralInviter(normalized);
    uplineController.text = normalized;
    Get.snackbar(
      'registration.uplineSaved'.tr,
      normalized,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> continueToPayment() async {
    try {
      if (!walletService.isConnected.value) {
        await walletService.connectBaseAccount();
      }
      await walletService.ensureBaseNetwork();

      final entered = uplineController.text.trim();
      if (entered.isNotEmpty) {
        final normalized = ReferralLinkService.normalizeAddress(entered);
        if (normalized.isEmpty) {
          Get.snackbar(
            'registration.invalidUpline'.tr,
            'registration.enterWallet'.tr,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        walletService.setReferralInviter(normalized);
        uplineController.text = normalized;
      }

      final round = await _requireOpenRound();
      final price = priceForLevel(selectedLevel.value);
      selectedPriceUnits.value = price;
      networkChecked.value = true;

      Get.to(
        () => ActivateExpressGameScreen(
          level: selectedLevel.value,
          inviter: uplineController.text.trim(),
          paymentAsset: paymentAsset.value,
          initialRound: round,
        ),
      );
    } catch (e) {
      Get.snackbar(
        'registration.registrationFailed'.tr,
        '$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  GameRoundViewState? _roundForLevel(int level) {
    return _rounds.roundForLevel(level);
  }

  Future<GameRoundViewState> _requireOpenRound() async {
    final round = selectedRound.value;
    if (round == null || !round.canEnter) {
      throw Exception('round.actionsUnavailable'.tr);
    }
    final available =
        await walletService.isEasyGameLevelAvailable(selectedLevel.value);
    contractAvailability[selectedLevel.value] = available;
    if (!available) {
      throw Exception('payment.levelEmergencyPausedHint'.tr);
    }
    await _requireProgressionEligibility(round);
    final contractPrice = await _ensureContractPrice(selectedLevel.value);
    if (contractPrice.ethPriceWei != round.ethPriceWei ||
        contractPrice.usdcPrice != round.usdcPrice) {
      throw StateError('payment.contractPriceMismatch'.tr);
    }
    return round;
  }

  Future<void> _requireProgressionEligibility(
    GameRoundViewState round,
  ) async {
    RoundEntryEligibility eligibility;
    try {
      eligibility = await walletService.getRoundEntryEligibility(
        seasonId: BigInt.from(round.schedule.seasonId),
        level: selectedLevel.value,
      );
    } catch (_) {
      // Older test deployments do not expose progression introspection. The
      // transaction remains protected by RoundManager after the next deploy.
      return;
    }
    switch (eligibility.reason) {
      case RoundEntryEligibilityReason.eligible:
        return;
      case RoundEntryEligibilityReason.alreadyPurchasedOrLower:
        throw Exception('levels.missedHint'.tr);
      case RoundEntryEligibilityReason.nextLevelRequired:
        throw Exception('levels.activateRequiredLevel'.trParams({
          'level': '${eligibility.requiredLevel}',
        }));
      case RoundEntryEligibilityReason.frozen:
        throw Exception('levels.unfreezeCurrentLevel'.tr);
      case RoundEntryEligibilityReason.unknown:
        throw Exception('levels.entryUnavailable'.tr);
    }
  }

  Future<ContractLevelPrice> _ensureContractPrice(int level) async {
    final cached = contractPrices[level];
    if (cached != null) return cached;

    final loaded = await _levelPrices.loadContractPrice(level);
    if (!isClosed) {
      contractPrices[level] = loaded;
      _applyRoundPrice();
    }
    return loaded;
  }

  void _applyRoundPrice() {
    selectedPriceUnits.value = priceForLevel(selectedLevel.value);
  }

  Future<void> _loadContractPrices() async {
    final requests = <Future<void>>[];
    for (var level = 1; level <= easyGameLevelCount; level++) {
      requests.add(Future.wait<dynamic>([
        _levelPrices.loadContractPrice(level),
        walletService.isEasyGameLevelAvailable(level),
      ]).then((values) {
        if (!isClosed) {
          contractPrices[level] = values[0] as ContractLevelPrice;
          contractAvailability[level] = values[1] as bool;
        }
      }).catchError((_) {}));
    }
    await Future.wait(requests);
    if (!isClosed) _applyRoundPrice();
  }

  String formatAssetAmount(BigInt amount) {
    if (paysWithUsdc) {
      final whole = amount ~/ BigInt.from(1000000);
      final fraction =
          (amount % BigInt.from(1000000)).toString().padLeft(6, '0');
      final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
      return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
    }
    return formatWeiToEth(amount);
  }
}
