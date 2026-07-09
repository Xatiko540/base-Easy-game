part of '../views/utility_screens.dart';

class _StatisticsController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  late final FirebaseDataService _firebaseData;

  _StatisticsController();

  final snapshot = Rxn<_StatisticsSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;
  StreamSubscription<List<FirebaseLevelData>>? _levelsSub;

  @override
  void onInit() {
    super.onInit();
    _firebaseData = Get.find<FirebaseDataService>();
    _firebaseData.init();

    _levelsSub = _firebaseData.watchAllLevels().listen((firebaseLevels) {
      if (firebaseLevels.isNotEmpty && !isLoading.value) {
        _buildFromFirebase(firebaseLevels);
      }
    });

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
    _levelsSub?.cancel();
    super.onClose();
  }

  Future<void> refreshStats() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final fbLevels = await _firebaseData.fetchLevelsFromContract();
      if (fbLevels.isNotEmpty) {
        _buildFromFirebase(fbLevels);
        return;
      }
      snapshot.value = await _loadFromContract();
    } catch (error) {
      errorMessage.value = error.toString();
      snapshot.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void _buildFromFirebase(List<FirebaseLevelData> fbLevels) {
    final contractAddress = walletService.easyGameAddress.value;
    var activeLevels = 0;
    var frozenLevels = 0;
    var matrixNodes = BigInt.zero;
    var totalLevelCostWei = BigInt.zero;
    var totalPrizePoolWei = BigInt.zero;
    var totalWeight = BigInt.zero;
    var playerRewardsWei = BigInt.zero;
    final levelRows = <_LevelArenaStat>[];

    for (final fb in fbLevels) {
      totalLevelCostWei += fb.ethPriceWei;
      matrixNodes += fb.activeCells;
      totalPrizePoolWei += fb.prizePoolWei;
      totalWeight += fb.totalWeight;

      levelRows.add(_LevelArenaStat(
        level: fb.level,
        priceWei: fb.ethPriceWei,
        activeCells: fb.activeCells,
        prizePoolWei: fb.prizePoolWei,
        totalWeight: fb.totalWeight,
      ));

      if (walletService.isConnected.value) {
        walletService.getEasyGameLevel(level: fb.level).then((state) {
          if (state.active) activeLevels++;
          if (state.frozen) frozenLevels++;
          playerRewardsWei += state.earnedWei;
        });
      }
    }

    snapshot.value = _StatisticsSnapshot(
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

  Future<_StatisticsSnapshot> _loadFromContract() async {
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
          if (state.active) activeLevels++;
          if (state.frozen) frozenLevels++;
          playerRewardsWei += state.earnedWei;
        } catch (_) {}
      }

      levelRows.add(_LevelArenaStat(
        level: level,
        priceWei: levelPriceWei,
        activeCells: advanceStats?.activeCells ?? BigInt.zero,
        prizePoolWei: advanceStats?.prizePoolWei ?? BigInt.zero,
        totalWeight: advanceStats?.totalWeight ?? BigInt.zero,
      ));
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
