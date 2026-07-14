import 'package:get/get.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class LandingController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  LandingController();

  final RxString previewQuery = ''.obs;

  Future<void> connectAndEnter() async {
    if (walletService.isConnected.value) {
      UiNavigationService.openLevels();
      return;
    }

    try {
      await walletService.connectBaseAccount();
      if (walletService.isConnected.value) {
        linkFirebaseWallet();
        UiNavigationService.openLevels();
      }
    } catch (e) {
      Get.snackbar(
        'common.error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void linkFirebaseWallet() {
    if (!Get.isRegistered<FirebaseBackendService>()) return;
    final backend = Get.find<FirebaseBackendService>();
    if (!backend.isReady.value) return;
    backend.ensureCurrentWalletLinkedInBackground();
  }

  void openPreview() {
    UiNavigationService.openMemberPreview(previewQuery.value);
  }
}
