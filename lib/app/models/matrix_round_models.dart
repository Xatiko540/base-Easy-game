class RoundMatrixStats {
  final BigInt prizePoolEth;
  final BigInt prizePoolUsdc;
  final BigInt totalWeight;
  final BigInt activeCells;
  final BigInt nextCellId;
  final BigInt nextOpenParentId;

  const RoundMatrixStats({
    required this.prizePoolEth,
    required this.prizePoolUsdc,
    required this.totalWeight,
    required this.activeCells,
    required this.nextCellId,
    required this.nextOpenParentId,
  });
}

class RoundPlayerState {
  final bool active;
  final int level;
  final BigInt cellId;
  final BigInt cycleCount;
  final BigInt totalWeight;

  const RoundPlayerState({
    required this.active,
    required this.level,
    required this.cellId,
    required this.cycleCount,
    required this.totalWeight,
  });
}

class RoundMatrixNode {
  final BigInt cellId;
  final String player;
  final int level;
  final BigInt parentCellId;
  final BigInt leftChildCellId;
  final BigInt rightChildCellId;
  final bool closed;

  const RoundMatrixNode({
    required this.cellId,
    required this.player,
    required this.level,
    required this.parentCellId,
    required this.leftChildCellId,
    required this.rightChildCellId,
    required this.closed,
  });
}

class ArenaSkillStatus {
  final bool frozen;
  final bool immune;
  final DateTime? frozenUntil;
  final int freezeHits;
  final int freezeTokens;
  final BigInt unfreezePriceUsdc;

  const ArenaSkillStatus({
    required this.frozen,
    required this.immune,
    required this.frozenUntil,
    required this.freezeHits,
    required this.freezeTokens,
    required this.unfreezePriceUsdc,
  });
}

class MatrixParticipant {
  final BigInt cellId;
  final String wallet;
  final bool isCurrentPlayer;
  final bool isInvited;
  final ArenaSkillStatus? skillStatus;

  const MatrixParticipant({
    required this.cellId,
    required this.wallet,
    required this.isCurrentPlayer,
    required this.isInvited,
    this.skillStatus,
  });
}
