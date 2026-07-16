import 'package:lottery_advance/app/models/game_round_phase.dart';

class GameRoundChainState {
  final BigInt roundId;
  final String configHash;
  final DateTime? initializedAt;
  final BigInt occupiedCells;
  final BigInt winnersRegistered;
  final bool initialized;
  final bool settled;
  final bool cancelled;
  final bool paused;
  final BigInt prizePoolEth;
  final BigInt prizePoolUsdc;
  final BigInt ethPriceWei;
  final BigInt usdcPrice;
  final GameRoundPhase phase;

  const GameRoundChainState({
    required this.roundId,
    required this.configHash,
    required this.initializedAt,
    required this.occupiedCells,
    required this.winnersRegistered,
    required this.initialized,
    required this.settled,
    required this.cancelled,
    required this.paused,
    required this.prizePoolEth,
    required this.prizePoolUsdc,
    required this.ethPriceWei,
    required this.usdcPrice,
    required this.phase,
  });
}
