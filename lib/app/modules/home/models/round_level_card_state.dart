import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/player_progression_models.dart';

enum RoundLevelCardViewMode {
  awaiting,
  activation,
  active,
  completed,
  skipped,
  frozen,
  paused,
  cancelled,
}

class RoundLevelCardState {
  final int level;
  final GameRoundViewState? round;
  final RoundMatrixStats? matrix;
  final RoundPlayerState? player;
  final ArenaSkillStatus? arenaStatus;
  final PlayerSeasonProgress? seasonProgress;
  final RoundEntryEligibility? entryEligibility;
  final bool? contractLevelAvailable;
  final bool? didWin;

  const RoundLevelCardState({
    required this.level,
    this.round,
    this.matrix,
    this.player,
    this.arenaStatus,
    this.seasonProgress,
    this.entryEligibility,
    this.contractLevelAvailable,
    this.didWin,
  });

  RoundLevelCardState copyWith({
    int? level,
    GameRoundViewState? round,
    RoundMatrixStats? matrix,
    RoundPlayerState? player,
    ArenaSkillStatus? arenaStatus,
    PlayerSeasonProgress? seasonProgress,
    RoundEntryEligibility? entryEligibility,
    bool? contractLevelAvailable,
    bool? didWin,
  }) {
    return RoundLevelCardState(
      level: level ?? this.level,
      round: round ?? this.round,
      matrix: matrix ?? this.matrix,
      player: player ?? this.player,
      arenaStatus: arenaStatus ?? this.arenaStatus,
      seasonProgress: seasonProgress ?? this.seasonProgress,
      entryEligibility: entryEligibility ?? this.entryEligibility,
      contractLevelAvailable: contractLevelAvailable ?? this.contractLevelAvailable,
      didWin: didWin ?? this.didWin,
    );
  }

  BigInt get roundId => BigInt.from(round?.schedule.roundId ?? 0);
  BigInt get ethPriceWei => round?.ethPriceWei ?? BigInt.zero;
  BigInt get usdcPrice => round?.usdcPrice ?? BigInt.zero;
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
  bool get isEmergencyPaused => contractLevelAvailable == false;
  BigInt get _occupiedCells =>
      round?.chainState?.occupiedCells ?? activeCells;
  bool get isFull =>
      round != null &&
      _occupiedCells >= BigInt.from(round!.schedule.maxPlayers);
  bool get canEnter =>
      round?.canEnter == true &&
      contractLevelAvailable == true &&
      entryEligibility?.canEnter != false &&
      !isFull;
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

  double get fillPercent {
    final capacity = round?.schedule.maxPlayers ?? 0;
    if (capacity <= 0 || activeCells <= BigInt.zero) return 0;
    return (activeCells.toDouble() / capacity * 100).clamp(0, 100).toDouble();
  }

  BigInt get playerWeightShareBps {
    if (playerWeight <= BigInt.zero || totalWeight <= BigInt.zero) {
      return BigInt.zero;
    }
    return (playerWeight * BigInt.from(10000)) ~/ totalWeight;
  }

  RoundLevelCardViewMode resolveViewMode() {
    final r = round;
    if (r == null) return RoundLevelCardViewMode.awaiting;

    switch (r.phase) {
      case GameRoundPhase.paused:
        return RoundLevelCardViewMode.paused;
      case GameRoundPhase.cancelled:
        return RoundLevelCardViewMode.cancelled;
      case GameRoundPhase.scheduled:
        return RoundLevelCardViewMode.awaiting;
      case GameRoundPhase.open:
        if (isFrozen) return RoundLevelCardViewMode.frozen;
        if (isPlayerActive) return RoundLevelCardViewMode.active;
        return RoundLevelCardViewMode.activation;
      case GameRoundPhase.locked:
        if (isFrozen) return RoundLevelCardViewMode.frozen;
        if (isPlayerActive) return RoundLevelCardViewMode.active;
        return RoundLevelCardViewMode.awaiting;
      case GameRoundPhase.settlementReady:
        if (isFrozen) return RoundLevelCardViewMode.frozen;
        if (isPlayerActive) return RoundLevelCardViewMode.active;
        return RoundLevelCardViewMode.awaiting;
      case GameRoundPhase.settled:
        if (isFrozen) return RoundLevelCardViewMode.frozen;
        if (isPlayerActive) return RoundLevelCardViewMode.completed;
        return RoundLevelCardViewMode.awaiting;
      case GameRoundPhase.uninitialized:
        return RoundLevelCardViewMode.awaiting;
    }
  }
}
