import 'dart:async';

import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_transaction_model.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/controllers/wallet_auth_controller.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/repositories/round_levels_repository.dart';
import 'package:lottery_advance/app/services/game_round_blockchain_service.dart';
import 'package:lottery_advance/app/services/game_settlement_service.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class LevelDetailController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final WalletAuthController authController = Get.find<WalletAuthController>();
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
  final transactions = <GameTransaction>[].obs;
  final isTransactionsLoading = false.obs;
  final transactionsError = ''.obs;
  final List<Worker> _workers = [];
  StreamSubscription<List<GameTransaction>>? _transactionsSubscription;
  int _refreshRun = 0;

  @override
  void onInit() {
    super.onInit();
    _workers.addAll([
      ever<bool>(walletService.isConnected, (_) => _handleWalletChange()),
      ever<String>(walletService.currentAddress, (_) => _handleWalletChange()),
      ever(_roundChain.states, (_) => refreshDetail()),
    ]);
    if (Get.isRegistered<FirebaseBackendService>()) {
      final backend = Get.find<FirebaseBackendService>();
      _workers.add(ever<bool>(backend.isReady, (ready) {
        if (ready) _subscribeTransactions();
      }));
    }
    refreshDetail();
    _subscribeTransactions();
  }

  GameRoundViewState? get round {
    for (final item in _rounds.timeline) {
      if (item.schedule.roundId == roundId.toInt()) return item;
    }
    return null;
  }

  LevelDetailDestination? destinationForLevel(int targetLevel) {
    if (targetLevel < 1 || targetLevel > 17) return null;
    final currentRound = round;
    if (currentRound == null) return null;
    final target = _rounds.roundForLevelInSeason(
      targetLevel,
      currentRound.schedule.seasonId,
    );
    if (target == null) return null;
    return LevelDetailDestination(
      level: targetLevel,
      roundId: BigInt.from(target.schedule.roundId),
    );
  }

  void _handleWalletChange() {
    refreshDetail();
    _subscribeTransactions();
  }

  void _subscribeTransactions() {
    _transactionsSubscription?.cancel();
    transactions.clear();
    transactionsError.value = '';
    if (!authController.isAuthenticated ||
        walletService.currentAddress.value.isEmpty ||
        !Get.isRegistered<FirebaseBackendService>()) {
      isTransactionsLoading.value = false;
      return;
    }
    final backend = Get.find<FirebaseBackendService>();
    if (!backend.isReady.value) {
      isTransactionsLoading.value = true;
      return;
    }
    isTransactionsLoading.value = true;
    _transactionsSubscription = backend
        .watchRecentTransactions(
      limit: 50,
      chainId: walletService.chainId.value,
      wallet: walletService.currentAddress.value,
    )
        .listen(
      (items) {
        if (isClosed) return;
        transactions.assignAll(
          items.where((transaction) => transaction.level == level),
        );
        isTransactionsLoading.value = false;
      },
      onError: (Object error) {
        if (isClosed) return;
        transactionsError.value = error.toString();
        isTransactionsLoading.value = false;
      },
    );
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
        _levels.loadPlayerLevel(
          level: level,
          round: selectedRound,
          playerAddress: authController.isAuthenticated
              ? walletService.currentAddress.value
              : null,
        ),
        if (authController.isAuthenticated)
          walletService.getEasyGamePlayerSummary(),
        if (authController.isAuthenticated) _settlement.getClaimable(),
      ]);
      if (isClosed || run != _refreshRun) return;
      final card = values[0] as RoundLevelCardState;
      snapshot.value = LevelDetailSnapshot(
        card: card,
        player: authController.isAuthenticated ? values[1] : null,
        settlement: authController.isAuthenticated
            ? values.last as SettlementClaimable
            : SettlementClaimable.zero,
      );
    } catch (error) {
      if (isClosed || run != _refreshRun) return;
      errorMessage.value = error.toString();
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
      await Get.find<WalletAuthController>().ensureAuthenticated();
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
    final mode = data.card.resolveViewMode();
    switch (mode) {
      case RoundLevelCardViewMode.active:
        return 'common.active'.tr;
      case RoundLevelCardViewMode.frozen:
        return 'common.frozen'.tr;
      case RoundLevelCardViewMode.skipped:
        return 'levels.missed'.tr;
      case RoundLevelCardViewMode.activation:
        return 'levels.availableActivation'.tr;
      case RoundLevelCardViewMode.completed:
        return 'round.settled'.tr;
      case RoundLevelCardViewMode.awaiting:
        return 'levels.gameNotStarted'.tr;
      case RoundLevelCardViewMode.paused:
      case RoundLevelCardViewMode.cancelled:
        return 'round.${data.card.round?.phase.name ?? 'paused'}'.tr;
    }
  }

  @override
  void onClose() {
    _refreshRun++;
    for (final worker in _workers) {
      worker.dispose();
    }
    _transactionsSubscription?.cancel();
    super.onClose();
  }
}
