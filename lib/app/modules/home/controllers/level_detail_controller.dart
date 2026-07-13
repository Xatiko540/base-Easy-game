import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';
import 'package:lottery_advance/app/repositories/round_levels_repository.dart';
import 'package:lottery_advance/app/services/game_round_blockchain_service.dart';
import 'package:lottery_advance/app/services/game_settlement_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class LevelDetailController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final RoundLevelsRepository _levels = Get.find<RoundLevelsRepository>();
  final GameRoundsController _rounds = Get.find<GameRoundsController>();
  final GameSettlementService _settlement = Get.find<GameSettlementService>();
  final GameRoundBlockchainService _roundChain =
      Get.find<GameRoundBlockchainService>();

  final int level;
  final BigInt roundId;

  LevelDetailController({required this.level, required this.roundId});

  final snapshot = Rxn<LevelDetailSnapshot>();
  final isLoading = false.obs;
  final isActionBusy = false.obs;
  final errorMessage = ''.obs;
  final actionError = ''.obs;
  final List<Worker> _workers = [];
  int _refreshRun = 0;

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever<bool>(walletService.isConnected, (_) => refreshDetail()),
      ever<String>(walletService.currentAddress, (_) => refreshDetail()),
      ever<int?>(walletService.chainId, (_) => refreshDetail()),
      ever(_roundChain.states, (_) => refreshDetail()),
    ]);
    refreshDetail();
  }

  GameRoundViewState? get round {
    for (final item in _rounds.timeline) {
      if (item.schedule.roundId == roundId.toInt()) return item;
    }
    return null;
  }

  BigInt? roundIdForLevel(int targetLevel) {
    final target = _rounds.roundForLevel(targetLevel);
    return target == null ? null : BigInt.from(target.schedule.roundId);
  }

  Future<void> refreshDetail() async {
    final run = ++_refreshRun;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final selectedRound = round;
      if (selectedRound == null) {
        throw StateError('Round $roundId is not present in the schedule.');
      }

      final values = await Future.wait<dynamic>([
        _levels.loadLevel(level: level, round: selectedRound),
        if (walletService.isConnected.value)
          walletService.getEasyGamePlayerSummary(),
        if (walletService.isConnected.value) _settlement.getClaimable(),
      ]);
      if (isClosed || run != _refreshRun) return;
      final card = values[0];
      if (card.hasError) throw StateError(card.errorMessage!);
      snapshot.value = LevelDetailSnapshot(
        card: card,
        player: walletService.isConnected.value ? values[1] : null,
        settlement: walletService.isConnected.value
            ? values.last as SettlementClaimable
            : SettlementClaimable.zero,
      );
    } catch (error) {
      if (isClosed || run != _refreshRun) return;
      errorMessage.value = error.toString();
      snapshot.value = null;
    } finally {
      if (!isClosed && run == _refreshRun) isLoading.value = false;
    }
  }

  Future<String> claimPrize() => _runAction(_settlement.claimPrize);

  Future<String> claimReferralBonus() =>
      _runAction(walletService.claimEasyGameReferralBonus);

  Future<String> _runAction(Future<String> Function() action) async {
    if (isActionBusy.value) throw StateError('Action already in progress.');
    isActionBusy.value = true;
    actionError.value = '';
    try {
      final transactionHash = await action();
      await refreshDetail();
      return transactionHash;
    } catch (error) {
      actionError.value = error.toString();
      rethrow;
    } finally {
      isActionBusy.value = false;
    }
  }

  double fillPercent(LevelDetailSnapshot data) => data.card.fillPercent;

  String stateLabel(LevelDetailSnapshot data) {
    if (data.card.isFrozen) return 'common.frozen'.tr;
    if (data.card.isPlayerActive) return 'common.active'.tr;
    return 'levels.availableActivation'.tr;
  }

  @override
  void onClose() {
    _refreshRun++;
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
