import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/wallet_auth_models.dart';
import 'package:lottery_advance/app/modules/home/models/partner_bonus_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/wallet_auth_controller.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class PartnerBonusController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final WalletAuthController authController = Get.find<WalletAuthController>();

  PartnerBonusController();

  final snapshot = PartnerArenaSnapshot.empty().obs;
  final isLoading = false.obs;
  Worker? _connectionWorker;
  Worker? _addressWorker;
  Worker? _authWorker;

  @override
  void onInit() {
    super.onInit();
    refreshSnapshot();
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => refreshSnapshot(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => refreshSnapshot(),
    );
    _authWorker = ever<WalletAuthPhase>(
      authController.phase,
      (_) => refreshSnapshot(),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    _authWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshSnapshot() async {
    isLoading.value = true;
    try {
      snapshot.value = await _loadSnapshot();
    } finally {
      isLoading.value = false;
    }
  }

  Future<PartnerArenaSnapshot> _loadSnapshot() async {
    if (!authController.isAuthenticated) {
      return PartnerArenaSnapshot.empty();
    }
    try {
      final player = await walletService.getEasyGamePlayerSummary();
      return PartnerArenaSnapshot(player: player);
    } catch (_) {
      return PartnerArenaSnapshot.empty();
    }
  }

  String get referralLink => ReferralLinkService.buildReferralLink(
        walletService.currentAddress.value,
      );

  Future<void> copyReferralLink() async {
    await authController.ensureAuthenticated();
    final link = referralLink;
    await Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'common.copied'.tr,
      link,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> shareReferralLink() async {
    await authController.ensureAuthenticated();
    UiNavigationService.openExternal(referralLink);
  }

  Future<void> claimReferralBonus() async {
    try {
      await authController.ensureAuthenticated();
      final txHash = await walletService.claimEasyGameReferralBonus();
      Get.snackbar(
        'partner.claimSent'.tr,
        txHash,
        snackPosition: SnackPosition.BOTTOM,
      );
      await refreshSnapshot();
    } catch (e) {
      Get.snackbar(
        'payment.unavailable'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
