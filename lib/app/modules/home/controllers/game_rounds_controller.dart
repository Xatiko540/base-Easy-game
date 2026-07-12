import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/repositories/game_rounds_repository.dart';
import 'package:lottery_advance/app/services/game_clock_service.dart';
import 'package:lottery_advance/app/services/game_schedule_service.dart';

class GameRoundsController extends GetxController {
  final GameRoundsRepository _repository = Get.find<GameRoundsRepository>();
  final GameClockService _clockService = Get.find<GameClockService>();
  final GameScheduleService _scheduleService = Get.find<GameScheduleService>();

  RxMap<int, GameRoundViewState> get roundsByLevel => _repository.roundsByLevel;
  RxList<GameRoundViewState> get timeline => _repository.timeline;
  RxBool get isClockSynchronized => _clockService.isSynchronized;
  RxBool get isScheduleReady => _scheduleService.isReady;
  RxString get scheduleError => _scheduleService.errorMessage;

  GameRoundViewState? roundForLevel(int level) => roundsByLevel[level];

  GameRoundViewState? get nearestEvent {
    final active = timeline.where((item) =>
        item.phase == GameRoundPhase.open ||
        item.phase == GameRoundPhase.scheduled ||
        item.phase == GameRoundPhase.locked);
    return active.isEmpty ? null : active.first;
  }

  Future<void> refreshClock() => _clockService.synchronize();
}
