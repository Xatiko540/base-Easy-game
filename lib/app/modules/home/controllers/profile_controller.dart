part of '../views/profilescreen.dart';

class _ProfileController extends GetxController {
  final WalletConnectService walletService;

  _ProfileController(this.walletService);

  final dashboard = _ProfileDashboardSnapshot.empty().obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  Worker? _connectionWorker;
  Worker? _addressWorker;

  String get referralLink =>
      ReferralLinkService.buildReferralLink(walletService.currentAddress.value);

  String get profileId {
    final address = walletService.currentAddress.value;
    if (address.length < 8) {
      return '325234';
    }
    final tail = address.substring(address.length - 6);
    return (int.tryParse(tail.replaceAll(RegExp(r'[^0-9]'), '')) ?? 325234)
        .toString()
        .padLeft(6, '0')
        .substring(0, 6);
  }

  @override
  void onInit() {
    super.onInit();
    refreshDashboard();
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => refreshDashboard(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => refreshDashboard(),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      dashboard.value = await _loadDashboard();
    } catch (error) {
      errorMessage.value = error.toString();
      dashboard.value = _ProfileDashboardSnapshot.empty();
    } finally {
      isLoading.value = false;
    }
  }

  void copyReferralLink() {
    Clipboard.setData(ClipboardData(text: referralLink));
    Get.snackbar(
      'common.copy'.tr,
      referralLink,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> shareReferralLink() async {
    final url = Uri.parse(referralLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }
    Get.snackbar(
      'common.linkUnavailable'.tr,
      referralLink,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void copyContractAddress() {
    final address = dashboard.value.contractAddress;
    Clipboard.setData(ClipboardData(text: address));
    Get.snackbar(
      'common.copied'.tr,
      _shortAddress(address),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<_ProfileDashboardSnapshot> _loadDashboard() async {
    if (!walletService.isConnected.value) {
      return _ProfileDashboardSnapshot.empty();
    }

    var contractAddress = '0x0000000000000000000000000000000000000000';
    try {
      contractAddress = await walletService.resolveEasyGameAddress();
    } catch (_) {
      contractAddress = '0x0000000000000000000000000000000000000000';
    }

    EasyGamePlayerSummary? player;
    try {
      player = await walletService.getEasyGamePlayerSummary();
    } catch (_) {
      player = null;
    }

    final levels = <_ProfileLevelState>[];
    var activeCount = 0;
    var frozenCount = 0;
    var totalEarnedWei = BigInt.zero;
    var totalPrizePoolWei = BigInt.zero;
    var totalActiveCells = BigInt.zero;
    var totalWeight = BigInt.zero;

    for (var level = easyGameLevelCount; level >= 1; level--) {
      EasyGameLevelState state;
      EasyGameAdvanceLevelStats? stats;
      BigInt priceWei;
      var available = false;

      try {
        state = await walletService.getEasyGameLevel(level: level);
      } catch (_) {
        state = EasyGameLevelState(
          active: false,
          frozen: false,
          cycles: BigInt.zero,
          positionId: BigInt.zero,
          earnedWei: BigInt.zero,
        );
      }

      try {
        stats = await walletService.getEasyGameAdvanceLevelStats(level);
        totalPrizePoolWei += stats.prizePoolWei;
        totalActiveCells += stats.activeCells;
        totalWeight += stats.totalWeight;
      } catch (_) {
        stats = null;
      }

      try {
        priceWei = await walletService.getEasyGameLevelPriceWei(level);
      } catch (_) {
        priceWei = BigInt.zero;
      }

      try {
        available = await walletService.isEasyGameLevelAvailable(level);
      } catch (_) {
        available = level >= 3;
      }

      if (state.active) {
        activeCount++;
      }
      if (state.frozen) {
        frozenCount++;
      }
      totalEarnedWei += state.earnedWei;

      levels.add(
        _ProfileLevelState(
          level: level,
          state: state,
          stats: stats,
          priceWei: priceWei,
          available: available,
        ),
      );
    }

    return _ProfileDashboardSnapshot(
      contractAddress: contractAddress,
      player: player,
      levels: levels,
      activeCount: activeCount,
      frozenCount: frozenCount,
      totalEarnedWei: totalEarnedWei,
      totalPrizePoolWei: totalPrizePoolWei,
      totalActiveCells: totalActiveCells,
      totalWeight: totalWeight,
    );
  }
}
