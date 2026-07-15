import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';

enum RoundLevelPlayerStatus {
  unavailable,
  available,
  active,
  frozen,
  completed
}

class ContractLevelPrice {
  final BigInt ethPriceWei;
  final BigInt usdcPrice;

  const ContractLevelPrice({
    required this.ethPriceWei,
    required this.usdcPrice,
  });
}

class RoundLevelCardState {
  final int level;
  final GameRoundViewState? round;
  final RoundMatrixStats? matrix;
  final RoundPlayerState? player;
  final BigInt? contractEthPriceWei;
  final BigInt? contractUsdcPrice;
  final bool? contractLevelAvailable;
  final String? errorMessage;

  const RoundLevelCardState({
    required this.level,
    this.round,
    this.matrix,
    this.player,
    this.contractEthPriceWei,
    this.contractUsdcPrice,
    this.contractLevelAvailable,
    this.errorMessage,
  });

  BigInt get roundId => BigInt.from(round?.schedule.roundId ?? 0);
  BigInt get ethPriceWei =>
      round?.ethPriceWei ?? contractEthPriceWei ?? BigInt.zero;
  BigInt get usdcPrice => round?.usdcPrice ?? contractUsdcPrice ?? BigInt.zero;
  BigInt get prizePoolWei => matrix?.prizePoolEth ?? BigInt.zero;
  BigInt get prizePoolUsdc => matrix?.prizePoolUsdc ?? BigInt.zero;
  BigInt get totalWeight => matrix?.totalWeight ?? BigInt.zero;
  BigInt get activeCells => matrix?.activeCells ?? BigInt.zero;
  BigInt get positionId => player?.cellId ?? BigInt.zero;
  BigInt get cycles => player?.cycleCount ?? BigInt.zero;
  BigInt get playerWeight => player?.totalWeight ?? BigInt.zero;

  bool get isPlayerActive => player?.active == true;
  bool get isFrozen => player?.frozen == true;
  bool get hasRound => round != null;
  bool get hasError => errorMessage?.isNotEmpty == true;
  bool get isEmergencyPaused => contractLevelAvailable == false;
  bool get canEnter =>
      round?.canEnter == true && contractLevelAvailable == true;

  RoundLevelPlayerStatus get playerStatus {
    if (!hasRound) return RoundLevelPlayerStatus.unavailable;
    if (isEmergencyPaused) return RoundLevelPlayerStatus.unavailable;
    if (isFrozen) return RoundLevelPlayerStatus.frozen;
    if (isPlayerActive && round!.phase == GameRoundPhase.settled) {
      return RoundLevelPlayerStatus.completed;
    }
    if (isPlayerActive) return RoundLevelPlayerStatus.active;
    return canEnter
        ? RoundLevelPlayerStatus.available
        : RoundLevelPlayerStatus.unavailable;
  }

  double get fillPercent {
    final capacity = round?.schedule.maxPlayers ?? 0;
    if (capacity <= 0 || activeCells <= BigInt.zero) return 0;
    return (activeCells.toDouble() / capacity * 100).clamp(0, 100).toDouble();
  }

  BigInt get playerChanceBps {
    if (playerWeight <= BigInt.zero || totalWeight <= BigInt.zero) {
      return BigInt.zero;
    }
    return (playerWeight * BigInt.from(10000)) ~/ totalWeight;
  }
}
