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
      selected[level] = candidates.reduce(
        (a, b) => a.schedule.seasonId > b.schedule.seasonId ? a : b,
      );
    }
    roundsByLevel.assignAll(selected);

    final newIds = <int, int>{
      for (final entry in selected.entries)
        entry.key: entry.value.schedule.roundId,
    };
    if (!_mapEquals(selectedRoundIds, newIds)) {
      selectedRoundIds.assignAll(newIds);
    }
  }

  static bool _mapEquals(Map<int, int> a, Map<int, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  void onClose() {
    _scheduleWorker?.dispose();
    _clockWorker?.dispose();
    _chainStateWorker?.dispose();
    super.onClose();
  }
}
