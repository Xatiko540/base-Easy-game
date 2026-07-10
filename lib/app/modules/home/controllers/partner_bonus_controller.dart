import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/models/partner_bonus_models.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class PartnerBonusController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  PartnerBonusController();

  final snapshot = PartnerArenaSnapshot.empty().obs;
  final isLoading = false.obs;
  Worker? _connectionWorker;
  Worker? _addressWorker;

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
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
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
    if (!walletService.isConnected.value) {
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
    final link = referralLink;
    await Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'common.copied'.tr,
      link,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void shareReferralLink() {
    UiNavigationService.openExternal(referralLink);
  }

  Future<void> claimReferralBonus() async {
    try {
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
