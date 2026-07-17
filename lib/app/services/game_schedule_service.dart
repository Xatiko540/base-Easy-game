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

enum GameScheduleAvailability {
  loading,
  awaitingPublication,
  ready,
  failed,
}

class GameScheduleService extends GetxService {
  final WalletConnectService _walletService = Get.find<WalletConnectService>();
  final GameScheduleRestDataSource _restDataSource =
      GameScheduleRestDataSource();

  final RxList<GameRoundSchedule> schedules = <GameRoundSchedule>[].obs;
  final RxBool isReady = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<GameScheduleAvailability> availability =
      GameScheduleAvailability.loading.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Worker? _chainWorker;
  Worker? _configWorker;
  int _watchGeneration = 0;
  String? _activeIdentityKey;

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
    _configWorker ??= ever<bool>(
      Get.find<AppConfigService>().isLoaded,
      (loaded) {
        if (loaded) unawaited(_watchRounds());
      },
    );
    await _watchRounds();
    isReady.value = true;
    return this;
  }

  Future<void> _watchRounds() async {
    final generation = ++_watchGeneration;
    await _subscription?.cancel();
    if (schedules.isEmpty) {
      availability.value = GameScheduleAvailability.loading;
    }
    errorMessage.value = '';
    final chainId =
        _walletService.chainId.value ?? WalletConnectService.targetBaseChainId;
    _RoundIdentity? identity;
    try {
      identity = await _resolveRoundIdentity();
    } catch (error) {
      if (generation != _watchGeneration) return;
      schedules.clear();
      availability.value = GameScheduleAvailability.failed;
      errorMessage.value = 'Invalid round contract configuration: $error';
      return;
    }
    if (identity == null) {
      if (generation != _watchGeneration) return;
      schedules.clear();
      _activeIdentityKey = null;
      availability.value = GameScheduleAvailability.awaitingPublication;
      return;
    }
    final configuredContract = identity.contractAddress;
    final configuredManager = identity.managerAddress;

    final identityKey = '$chainId:$configuredContract:$configuredManager';
    if (_activeIdentityKey != identityKey) {
      schedules.clear();
      _activeIdentityKey = identityKey;
    }

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

  Future<_RoundIdentity?> _resolveRoundIdentity() async {
    final config = Get.find<AppConfigService>();
    var contract = config.get('easyGameContractAddress').toLowerCase();
    var manager = config.get('roundManagerAddress').toLowerCase();

    if (contract.isNotEmpty && !_isContractAddress(contract)) {
      throw FormatException('Invalid core address: $contract');
    }
    if (manager.isNotEmpty && !_isContractAddress(manager)) {
      throw FormatException('Invalid round manager address: $manager');
    }

    if (contract.isEmpty) {
      try {
        contract =
            (await _walletService.resolveEasyGameAddress()).toLowerCase();
      } catch (_) {
        // A compatible core has not been published for this network yet.
      }
    }
    if (manager.isEmpty) {
      try {
        manager =
            (await _walletService.resolveRoundManagerAddress()).toLowerCase();
      } catch (_) {
        // A compatible round manager has not been published yet.
      }
    }
    if (contract.isEmpty || manager.isEmpty) {
      return null;
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
      availability.value = GameScheduleAvailability.failed;
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
    availability.value = accepted.isEmpty
        ? GameScheduleAvailability.awaitingPublication
        : GameScheduleAvailability.ready;
    errorMessage.value = '';
  }

  bool _isContractAddress(String value) =>
      RegExp(r'^0x[0-9a-f]{40}$').hasMatch(value) &&
      value != '0x0000000000000000000000000000000000000000';

  @override
  void onClose() {
    _watchGeneration++;
    _chainWorker?.dispose();
    _configWorker?.dispose();
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
