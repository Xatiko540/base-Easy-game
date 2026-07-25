import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/models/game_transaction_model.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/modules/home/controllers/wallet_auth_controller.dart';
import 'package:lottery_advance/app/models/wallet_auth_models.dart';
import 'package:lottery_advance/app/repositories/round_levels_repository.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/game_round_blockchain_service.dart';
import 'package:lottery_advance/app/services/game_settlement_service.dart';
import 'package:lottery_advance/app/services/game_contract_events_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class LevelsProvider extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();
  final WalletAuthController authController = Get.find<WalletAuthController>();
  final RoundLevelsRepository _roundLevels = Get.find<RoundLevelsRepository>();
  final GameSettlementService _settlement = Get.find<GameSettlementService>();
  final GameRoundBlockchainService _roundChain =
      Get.find<GameRoundBlockchainService>();
  final GameContractEventsService _contractEvents =
      Get.find<GameContractEventsService>();

  final RxList<RoundLevelCardState> levels = <RoundLevelCardState>[].obs;
  final Rx<SettlementClaimable> settlementClaimable =
      SettlementClaimable.zero.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<GameTransaction> transactions = <GameTransaction>[].obs;
  final RxBool isTransactionsLoading = false.obs;
  final RxString transactionsError = ''.obs;

  String? playerAddress;
  bool _hasCompletedInitialLoad = false;
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
      ever<bool>(walletService.isConnected, (_) => fetchLevels()),
      ever<String>(walletService.currentAddress, (_) => fetchLevels()),
      ever<int?>(walletService.chainId, (_) => fetchLevels()),
      ever<WalletAuthPhase>(authController.phase, (_) => fetchLevels()),
      ever<Map<int, GameRoundChainState>>(
        _roundChain.states,
        (_) => fetchLevels(),
      ),
      ever<int>(
        _contractEvents.eventRevision,
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

  void _subscribeToTransactions(FirebaseBackendService backend) {
    _transactionsSub?.cancel();
    if (playerAddress != null || !authController.isAuthenticated) {
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

  bool _isFetching = false;

  Future<void> fetchLevels() async {
    if (isClosed || _isFetching) return;
    _isFetching = true;
    isLoading.value = !_hasCompletedInitialLoad;
    errorMessage.value = '';
    try {
      final results = await Future.wait<dynamic>([
        _roundLevels.loadCards(
          playerAddress: playerAddress ??
              (authController.isAuthenticated
                  ? walletService.currentAddress.value
                  : null),
        ),
        if (authController.isAuthenticated && playerAddress == null)
          _loadSettlementClaimable(),
      ]);
      if (isClosed) return;

      final incoming = results.first as List<RoundLevelCardState>;
      levels.assignAll(incoming);
      settlementClaimable.value = results.length > 1
          ? results[1] as SettlementClaimable
          : SettlementClaimable.zero;

      errorMessage.value = '';
    } catch (error) {
      if (isClosed) return;
      errorMessage.value = '${'levels.unableRefresh'.tr}: $error';
      if (kDebugMode) debugPrint(errorMessage.value);
    } finally {
      _isFetching = false;
      if (!isClosed) {
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
    _transactionsSub?.cancel();
    for (final worker in _workers) {
      worker.dispose();
    }
    super.onClose();
  }
}
