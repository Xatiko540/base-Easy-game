import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/models/game_transaction_model.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/repositories/round_levels_repository.dart';
import 'package:lottery_advance/app/repositories/game_rounds_repository.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/game_round_blockchain_service.dart';
import 'package:lottery_advance/app/services/game_settlement_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class LevelsProvider extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final RoundLevelsRepository _roundLevels = Get.find<RoundLevelsRepository>();
  final GameSettlementService _settlement = Get.find<GameSettlementService>();
  final GameRoundBlockchainService _roundChain =
      Get.find<GameRoundBlockchainService>();
  final GameRoundsRepository _rounds = Get.find<GameRoundsRepository>();

  final RxList<RoundLevelCardState> levels = <RoundLevelCardState>[].obs;
  final Rx<SettlementClaimable> settlementClaimable =
      SettlementClaimable.zero.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<GameTransaction> transactions = <GameTransaction>[].obs;
  final RxBool isTransactionsLoading = false.obs;
  final RxString transactionsError = ''.obs;

  String? playerAddress;
  int _refreshRun = 0;
  bool _fetchInFlight = false;
  bool _fetchQueued = false;
  bool _hasCompletedInitialLoad = false;
  Timer? _refreshDebounce;
  Timer? _autoRefreshTimer;
  StreamSubscription<List<GameTransaction>>? _transactionsSub;
  final List<Worker> _workers = [];

  BigInt get totalEarnedWei => settlementClaimable.value.ethAmount;

  int get activeLevels => levels.where((level) => level.isPlayerActive).length;

  @override
  void onInit() {
    super.onInit();
    final backend = Get.find<FirebaseBackendService>();

    _workers.addAll([
      ever<bool>(backend.isReady, (ready) {
        if (ready) _subscribeToTransactions(backend);
      }),
      ever<bool>(walletService.isConnected, (_) => _handleWalletChange()),
      ever<String>(walletService.currentAddress, (_) => _handleWalletChange()),
      ever<int?>(walletService.chainId, (_) => _handleWalletChange()),
      ever<Map<int, int>>(_rounds.selectedRoundIds, (_) => _queueFetchLevels()),
      ever<Map<int, GameRoundChainState>>(
        _roundChain.states,
        (_) => _queueFetchLevels(),
      ),
    ]);

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _queueFetchLevels(),
    );

    if (backend.isReady.value) _subscribeToTransactions(backend);
  }

  void configure({String? playerAddress}) {
    this.playerAddress = playerAddress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      if (levels.isEmpty) levels.assignAll(_initialLevels());
      _queueFetchLevels(immediate: true);
    });
  }

  void _handleWalletChange() {
    if (isClosed || playerAddress != null) return;
    _subscribeToTransactions(Get.find<FirebaseBackendService>());
    _queueFetchLevels();
  }

  void _queueFetchLevels({bool immediate = false}) {
    if (isClosed) return;
    _refreshDebounce?.cancel();
    if (immediate) {
      fetchLevels();
      return;
    }
    _refreshDebounce = Timer(
      const Duration(milliseconds: 350),
      fetchLevels,
    );
  }

  void _subscribeToTransactions(FirebaseBackendService backend) {
    _transactionsSub?.cancel();
    if (playerAddress != null || !walletService.isConnected.value) {
      transactions.clear();
      transactionsError.value = '';
      isTransactionsLoading.value = false;
      return;
    }
    if (!backend.isReady.value) {
      isTransactionsLoading.value = true;
      return;
    }

    isTransactionsLoading.value = true;
    transactionsError.value = '';
    _transactionsSub = backend
        .watchRecentTransactions(
      chainId: walletService.chainId.value,
      wallet: walletService.currentAddress.value,
    )
        .listen(
      (items) {
        if (isClosed) return;
        transactions.assignAll(items);
        isTransactionsLoading.value = false;
      },
      onError: (Object error) {
        if (isClosed) return;
        transactionsError.value = error.toString();
        isTransactionsLoading.value = false;
      },
    );
  }

  Future<void> fetchLevels() async {
    if (isClosed) return;
    _refreshRun++;
    if (_fetchInFlight) {
      _fetchQueued = true;
      return;
    }

    _fetchInFlight = true;
    try {
      do {
        _fetchQueued = false;
        await _fetchLevelsOnce(_refreshRun);
      } while (_fetchQueued && !isClosed);
    } finally {
      _fetchInFlight = false;
      if (!isClosed) isLoading.value = false;
    }
  }

  Future<void> _fetchLevelsOnce(int run) async {
    if (isClosed) return;

    // Keep already rendered cards in place during background refreshes.
    isLoading.value = !_hasCompletedInitialLoad;
    errorMessage.value = '';
    try {
      final results = await Future.wait<dynamic>([
        _roundLevels.loadCards(
          playerAddress: playerAddress,
          onBatch: (batch) {
            if (isClosed || run != _refreshRun) return;
            _applyCardBatch(batch);
          },
        ),
        if (walletService.isConnected.value && playerAddress == null)
          _loadSettlementClaimable(),
      ]);
      if (isClosed || run != _refreshRun) return;

      final incoming = results.first as List<RoundLevelCardState>;
      levels.assignAll(_mergeWithStableCards(incoming));
      settlementClaimable.value = results.length > 1
          ? results[1] as SettlementClaimable
          : SettlementClaimable.zero;

      final failures = levels.where((item) => item.hasError).toList();
      if (failures.isNotEmpty) {
        errorMessage.value = 'levels.partialRoundLoad'.trParams({
          'count': '${failures.length}',
        });
      }
    } catch (error) {
      if (isClosed || run != _refreshRun) return;
      errorMessage.value = '${'levels.unableRefresh'.tr}: $error';
      if (kDebugMode) debugPrint(errorMessage.value);
    } finally {
      if (!isClosed && run == _refreshRun) {
        _hasCompletedInitialLoad = true;
        isLoading.value = false;
      }
    }
  }

  Future<SettlementClaimable> _loadSettlementClaimable() async {
    try {
      return await _settlement.getClaimable();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Settlement balance is not available yet: $error');
      }
      return settlementClaimable.value;
    }
  }

  List<RoundLevelCardState> _mergeWithStableCards(
    List<RoundLevelCardState> incoming,
  ) {
    final previous = {for (final item in levels) item.level: item};
    return incoming.map((next) {
      final current = previous[next.level];
      final sameRound = current != null && current.roundId == next.roundId;
      final transientFailure = next.hasError || next.isPlayerStatePending;
      final currentIsStable = current != null &&
          !current.hasError &&
          !current.isPlayerStatePending &&
          current.hasRound;
      if (sameRound && transientFailure && currentIsStable) return current;
      return next;
    }).toList();
  }

  void _applyCardBatch(List<RoundLevelCardState> batch) {
    final next = levels.toList();
    for (final incoming in batch) {
      final index = next.indexWhere((item) => item.level == incoming.level);
      if (index < 0) {
        next.add(incoming);
        continue;
      }
      final current = next[index];
      final sameRound = current.roundId == incoming.roundId;
      final transientFailure =
          incoming.hasError || incoming.isPlayerStatePending;
      final currentIsStable = !current.hasError &&
          !current.isPlayerStatePending &&
          current.hasRound;
      if (!(sameRound && transientFailure && currentIsStable)) {
        next[index] = incoming;
      }
    }
    next.sort((a, b) => b.level.compareTo(a.level));
    levels.assignAll(next);
  }

  Future<void> refreshAll() async {
    _subscribeToTransactions(Get.find<FirebaseBackendService>());
    await fetchLevels();
  }

  List<RoundLevelCardState> _initialLevels() => [
        for (var level = 17; level >= 1; level--)
          RoundLevelCardState(level: level),
      ];

  @override
  void onClose() {
    _refreshRun++;
    _refreshDebounce?.cancel();
    _autoRefreshTimer?.cancel();
    _transactionsSub?.cancel();
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
