import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/controllers/wallet_auth_controller.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class LandingController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final WalletAuthController authController = Get.find<WalletAuthController>();

  LandingController();

  final RxString previewQuery = ''.obs;

  Future<void> connectAndEnter() async {
    if (authController.isAuthenticated) {
      UiNavigationService.openLevels();
      return;
    }

    try {
      await authController.connectAndAuthenticate();
      if (authController.isAuthenticated) UiNavigationService.openLevels();
    } catch (e) {
      if (WalletConnectService.isUserRejection(e)) return;
      Get.snackbar(
        'common.error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void openPreview() {
    UiNavigationService.openMemberPreview(previewQuery.value);
  }
}
