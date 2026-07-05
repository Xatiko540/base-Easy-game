part of '../views/levels.dart';

class LevelsProvider extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

  final RxList<Level> levels = <Level>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  String? playerAddress;
  int _refreshRun = 0;

  BigInt get totalEarnedWei => levels.fold<BigInt>(
        BigInt.zero,
        (sum, level) => sum + level.earnedWei,
      );

  int get activeLevels => levels
      .where((level) =>
          level.status == LevelStatus.active ||
          level.status == LevelStatus.frozen)
      .length;

  void configure({String? playerAddress}) {
    this.playerAddress = playerAddress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) {
        return;
      }
      if (levels.isEmpty) {
        levels.assignAll(_initialLevels());
      }
      refreshFromContract();
    });
  }

  Future<void> refreshFromContract() async {
    final run = ++_refreshRun;
    if (isClosed) {
      return;
    }

    if (!walletService.isConnected.value && playerAddress == null) {
      errorMessage.value = 'levels.connectToRead'.tr;
      levels.assignAll(_initialLevels());
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final nextLevels = <Level>[];
      for (var levelNumber = easyGameLevelCount;
          levelNumber >= 1;
          levelNumber--) {
        if (isClosed || run != _refreshRun) {
          return;
        }
        nextLevels.add(await _loadLevel(levelNumber));
      }
      if (isClosed || run != _refreshRun) {
        return;
      }
      levels.assignAll(nextLevels);
    } catch (e) {
      if (isClosed || run != _refreshRun) {
        return;
      }
      errorMessage.value = '${'levels.unableRefresh'.tr}: $e';
      if (kDebugMode) {
        print(errorMessage.value);
      }
    } finally {
      if (!isClosed && run == _refreshRun) {
        isLoading.value = false;
      }
    }
  }

  Future<Level> _loadLevel(int levelNumber) async {
    final priceWei = await walletService.getEasyGameLevelPriceWei(levelNumber);
    final state = await walletService.getEasyGameLevel(
      playerAddress: playerAddress,
      level: levelNumber,
    );
    final matrixStats = await walletService.getEasyGameMatrixStats(levelNumber);
    final advancedStats =
        await walletService.getEasyGameAdvanceLevelStats(levelNumber);
    final available = await walletService.isEasyGameLevelAvailable(levelNumber);
    var playerWeight = BigInt.zero;
    var playerChanceBps = BigInt.zero;
    if (state.active) {
      playerWeight = await walletService.getEasyGamePlayerWeight(
        playerAddress: playerAddress,
        level: levelNumber,
      );
      playerChanceBps = await walletService.getEasyGamePlayerChanceBps(
        playerAddress: playerAddress,
        level: levelNumber,
      );
    }

    final status = state.active
        ? state.frozen
            ? LevelStatus.frozen
            : LevelStatus.active
        : available
            ? LevelStatus.waiting
            : LevelStatus.locked;

    return Level(
      levelNumber: levelNumber,
      status: status,
      coin: weiToEthDouble(priceWei),
      partnerBonus: weiToEthDouble(priceWei) * 0.095,
      levelProfit: weiToEthDouble(state.earnedWei),
      fillPercent: _fillPercent(state, matrixStats),
      isVisible: available || state.active,
      cycles: state.cycles,
      positionId: state.positionId,
      earnedWei: state.earnedWei,
      matrixSize: matrixStats.size,
      prizePoolWei: advancedStats.prizePoolWei,
      totalWeight: advancedStats.totalWeight,
      activeCells: advancedStats.activeCells,
      playerWeight: playerWeight,
      playerChanceBps: playerChanceBps,
    );
  }

  List<Level> _initialLevels() {
    return [
      for (var i = easyGameLevelCount; i >= 1; i--)
        Level(
          levelNumber: i,
          status: i >= 3 ? LevelStatus.waiting : LevelStatus.locked,
          coin: levelPrice(i),
          partnerBonus: levelPrice(i) * 0.095,
          levelProfit: 0,
          fillPercent: 0,
          isVisible: i >= 3,
        ),
    ];
  }

  double _fillPercent(
    EasyGameLevelState state,
    EasyGameMatrixStats matrixStats,
  ) {
    if (!state.active || matrixStats.size == BigInt.zero) {
      return 0;
    }
    if (state.positionId == BigInt.zero) {
      return 0;
    }

    final filled = state.positionId.toDouble();
    final total = matrixStats.size.toDouble();
    if (total <= 0) {
      return 0;
    }
    return ((filled / total) * 100).clamp(0, 100).toDouble();
  }
}
