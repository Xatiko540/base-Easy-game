import 'package:get/get.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';

String roundPhaseTranslationKey(GameRoundPhase phase) {
  switch (phase) {
    case GameRoundPhase.uninitialized:
      return 'round.uninitialized';
    case GameRoundPhase.scheduled:
      return 'round.scheduled';
    case GameRoundPhase.open:
      return 'round.open';
    case GameRoundPhase.locked:
      return 'round.locked';
    case GameRoundPhase.settlementReady:
      return 'round.settlementReady';
    case GameRoundPhase.settled:
      return 'round.settled';
    case GameRoundPhase.cancelled:
      return 'round.cancelled';
    case GameRoundPhase.paused:
      return 'round.paused';
  }
}

String formatRoundStart(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}

String formatRoundCompactDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)} '
      '${two(local.hour)}:${two(local.minute)}';
}

String localizedRoundCountdown(GameRoundViewState round) {
  return formatRoundCardCountdown(
    round.remaining,
    dayUnit: 'time.dayShort'.tr,
    hourUnit: 'time.hourShort'.tr,
    minuteUnit: 'time.minuteShort'.tr,
    secondUnit: 'time.secondShort'.tr,
  );
}

String localizedRoundScheduleRange(GameRoundSchedule schedule) {
  return 'round.scheduleRange'.trParams({
    'start': formatRoundStart(schedule.startsAt),
    'end': formatRoundStart(schedule.endsAt),
  });
}

String formatRoundCardCountdown(
  Duration duration, {
  required String dayUnit,
  required String hourUnit,
  required String minuteUnit,
  required String secondUnit,
}) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final days = safe.inDays;
  final seconds = safe.inSeconds.remainder(60);

  // Keep the same hierarchy as the original level cards: long waits are
  // expressed in days, while shorter waits keep their total hour count.
  if (safe.inHours >= 72) {
    return '$days $dayUnit';
  }
  if (safe.inHours > 0) {
    return '${safe.inHours} $hourUnit';
  }
  if (safe.inMinutes > 0) {
    return '${safe.inMinutes} $minuteUnit '
        '${seconds.toString().padLeft(2, '0')} $secondUnit';
  }
  return '${safe.inSeconds} $secondUnit';
}
