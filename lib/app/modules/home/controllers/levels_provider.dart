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
      ever<Map<int, int>>(_rounds.selectedRoundIds, (_) => fetchLevels()),
      ever<Map<int, GameRoundChainState>>(
        _roundChain.states,
        (_) => fetchLevels(),
      ),
    ]);

    if (backend.isReady.value) _subscribeToTransactions(backend);
  }

  void configure({String? playerAddress}) {
    this.playerAddress = playerAddress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isClosed) return;
      if (levels.isEmpty) levels.assignAll(_initialLevels());
      fetchLevels();
    });
  }

  void _handleWalletChange() {
    if (isClosed || playerAddress != null) return;
    _subscribeToTransactions(Get.find<FirebaseBackendService>());
    fetchLevels();
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
    final run = ++_refreshRun;
    if (isClosed) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final results = await Future.wait<dynamic>([
        _roundLevels.loadCards(playerAddress: playerAddress),
        if (walletService.isConnected.value && playerAddress == null)
          _settlement.getClaimable(),
      ]);
      if (isClosed || run != _refreshRun) return;

      levels.assignAll(results.first as List<RoundLevelCardState>);
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
      if (!isClosed && run == _refreshRun) isLoading.value = false;
    }
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
    _transactionsSub?.cancel();
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
