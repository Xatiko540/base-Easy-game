part of '../views/utility_screens.dart';

class _MatrixArenaController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  _MatrixArenaController();

  final selectedLevel = 5.obs;
  final snapshot = _MatrixArenaSnapshot.empty(5).obs;
  final isLoading = false.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;

  @override
  void onInit() {
    super.onInit();
    refreshArena();
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => refreshArena(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => refreshArena(),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    super.onClose();
  }

  Future<void> selectLevel(int level) async {
    if (selectedLevel.value == level) {
      return;
    }
    selectedLevel.value = level;
    await refreshArena();
  }

  Future<void> refreshArena() async {
    isLoading.value = true;
    try {
      snapshot.value = await _load(selectedLevel.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<_MatrixArenaSnapshot> _load(int level) async {
    BigInt priceWei;
    EasyGameAdvanceLevelStats? stats;
    EasyGameLevelState? playerLevel;
    EasyGamePlayerSummary? player;
    BigInt playerWeight = BigInt.zero;
    BigInt chanceBps = BigInt.zero;

    try {
      priceWei = await walletService.getEasyGameLevelPriceWei(level);
    } catch (_) {
      priceWei = BigInt.zero;
    }

    try {
      stats = await walletService.getEasyGameAdvanceLevelStats(level);
    } catch (_) {
      stats = null;
    }

    if (walletService.isConnected.value) {
      try {
        playerLevel = await walletService.getEasyGameLevel(level: level);
      } catch (_) {
        playerLevel = null;
      }
      try {
        player = await walletService.getEasyGamePlayerSummary();
      } catch (_) {
        player = null;
      }
      try {
        playerWeight =
            await walletService.getEasyGamePlayerWeight(level: level);
      } catch (_) {
        playerWeight = BigInt.zero;
      }
      try {
        chanceBps = await walletService.getEasyGamePlayerChanceBps(
          level: level,
        );
      } catch (_) {
        chanceBps = BigInt.zero;
      }
    }

    return _MatrixArenaSnapshot(
      level: level,
      priceWei: priceWei,
      activeCells: stats?.activeCells ?? BigInt.zero,
      totalWeight: stats?.totalWeight ?? BigInt.zero,
      prizePoolWei: stats?.prizePoolWei ?? BigInt.zero,
      nextCellId: stats?.nextCellId ?? BigInt.zero,
      nextOpenParentId: stats?.nextOpenParentId ?? BigInt.zero,
      playerCellId: playerLevel?.positionId ?? BigInt.zero,
      playerActive: playerLevel?.active ?? false,
      playerFrozen: playerLevel?.frozen ?? false,
      recycleCount: playerLevel?.cycles ?? BigInt.zero,
      playerWeight: playerWeight,
      chanceBps: chanceBps,
      boxTokens: player?.boxTokens ?? BigInt.zero,
    );
  }
}
