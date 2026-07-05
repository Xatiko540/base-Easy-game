part of '../views/levels.dart';

class _LevelDetailController extends GetxController {
  final WalletConnectService walletService;
  final int level;

  _LevelDetailController({
    required this.walletService,
    required this.level,
  });

  final snapshot = Rxn<_LevelDetailSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;

  @override
  void onInit() {
    super.onInit();
    refreshDetail();
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => refreshDetail(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => refreshDetail(),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshDetail() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      snapshot.value = await _load();
    } catch (error) {
      errorMessage.value = error.toString();
      snapshot.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<_LevelDetailSnapshot> _load() async {
    final state = await walletService.getEasyGameLevel(level: level);
    final stats = await walletService.getEasyGameMatrixStats(level);
    final advanceStats =
        await walletService.getEasyGameAdvanceLevelStats(level);
    final priceWei = await walletService.getEasyGameLevelPriceWei(level);
    EasyGamePlayerSummary? player;
    var playerWeight = BigInt.zero;
    var playerChanceBps = BigInt.zero;
    if (walletService.isConnected.value) {
      try {
        player = await walletService.getEasyGamePlayerSummary();
        playerWeight =
            await walletService.getEasyGamePlayerWeight(level: level);
        playerChanceBps =
            await walletService.getEasyGamePlayerChanceBps(level: level);
      } catch (_) {
        player = null;
      }
    }
    return _LevelDetailSnapshot(
      state: state,
      stats: stats,
      advanceStats: advanceStats,
      priceWei: priceWei,
      player: player,
      playerWeight: playerWeight,
      playerChanceBps: playerChanceBps,
    );
  }

  double fillPercent(_LevelDetailSnapshot data) {
    if (data.stats.size == BigInt.zero ||
        data.state.positionId == BigInt.zero) {
      return 0;
    }
    return ((data.state.positionId.toDouble() / data.stats.size.toDouble()) *
            100)
        .clamp(0, 100)
        .toDouble();
  }

  String stateLabel(_LevelDetailSnapshot data) {
    if (data.state.frozen) {
      return 'common.frozen'.tr;
    }
    if (data.state.active) {
      return 'common.active'.tr;
    }
    return 'levels.availableActivation'.tr;
  }
}
