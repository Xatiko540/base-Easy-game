import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/views/activate_express_game_screen.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/modules/home/controllers/wallet_auth_controller.dart';

class RegistrationController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final GameRoundsController _rounds = Get.find<GameRoundsController>();

  RegistrationController();

  final uplineController = TextEditingController();
  final selectedLevel = 3.obs;
  final selectedPriceUnits = BigInt.zero.obs;
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
    ]);
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

  List<int> get selectableLevels {
    final levels = _rounds.roundsByLevel.entries
        .where((entry) => entry.value.canEnter)
        .map((entry) => entry.key)
        .toSet();
    // Keep the route-selected value present while the schedule is loading so
    // DropdownButton never receives a value missing from its item list.
    levels.add(selectedLevel.value);
    final result = levels.toList()..sort((a, b) => b.compareTo(a));
    return result;
  }

  BigInt priceForLevel(int level) {
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
    if (!selectableLevels.contains(level)) return;
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
      final round = await _requireOpenRound();
      final price = priceForLevel(selectedLevel.value);
      await walletService.refreshNativeBalance();
      final gasQuote = await walletService.estimateRoundActivationGas(
        round: round.schedule,
        paysWithUsdc: paymentAsset.value == EasyGamePaymentAsset.usdc,
      );
      final nativeBalance = walletService.nativeBalanceWei.value ?? BigInt.zero;
      final requiredNative = gasQuote.requiredNativeWei(
        ticketPriceWei: round.ethPriceWei,
        paysWithUsdc: paymentAsset.value == EasyGamePaymentAsset.usdc,
      );
      final hasPaymentAsset = paymentAsset.value == EasyGamePaymentAsset.usdc
          ? (await walletService.getUsdcBalanceWei()) >= price
          : nativeBalance >= requiredNative;
      final hasEnoughBalance =
          hasPaymentAsset && nativeBalance >= requiredNative;
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
            : '${formatAssetAmount(price)} $currencySymbol / ${walletService.nativeBalance}',
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
      await Get.find<WalletAuthController>().ensureAuthenticated();
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
      if (!await _checkEntryEligibility(round)) return;
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

  Future<bool> _checkEntryEligibility(GameRoundViewState round) async {
    try {
      final eligibility = await walletService.getRoundEntryEligibility(
        seasonId: BigInt.from(round.schedule.seasonId),
        level: selectedLevel.value,
      );
      switch (eligibility.reason) {
        case RoundEntryEligibilityReason.eligible:
          return true;
        case RoundEntryEligibilityReason.alreadyPurchasedOrLower:
          _showEligibilityDialog(
            title: 'levels.missed'.tr,
            message: 'levels.missedHint'.tr,
          );
          return false;
        case RoundEntryEligibilityReason.nextLevelRequired:
          _showEligibilityDialog(
            title: 'levels.activateRequiredLevel'.trParams({
              'level': '${eligibility.requiredLevel}',
            }),
            message: 'levels.nextLevelRequired'.tr,
          );
          return false;
        case RoundEntryEligibilityReason.frozen:
          _showEligibilityDialog(
            title: 'levels.progressionFrozen'.tr,
            message: 'levels.unfreezeCurrentLevel'.tr,
          );
          return false;
        case RoundEntryEligibilityReason.unknown:
          return true;
      }
    } catch (_) {
      return true;
    }
  }

  void _showEligibilityDialog({
    required String title,
    required String message,
  }) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'common.close'.tr,
              style: const TextStyle(color: Color(0xFF6A4BFF), fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  GameRoundViewState? _roundForLevel(int level) {
    return _rounds.roundForLevel(level);
  }

  Future<GameRoundViewState> _requireOpenRound() async {
    final round = selectedRound.value;
    if (round == null || round.phase != GameRoundPhase.open) {
      throw Exception('round.actionsUnavailable'.tr);
    }
    final available =
        await walletService.isEasyGameLevelAvailable(selectedLevel.value);
    contractAvailability[selectedLevel.value] = available;
    if (!available) {
      throw Exception('payment.levelEmergencyPausedHint'.tr);
    }
    return round;
  }

  void _applyRoundPrice() {
    selectedPriceUnits.value = priceForLevel(selectedLevel.value);
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
