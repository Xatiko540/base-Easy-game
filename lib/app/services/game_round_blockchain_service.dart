import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/services/game_schedule_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class GameRoundBlockchainService extends GetxService {
  static const Duration refreshInterval = Duration(minutes: 2);
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
      refreshInterval,
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
      final selected = _selectRelevantRounds(
        _scheduleService.schedules,
        DateTime.now().toUtc(),
      );
      final next = <int, GameRoundChainState>{};
      final errors = <String>[];
      for (var offset = 0; offset < selected.length; offset += 6) {
        if (run != _refreshRun) return;
        final end = offset + 6 < selected.length ? offset + 6 : selected.length;
        final batch = selected.sublist(offset, end);
        final results = await Future.wait(batch.map((schedule) async {
          try {
            final state = await _walletService.getEasyGameRoundState(schedule);
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

  List<GameRoundSchedule> _selectRelevantRounds(
    Iterable<GameRoundSchedule> schedules,
    DateTime now,
  ) {
    final byLevel = <int, List<GameRoundSchedule>>{};
    for (final schedule in schedules) {
      byLevel.putIfAbsent(schedule.level, () => []).add(schedule);
    }

    final selected = <GameRoundSchedule>[];
    for (final candidates in byLevel.values) {
      candidates.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      final running = candidates.where(
        (round) => !now.isBefore(round.startsAt) && now.isBefore(round.endsAt),
      );
      if (running.isNotEmpty) {
        selected.add(running.last);
        continue;
      }

      final upcoming = candidates.where((round) => round.startsAt.isAfter(now));
      if (upcoming.isNotEmpty) {
        selected.add(upcoming.first);
        continue;
      }

      final finished = candidates.where((round) => !round.endsAt.isAfter(now));
      if (finished.isNotEmpty) selected.add(finished.last);
    }
    selected.sort((a, b) => a.level.compareTo(b.level));
    return selected;
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    _scheduleWorker?.dispose();
    _chainWorker?.dispose();
    super.onClose();
  }
}
