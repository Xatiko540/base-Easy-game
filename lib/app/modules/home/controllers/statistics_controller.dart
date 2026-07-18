part of '../views/utility_screens.dart';

class _StatisticsController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final WalletAuthController authController = Get.find<WalletAuthController>();
  final GameRoundsRepository _rounds = Get.find<GameRoundsRepository>();

  final snapshot = Rxn<_StatisticsSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  final List<Worker> _workers = [];
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever<Map<int, int>>(_rounds.selectedRoundIds, (_) => refreshStats()),
      ever<bool>(walletService.isConnected, (_) => refreshStats()),
      ever<String>(walletService.currentAddress, (_) => refreshStats()),
      ever<int?>(walletService.chainId, (_) => refreshStats()),
      ever<WalletAuthPhase>(authController.phase, (_) => refreshStats()),
    ]);
    refreshStats();
  }

  @override
  void onClose() {
    _requestId++;
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }

  Future<void> refreshStats() async {
    final requestId = ++_requestId;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final next = await _loadRoundStats();
      if (!isClosed && requestId == _requestId) {
        snapshot.value = next;
      }
    } catch (error) {
      if (!isClosed && requestId == _requestId) {
        errorMessage.value = error.toString();
      }
    } finally {
      if (!isClosed && requestId == _requestId) {
        isLoading.value = false;
      }
    }
  }

  Future<_StatisticsSnapshot> _loadRoundStats() async {
    final contractAddress = await walletService.resolveEasyGameAddress();
    final rounds = _rounds.roundsByLevel.entries.toList(growable: false);
    final samples = await Future.wait(
      rounds.map((entry) => _loadRound(entry.key, entry.value)),
    );

    var activeLevels = 0;
    var frozenLevels = 0;
    var matrixNodes = BigInt.zero;
    var totalLevelCostWei = BigInt.zero;
    var totalPrizePoolWei = BigInt.zero;
    var totalWeight = BigInt.zero;
    final rows = <_LevelArenaStat>[];
    for (final sample in samples) {
      if (sample.playerActive) activeLevels++;
      if (sample.playerFrozen) frozenLevels++;
      matrixNodes += sample.matrix.activeCells;
      totalLevelCostWei += sample.priceWei;
      totalPrizePoolWei += sample.matrix.prizePoolEth;
      totalWeight += sample.matrix.totalWeight;
      rows.add(_LevelArenaStat(
        level: sample.level,
        priceWei: sample.priceWei,
        activeCells: sample.matrix.activeCells,
        prizePoolWei: sample.matrix.prizePoolEth,
        totalWeight: sample.matrix.totalWeight,
      ));
    }
    rows.sort((left, right) => right.level.compareTo(left.level));

    final rewards = authController.isAuthenticated
        ? await walletService.getSettlementClaimable()
        : SettlementClaimable.zero;
    return _StatisticsSnapshot(
      contractAddress: contractAddress,
      activeLevels: activeLevels,
      frozenLevels: frozenLevels,
      matrixNodes: matrixNodes,
      totalLevelCostWei: totalLevelCostWei,
      totalPrizePoolWei: totalPrizePoolWei,
      totalWeight: totalWeight,
      playerRewardsWei: rewards.ethAmount,
      levelRows: rows,
    );
  }

  Future<_RoundStatisticsSample> _loadRound(
    int level,
    GameRoundViewState round,
  ) async {
    final roundId = BigInt.from(round.schedule.roundId);
    RoundMatrixStats matrix;
    try {
      matrix = (await walletService.getRoundMatrixStats(roundId))!;
    } catch (_) {
      matrix = RoundMatrixStats(
        prizePoolEth: BigInt.zero,
        prizePoolUsdc: BigInt.zero,
        totalWeight: BigInt.zero,
        activeCells: round.chainState?.occupiedCells ?? BigInt.zero,
        nextCellId: BigInt.zero,
        nextOpenParentId: BigInt.zero,
      );
    }

    var playerActive = false;
    var playerFrozen = false;
    if (authController.isAuthenticated &&
        walletService.currentAddress.value.isNotEmpty) {
      try {
        final player = await walletService.getRoundPlayerState(roundId);
        playerActive = player?.active ?? false;
        if (player?.active == true) {
          final status = await walletService.getArenaSkillStatus(roundId);
          playerFrozen = status?.frozen ?? false;
        }
      } catch (_) {
        // Global round statistics remain useful if a player-specific getter is
        // temporarily unavailable on the selected network.
      }
    }

    return _RoundStatisticsSample(
      level: level,
      priceWei: round.ethPriceWei,
      matrix: matrix,
      playerActive: playerActive,
      playerFrozen: playerFrozen,
    );
  }
}
