part of '../views/utility_screens.dart';

class _StatisticsController extends GetxController {
  final WalletConnectService walletService;

  _StatisticsController(this.walletService);

  final snapshot = Rxn<_StatisticsSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;

  @override
  void onInit() {
    super.onInit();
    refreshStats();
    _connectionWorker = ever<bool>(
      walletService.isConnected,
      (_) => refreshStats(),
    );
    _addressWorker = ever<String>(
      walletService.currentAddress,
      (_) => refreshStats(),
    );
  }

  @override
  void onClose() {
    _connectionWorker?.dispose();
    _addressWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshStats() async {
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

  Future<_StatisticsSnapshot> _load() async {
    final contractAddress = await walletService.resolveEasyGameAddress();
    var activeLevels = 0;
    var frozenLevels = 0;
    var matrixNodes = BigInt.zero;
    var totalLevelCostWei = BigInt.zero;
    var totalPrizePoolWei = BigInt.zero;
    var totalWeight = BigInt.zero;
    var playerRewardsWei = BigInt.zero;
    final levelRows = <_LevelArenaStat>[];

    for (var level = 1; level <= easyGameLevelCount; level++) {
      BigInt levelPriceWei;
      EasyGameAdvanceLevelStats? advanceStats;

      try {
        levelPriceWei = await walletService.getEasyGameLevelPriceWei(level);
        totalLevelCostWei += levelPriceWei;
      } catch (_) {
        levelPriceWei = BigInt.zero;
      }

      try {
        advanceStats = await walletService.getEasyGameAdvanceLevelStats(level);
        matrixNodes += advanceStats.activeCells;
        totalPrizePoolWei += advanceStats.prizePoolWei;
        totalWeight += advanceStats.totalWeight;
      } catch (_) {
        advanceStats = null;
      }

      if (walletService.isConnected.value) {
        try {
          final state = await walletService.getEasyGameLevel(level: level);
          if (state.active) {
            activeLevels++;
          }
          if (state.frozen) {
            frozenLevels++;
          }
          playerRewardsWei += state.earnedWei;
        } catch (_) {
          // Individual level read failures should not hide the whole screen.
        }
      }

      levelRows.add(
        _LevelArenaStat(
          level: level,
          priceWei: levelPriceWei,
          activeCells: advanceStats?.activeCells ?? BigInt.zero,
          prizePoolWei: advanceStats?.prizePoolWei ?? BigInt.zero,
          totalWeight: advanceStats?.totalWeight ?? BigInt.zero,
        ),
      );
    }

    return _StatisticsSnapshot(
      contractAddress: contractAddress,
      activeLevels: activeLevels,
      frozenLevels: frozenLevels,
      matrixNodes: matrixNodes,
      totalLevelCostWei: totalLevelCostWei,
      totalPrizePoolWei: totalPrizePoolWei,
      totalWeight: totalWeight,
      playerRewardsWei: playerRewardsWei,
      levelRows: levelRows,
    );
  }
}
