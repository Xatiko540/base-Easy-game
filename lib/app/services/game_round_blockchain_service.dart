import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/services/game_schedule_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class GameRoundBlockchainService extends GetxService {
  final WalletConnectService _walletService = Get.find<WalletConnectService>();
  final GameScheduleService _scheduleService = Get.find<GameScheduleService>();

  final RxMap<int, GameRoundChainState> states =
      <int, GameRoundChainState>{}.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  Timer? _refreshTimer;
  Worker? _scheduleWorker;
  Worker? _chainWorker;
  int _refreshRun = 0;

  GameRoundBlockchainService bind() {
    _scheduleWorker ??= ever<List<GameRoundSchedule>>(
      _scheduleService.schedules,
      (_) => refreshAll(),
    );
    _chainWorker ??= ever<int?>(_walletService.chainId, (_) {
      states.clear();
      _refreshRun++;
      refreshAll();
    });
    _refreshTimer ??= Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshAll(),
    );
    return this;
  }

  Future<void> refreshAll() async {
    if (isRefreshing.value) return;
    if (_scheduleService.schedules.isEmpty) {
      states.clear();
      return;
    }
    final run = ++_refreshRun;
    isRefreshing.value = true;
    try {
      final cutoff = DateTime.now().toUtc().subtract(const Duration(days: 1));
      final relevant = _scheduleService.schedules
          .where((round) => round.endsAt.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      final selected = relevant.take(34).toList();
      final next = <int, GameRoundChainState>{};
      final errors = <String>[];
      for (var offset = 0; offset < selected.length; offset += 6) {
        if (run != _refreshRun) return;
        final end = offset + 6 < selected.length ? offset + 6 : selected.length;
        final batch = selected.sublist(offset, end);
        final results = await Future.wait(batch.map((schedule) async {
          try {
            final state = await _walletService.getEasyGameRoundState(
              BigInt.from(schedule.roundId),
            );
            return MapEntry(schedule.roundId, state);
          } catch (error) {
            errors.add('${schedule.roundId}: $error');
            return null;
          }
        }));
        for (final result in results) {
          if (result != null) next[result.key] = result.value;
        }
      }
      if (run != _refreshRun) return;
      states.assignAll(next);
      errorMessage.value = errors.isEmpty ? '' : errors.join('\n');
    } catch (error) {
      errorMessage.value = '$error';
      if (kDebugMode) {
        debugPrint('GameRoundBlockchainService refresh failed: $error');
      }
    } finally {
      if (run == _refreshRun) isRefreshing.value = false;
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _scheduleWorker?.dispose();
    _chainWorker?.dispose();
    super.onClose();
  }
}
