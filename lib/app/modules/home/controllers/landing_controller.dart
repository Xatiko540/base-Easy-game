import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class LandingController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  LandingController();

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
        await linkFirebaseWallet();
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

  Future<void> linkFirebaseWallet() async {
    if (!Get.isRegistered<FirebaseBackendService>()) return;
    final backend = Get.find<FirebaseBackendService>();
    if (!backend.isReady.value) return;
    try {
      await backend.ensureCurrentWalletLinked();
    } catch (error) {
      debugPrint('Firebase wallet link skipped: $error');
    }
  }

  void openPreview() {
    UiNavigationService.openMemberPreview(previewSearchController.text);
  }
}
