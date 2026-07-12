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
