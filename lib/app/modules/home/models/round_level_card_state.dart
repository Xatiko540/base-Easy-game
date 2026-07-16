import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';

enum RoundLevelPlayerStatus {
  unavailable,
  available,
  active,
  frozen,
  missed,
  progressionBlocked,
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
  final ArenaSkillStatus? arenaStatus;
  final PlayerSeasonProgress? seasonProgress;
  final RoundEntryEligibility? entryEligibility;
  final BigInt? contractEthPriceWei;
  final BigInt? contractUsdcPrice;
  final bool? contractLevelAvailable;
  final bool playerStateResolved;
  final String? errorMessage;

  const RoundLevelCardState({
    required this.level,
    this.round,
    this.matrix,
    this.player,
    this.arenaStatus,
    this.seasonProgress,
    this.entryEligibility,
    this.contractEthPriceWei,
    this.contractUsdcPrice,
    this.contractLevelAvailable,
    this.playerStateResolved = true,
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
  bool get isFrozen => arenaStatus?.frozen == true;
  bool get isImmune => arenaStatus?.immune == true;
  bool get hasRound => round != null;
  bool get hasError => errorMessage?.isNotEmpty == true;
  bool get isPlayerStatePending => !playerStateResolved;
  bool get isEmergencyPaused => contractLevelAvailable == false;
  bool get canEnter =>
      round?.canEnter == true &&
      contractLevelAvailable == true &&
      entryEligibility?.canEnter != false;
  bool get isMissed =>
      !isPlayerActive &&
      entryEligibility?.reason ==
          RoundEntryEligibilityReason.alreadyPurchasedOrLower;
  bool get isProgressionBlocked =>
      !isPlayerActive &&
      entryEligibility?.reason == RoundEntryEligibilityReason.nextLevelRequired;
  bool get isFrozenProgressionBlocked =>
      !isPlayerActive &&
      entryEligibility?.reason == RoundEntryEligibilityReason.frozen;
  int get requiredLevel => entryEligibility?.requiredLevel ?? 0;
  int get directInvites => seasonProgress?.directInvites ?? 0;
  int get inviteCapacity => seasonProgress?.inviteCapacity ?? 0;
  int get remainingInviteSlots => seasonProgress?.remainingInviteSlots ?? 0;

  RoundLevelPlayerStatus get playerStatus {
    if (!hasRound) return RoundLevelPlayerStatus.unavailable;
    if (isEmergencyPaused) return RoundLevelPlayerStatus.unavailable;
    if (isFrozen) return RoundLevelPlayerStatus.frozen;
    if (isMissed) return RoundLevelPlayerStatus.missed;
    if (isProgressionBlocked || isFrozenProgressionBlocked) {
      return RoundLevelPlayerStatus.progressionBlocked;
    }
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
