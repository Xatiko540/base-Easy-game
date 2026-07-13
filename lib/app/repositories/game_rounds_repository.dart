import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/services/game_clock_service.dart';
import 'package:lottery_advance/app/services/game_schedule_service.dart';
import 'package:lottery_advance/app/services/game_round_blockchain_service.dart';

class GameRoundsRepository extends GetxService {
  final GameScheduleService _scheduleService = Get.find<GameScheduleService>();
  final GameClockService _clockService = Get.find<GameClockService>();
  final GameRoundBlockchainService _blockchainService =
      Get.find<GameRoundBlockchainService>();

  final RxMap<int, GameRoundViewState> roundsByLevel =
      <int, GameRoundViewState>{}.obs;
  final RxMap<int, int> selectedRoundIds = <int, int>{}.obs;
  final RxList<GameRoundViewState> timeline = <GameRoundViewState>[].obs;

  Worker? _scheduleWorker;
  Worker? _clockWorker;
  Worker? _chainStateWorker;

  GameRoundsRepository bind() {
    _scheduleWorker ??= ever<List<GameRoundSchedule>>(
      _scheduleService.schedules,
      (_) => _rebuild(),
    );
    _clockWorker ??= ever<DateTime>(
      _clockService.chainTime,
      (_) => _rebuild(),
    );
    _chainStateWorker ??= ever(
      _blockchainService.states,
      (_) => _rebuild(),
    );
    _rebuild();
    return this;
  }

  void _rebuild() {
    final now = _clockService.chainTime.value;
    final states = _scheduleService.schedules
        .map((round) => GameRoundViewState.fromSchedule(
              round,
              now,
              _blockchainService.states[round.roundId],
            ))
        .toList()
      ..sort((a, b) => a.schedule.startsAt.compareTo(b.schedule.startsAt));
    timeline.assignAll(states);

    final selected = <int, GameRoundViewState>{};
    for (var level = 1; level <= 17; level++) {
      final candidates = states.where((item) => item.schedule.level == level);
      if (candidates.isEmpty) continue;
      selected[level] = candidates.reduce(_preferCurrentRound);
    }
    roundsByLevel.assignAll(selected);
    final nextIds = selected.map(
      (level, round) => MapEntry(level, round.schedule.roundId),
    );
    if (!_sameRoundIds(selectedRoundIds, nextIds)) {
      selectedRoundIds.assignAll(nextIds);
    }
  }

  bool _sameRoundIds(Map<int, int> current, Map<int, int> next) {
    if (current.length != next.length) return false;
    for (final entry in next.entries) {
      if (current[entry.key] != entry.value) return false;
    }
    return true;
  }

  GameRoundViewState _preferCurrentRound(
    GameRoundViewState current,
    GameRoundViewState candidate,
  ) {
    final currentRank = _phaseRank(current.phase);
    final candidateRank = _phaseRank(candidate.phase);
    if (candidateRank != currentRank) {
      return candidateRank < currentRank ? candidate : current;
    }
    if (candidate.phase == GameRoundPhase.settled) {
      return candidate.schedule.endsAt.isAfter(current.schedule.endsAt)
          ? candidate
          : current;
    }
    return candidate.schedule.startsAt.isBefore(current.schedule.startsAt)
        ? candidate
        : current;
  }

  int _phaseRank(GameRoundPhase phase) {
    switch (phase) {
      case GameRoundPhase.open:
        return 0;
      case GameRoundPhase.locked:
        return 1;
      case GameRoundPhase.settlementReady:
        return 2;
      case GameRoundPhase.scheduled:
        return 3;
      case GameRoundPhase.paused:
        return 4;
      case GameRoundPhase.settled:
        return 5;
      case GameRoundPhase.cancelled:
        return 6;
      case GameRoundPhase.uninitialized:
        return 7;
    }
  }

  @override
  void onClose() {
    _scheduleWorker?.dispose();
    _clockWorker?.dispose();
    _chainStateWorker?.dispose();
    super.onClose();
  }
}
