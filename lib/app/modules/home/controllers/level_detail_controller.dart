import 'dart:async';
import 'package:get/get.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/services/firebase_data_service.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';

class LevelDetailController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final int level;
  late final FirebaseDataService _firebaseData;

  LevelDetailController({
    required this.level,
  });

  final snapshot = Rxn<LevelDetailSnapshot>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Worker? _connectionWorker;
  Worker? _addressWorker;
  StreamSubscription<FirebaseLevelData?>? _levelSub;

  @override
  void onInit() {
    super.onInit();
    _firebaseData = Get.find<FirebaseDataService>();
    _firebaseData.init();

    _levelSub = _firebaseData.watchLevel(level).listen((fbLevel) {
      if (fbLevel != null && snapshot.value != null) {
        final prev = snapshot.value!;
        snapshot.value = LevelDetailSnapshot(
          state: prev.state,
          stats: EasyGameMatrixStats(
            size: fbLevel.activeCells,
            nextOpenParentId: fbLevel.nextOpenParent,
          ),
          advanceStats: EasyGameAdvanceLevelStats(
            prizePoolWei: fbLevel.prizePoolWei,
            totalWeight: fbLevel.totalWeight,
            activeCells: fbLevel.activeCells,
            nextOpenParentId: fbLevel.nextOpenParent,
            nextCellId: fbLevel.nextCell,
          ),
          priceWei: fbLevel.ethPriceWei,
          player: prev.player,
          playerWeight: prev.playerWeight,
          playerChanceBps: prev.playerChanceBps,
        );
      }
    });

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
    _levelSub?.cancel();
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

  Future<LevelDetailSnapshot> _load() async {
    EasyGameMatrixStats? stats;
    EasyGameAdvanceLevelStats? advanceStats;
    BigInt priceWei;

    // Try Firebase first for public data
    final fb = await _firebaseData.getLevel(level);
    if (fb != null) {
      stats = EasyGameMatrixStats(
        size: fb.activeCells,
        nextOpenParentId: fb.nextOpenParent,
      );
      advanceStats = EasyGameAdvanceLevelStats(
        prizePoolWei: fb.prizePoolWei,
        totalWeight: fb.totalWeight,
        activeCells: fb.activeCells,
        nextOpenParentId: fb.nextOpenParent,
        nextCellId: fb.nextCell,
      );
      priceWei = fb.ethPriceWei;
    } else {
      // Fallback to contract
      stats = await walletService.getEasyGameMatrixStats(level);
      advanceStats = await walletService.getEasyGameAdvanceLevelStats(level);
      priceWei = await walletService.getEasyGameLevelPriceWei(level);
    }

    final state = await walletService.getEasyGameLevel(level: level);
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
    return LevelDetailSnapshot(
      state: state,
      stats: stats,
      advanceStats: advanceStats,
      priceWei: priceWei,
      player: player,
      playerWeight: playerWeight,
      playerChanceBps: playerChanceBps,
    );
  }

  double fillPercent(LevelDetailSnapshot data) {
    if (data.stats.size == BigInt.zero ||
        data.state.positionId == BigInt.zero) {
      return 0;
    }
    return ((data.state.positionId.toDouble() / data.stats.size.toDouble()) *
            100)
        .clamp(0, 100)
        .toDouble();
  }

  String stateLabel(LevelDetailSnapshot data) {
    if (data.state.frozen) return 'common.frozen'.tr;
    if (data.state.active) return 'common.active'.tr;
    return 'levels.availableActivation'.tr;
  }
}
