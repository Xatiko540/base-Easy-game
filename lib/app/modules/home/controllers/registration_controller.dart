part of '../views/registrationlevel.dart';

class _RegistrationController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  _RegistrationController();

  final uplineController = TextEditingController();
  final selectedLevel = 3.obs;
  final selectedAmount = 0.1.obs;
  final paymentAsset = EasyGamePaymentAsset.native.obs;
  final networkChecked = false.obs;
  final balanceChecked = false.obs;
  final balanceMessage = ''.obs;

  void configure({
    required int level,
    required double amount,
    String? inviter,
  }) {
    selectedLevel.value = level;
    selectedAmount.value = amount;
    paymentAsset.value = EasyGamePaymentAsset.native;
    networkChecked.value = false;
    balanceChecked.value = false;
    balanceMessage.value = '';
    uplineController.text = inviter ?? '';
  }

  @override
  void onClose() {
    uplineController.dispose();
    super.onClose();
  }

  String get uplineLabel {
    final value = uplineController.text.trim();
    return value.isEmpty ? 'registration.noUpline'.tr : value;
  }

  String get currencySymbol => paymentAsset.value == EasyGamePaymentAsset.usdc
      ? 'USDC'
      : walletService.nativeSymbol;

  void selectPaymentAsset(EasyGamePaymentAsset asset) {
    paymentAsset.value = asset;
    selectedAmount.value = levelPrice(selectedLevel.value);
    balanceChecked.value = false;
    balanceMessage.value = '';
  }

  void selectLevel(int level) {
    selectedLevel.value = level;
    selectedAmount.value = levelPrice(level);
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
      final price = paymentAsset.value == EasyGamePaymentAsset.usdc
          ? await walletService.getEasyGameLevelPriceUsdc(selectedLevel.value)
          : await walletService.getEasyGameLevelPriceWei(selectedLevel.value);
      final balance = paymentAsset.value == EasyGamePaymentAsset.usdc
          ? await walletService.getUsdcBalance()
          : await walletService.refreshNativeBalance();
      final hasEnoughBalance = balance >= price;
      balanceChecked.value = hasEnoughBalance;
      balanceMessage.value = hasEnoughBalance
          ? ''
          : '${'registration.balanceLow'.tr}: ${formatAssetAmount(price)} $currencySymbol';
      selectedAmount.value = assetToDouble(price);
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

      final price = paymentAsset.value == EasyGamePaymentAsset.usdc
          ? await walletService.getEasyGameLevelPriceUsdc(selectedLevel.value)
          : await walletService.getEasyGameLevelPriceWei(selectedLevel.value);
      selectedAmount.value = assetToDouble(price);
      networkChecked.value = true;

      Get.to(
        () => ActivateExpressGameScreen(
          level: selectedLevel.value,
          totalAmount: selectedAmount.value,
          inviter: uplineController.text.trim(),
          paymentAsset: paymentAsset.value,
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

  double assetToDouble(BigInt amount) {
    if (paymentAsset.value == EasyGamePaymentAsset.usdc) {
      return amount.toDouble() / 1000000;
    }
    return weiToEthDouble(amount);
  }

  String formatAssetAmount(BigInt amount) {
    if (paymentAsset.value == EasyGamePaymentAsset.usdc) {
      final whole = amount ~/ BigInt.from(1000000);
      final fraction =
          (amount % BigInt.from(1000000)).toString().padLeft(6, '0');
      final trimmed = fraction.replaceFirst(RegExp(r'0+$'), '');
      return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
    }
    return formatWeiToEth(amount);
  }
}
