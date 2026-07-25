import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_chain_models.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/services/game_contract_events_service.dart';
import 'package:lottery_advance/app/services/game_schedule_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class GameRoundBlockchainService extends GetxService {
  final WalletConnectService _walletService = Get.find<WalletConnectService>();
  final GameScheduleService _scheduleService = Get.find<GameScheduleService>();
  final GameContractEventsService _eventsService =
      Get.find<GameContractEventsService>();

  final RxMap<int, GameRoundChainState> states =
      <int, GameRoundChainState>{}.obs;
  final RxBool isRefreshing = false.obs;
  final RxString errorMessage = ''.obs;

  Worker? _scheduleWorker;
  Worker? _chainWorker;
  Worker? _eventWorker;
  int _refreshRun = 0;
  Timer? _debounceTimer;
  StreamSubscription? _roundCacheSub;

  DateTime? _lastRefreshTrigger;

  GameRoundBlockchainService bind() {
    _scheduleWorker ??= ever<List<GameRoundSchedule>>(
      _scheduleService.schedules,
      (_) => _scheduleRefresh(),
    );
    _chainWorker ??= ever<int?>(_walletService.chainId, (_) {
      final now = DateTime.now();
      if (_lastRefreshTrigger != null &&
          now.difference(_lastRefreshTrigger!).inSeconds < 5) {
        return;
      }
      _lastRefreshTrigger = now;
      _scheduleRefresh();
    });
    _eventWorker ??= ever<int>(
      _eventsService.eventRevision,
      (_) => _scheduleRefresh(),
    );
    _listenRoundCache();
    if (_scheduleService.schedules.isNotEmpty) _scheduleRefresh();
    return this;
  }

  void _listenRoundCache() {
    try {
      _roundCacheSub = FirebaseFirestore.instance
          .collection('roundCache')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isEmpty) return;
        _walletService.clearRpcCache();
        _scheduleRefresh();
      }, onError: (error) {
        if (kDebugMode) {
          debugPrint('roundCache listener error: $error');
        }
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('roundCache init failed — Firebase not ready: $error');
      }
    }
  }

  void _scheduleRefresh() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), refreshAll);
  }

  Future<void> refreshAll() async {
    if (isRefreshing.value) return;
    if (_scheduleService.schedules.isEmpty) return;
    final run = ++_refreshRun;
    isRefreshing.value = true;
    try {
      final selected = _selectRelevantRounds(
        _scheduleService.schedules,
        DateTime.now().toUtc(),
      );
      final next = <int, GameRoundChainState>{};
      final errors = <String>[];
      for (final schedule in selected) {
        if (run != _refreshRun) return;
        try {
          final state = await _walletService.getEasyGameRoundState(schedule);
          next[schedule.roundId] = state;
        } catch (error) {
          errors.add('${schedule.roundId}: $error');
          final existing = states[schedule.roundId];
          if (existing != null) next[schedule.roundId] = existing;
        }
        await Future.delayed(const Duration(milliseconds: 300));
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
    final byLevel = <int, GameRoundSchedule>{};
    for (final schedule in schedules) {
      final key = schedule.level;
      final existing = byLevel[key];
      if (existing == null || schedule.seasonId > existing.seasonId) {
        byLevel[key] = schedule;
      }
    }
    final running = <GameRoundSchedule>[];
    final upcoming = <GameRoundSchedule>[];
    final finished = <GameRoundSchedule>[];
    for (final schedule in byLevel.values) {
      if (!now.isBefore(schedule.startsAt) && now.isBefore(schedule.endsAt)) {
        running.add(schedule);
      } else if (schedule.startsAt.isAfter(now)) {
        upcoming.add(schedule);
      } else {
        finished.add(schedule);
      }
    }
    final recentFinished = finished.where((r) {
      final age = now.difference(r.endsAt);
      return age.inDays < 7;
    }).toList();
    recentFinished.sort((a, b) => b.startsAt.compareTo(a.startsAt));
    return [
      ...running,
      if (upcoming.isNotEmpty)
        upcoming.reduce((a, b) => a.startsAt.isBefore(b.startsAt) ? a : b),
      if (recentFinished.length > 2) recentFinished[0]
      else ...recentFinished,
    ];
  }

  @override
  void onClose() {
    _debounceTimer?.cancel();
    _roundCacheSub?.cancel();
    _scheduleWorker?.dispose();
    _chainWorker?.dispose();
    _eventWorker?.dispose();
    super.onClose();
  }
}
