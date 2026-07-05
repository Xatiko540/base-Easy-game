part of '../views/partner_bonus_screen.dart';

class _PartnerBonusController extends GetxController {
  final WalletConnectService walletService;

  _PartnerBonusController(this.walletService);

  final snapshot = _PartnerArenaSnapshot.empty().obs;
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

  Future<_PartnerArenaSnapshot> _loadSnapshot() async {
    if (!walletService.isConnected.value) {
      return _PartnerArenaSnapshot.empty();
    }
    try {
      final player = await walletService.getEasyGamePlayerSummary();
      return _PartnerArenaSnapshot(player: player);
    } catch (_) {
      return _PartnerArenaSnapshot.empty();
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
