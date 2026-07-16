import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/services/app_config_service.dart';
import 'package:lottery_advance/app/services/game_schedule_rest_data_source.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/firebase_options.dart';

class GameScheduleService extends GetxService {
  final WalletConnectService _walletService = Get.find<WalletConnectService>();
  final GameScheduleRestDataSource _restDataSource =
      GameScheduleRestDataSource();

  final RxList<GameRoundSchedule> schedules = <GameRoundSchedule>[].obs;
  final RxBool isReady = false.obs;
  final RxString errorMessage = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Worker? _chainWorker;
  int _watchGeneration = 0;

  Future<GameScheduleService> init() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _chainWorker ??= ever<int?>(
      _walletService.chainId,
      (_) => unawaited(_watchRounds()),
    );
    await _watchRounds();
    isReady.value = true;
    return this;
  }

  Future<void> _watchRounds() async {
    final generation = ++_watchGeneration;
    await _subscription?.cancel();
    final chainId =
        _walletService.chainId.value ?? WalletConnectService.targetBaseChainId;
    String configuredContract;
    String configuredManager;
    try {
      final identity = await _resolveRoundIdentity();
      configuredContract = identity.contractAddress;
      configuredManager = identity.managerAddress;
    } catch (error) {
      if (generation != _watchGeneration) return;
      schedules.clear();
      errorMessage.value = 'Round contract configuration is incomplete: $error';
      return;
    }

    schedules.clear();
    _subscription = FirebaseFirestore.instance
        .collection('rounds')
        .where('chainId', isEqualTo: chainId)
        .snapshots()
        .listen(
      (snapshot) {
        if (generation != _watchGeneration) return;
        final parsed = <GameRoundSchedule>[];
        for (final document in snapshot.docs) {
          try {
            final round = GameRoundSchedule.fromFirestore(document);
            if (round.contractAddress == configuredContract &&
                round.roundManagerAddress == configuredManager) {
              parsed.add(round);
            }
          } catch (error) {
            if (kDebugMode) {
              debugPrint('Invalid round ${document.id}: $error');
            }
          }
        }
        if (parsed.isEmpty) {
          unawaited(_loadRestFallback(
            generation: generation,
            chainId: chainId,
            configuredContract: configuredContract,
            configuredManager: configuredManager,
            onlyWhenEmpty: false,
          ));
          return;
        }
        _acceptRounds(
          parsed,
          configuredContract: configuredContract,
          configuredManager: configuredManager,
        );
      },
      onError: (Object error) {
        if (kDebugMode) debugPrint('Round schedule stream failed: $error');
        unawaited(_loadRestFallback(
          generation: generation,
          chainId: chainId,
          configuredContract: configuredContract,
          configuredManager: configuredManager,
          onlyWhenEmpty: true,
        ));
      },
    );

    await _loadRestFallback(
      generation: generation,
      chainId: chainId,
      configuredContract: configuredContract,
      configuredManager: configuredManager,
      onlyWhenEmpty: true,
    );
  }

  Future<_RoundIdentity> _resolveRoundIdentity() async {
    final config = Get.find<AppConfigService>();
    var contract = config.get('easyGameContractAddress').toLowerCase();
    var manager = config.get('roundManagerAddress').toLowerCase();

    if (contract.isEmpty) {
      contract = (await _walletService.resolveEasyGameAddress()).toLowerCase();
    }
    if (manager.isEmpty) {
      manager =
          (await _walletService.resolveRoundManagerAddress()).toLowerCase();
    }
    if (contract.isEmpty || manager.isEmpty) {
      throw const FormatException('Missing core or round manager address');
    }
    return _RoundIdentity(
      contractAddress: contract,
      managerAddress: manager,
    );
  }

  Future<void> _loadRestFallback({
    required int generation,
    required int chainId,
    required String configuredContract,
    required String configuredManager,
    required bool onlyWhenEmpty,
  }) async {
    try {
      final rounds = await _restDataSource.fetchRounds(chainId: chainId);
      if (generation != _watchGeneration ||
          (onlyWhenEmpty && schedules.isNotEmpty)) {
        return;
      }
      _acceptRounds(
        rounds,
        configuredContract: configuredContract,
        configuredManager: configuredManager,
      );
    } catch (error) {
      if (generation != _watchGeneration || schedules.isNotEmpty) return;
      errorMessage.value = '$error';
      if (kDebugMode) {
        debugPrint('Public round schedule fallback failed: $error');
      }
    }
  }

  void _acceptRounds(
    Iterable<GameRoundSchedule> rounds, {
    required String configuredContract,
    required String configuredManager,
  }) {
    final accepted = rounds
        .where((round) =>
            round.contractAddress == configuredContract &&
            round.roundManagerAddress == configuredManager)
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    schedules.assignAll(accepted);
    errorMessage.value = '';
  }

  @override
  void onClose() {
    _watchGeneration++;
    _chainWorker?.dispose();
    _subscription?.cancel();
    _restDataSource.close();
    super.onClose();
  }
}

class _RoundIdentity {
  const _RoundIdentity({
    required this.contractAddress,
    required this.managerAddress,
  });

  final String contractAddress;
  final String managerAddress;
}
