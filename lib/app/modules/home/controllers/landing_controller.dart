part of '../views/start_page.dart';

class _LandingController extends GetxController {
  final WalletConnectService walletService;

  _LandingController(this.walletService);

  final previewSearchController = TextEditingController();

  @override
  void onClose() {
    previewSearchController.dispose();
    super.onClose();
  }

  Future<void> connectAndEnter() async {
    if (walletService.isConnected.value) {
      Get.to(() => const LevelsScreen());
      return;
    }

    try {
      await walletService.connectBaseAccount();
      if (walletService.isConnected.value) {
        Get.to(() => const LevelsScreen());
      }
    } catch (e) {
      Get.snackbar(
        'common.error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void openPreview() {
    UiNavigationService.openMemberPreview(previewSearchController.text);
  }
}
