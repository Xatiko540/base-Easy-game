part of '../views/utility_screens.dart';

class _DistributionRow {
  final String label;
  final String percent;
  final Color color;
  final double ratio;

  const _DistributionRow(this.label, this.percent, this.color, this.ratio);
}

class _LegendItem {
  final String label;
  final Color color;
  final IconData icon;

  const _LegendItem(this.label, this.color, this.icon);
}

class _LevelArenaStat {
  final int level;
  final BigInt priceWei;
  final BigInt activeCells;
  final BigInt prizePoolWei;
  final BigInt totalWeight;

  const _LevelArenaStat({
    required this.level,
    required this.priceWei,
    required this.activeCells,
    required this.prizePoolWei,
    required this.totalWeight,
  });

  double get fillPercent {
    if (activeCells == BigInt.zero) {
      return 0;
    }
    final slots = BigInt.one << level;
    return (activeCells.toDouble() / slots.toDouble() * 100).clamp(0, 100);
  }
}

class _MatrixArenaSnapshot {
  final BigInt roundId;
  final int level;
  final BigInt priceWei;
  final BigInt activeCells;
  final BigInt totalWeight;
  final BigInt prizePoolWei;
  final BigInt nextCellId;
  final BigInt nextOpenParentId;
  final BigInt playerCellId;
  final bool playerActive;
  final bool playerFrozen;
  final BigInt recycleCount;
  final BigInt playerWeight;
  final BigInt chanceBps;
  final BigInt boxTokens;
  final int maxPlayers;
  final GameRoundPhase phase;
  final DateTime? freezeClosesAt;
  final bool freezeWindowOpen;
  final BigInt freezeTokenPriceUsdc;
  final _MatrixSkillRules skillRules;
  final List<MatrixParticipant> participants;
  final ArenaSkillStatus? playerSkillStatus;

  const _MatrixArenaSnapshot({
    required this.level,
    required this.roundId,
    required this.priceWei,
    required this.activeCells,
    required this.totalWeight,
    required this.prizePoolWei,
    required this.nextCellId,
    required this.nextOpenParentId,
    required this.playerCellId,
    required this.playerActive,
    required this.playerFrozen,
    required this.recycleCount,
    required this.playerWeight,
    required this.chanceBps,
    required this.boxTokens,
    required this.maxPlayers,
    required this.phase,
    required this.freezeClosesAt,
    required this.freezeWindowOpen,
    required this.freezeTokenPriceUsdc,
    required this.skillRules,
    required this.participants,
    required this.playerSkillStatus,
  });

  factory _MatrixArenaSnapshot.empty(int level) {
    return _MatrixArenaSnapshot(
      level: level,
      roundId: BigInt.zero,
      priceWei: BigInt.zero,
      activeCells: BigInt.zero,
      totalWeight: BigInt.zero,
      prizePoolWei: BigInt.zero,
      nextCellId: BigInt.zero,
      nextOpenParentId: BigInt.zero,
      playerCellId: BigInt.zero,
      playerActive: false,
      playerFrozen: false,
      recycleCount: BigInt.zero,
      playerWeight: BigInt.zero,
      chanceBps: BigInt.zero,
      boxTokens: BigInt.zero,
      maxPlayers: 0,
      phase: GameRoundPhase.uninitialized,
      freezeClosesAt: null,
      freezeWindowOpen: false,
      freezeTokenPriceUsdc: BigInt.zero,
      skillRules: _MatrixSkillRules.empty(),
      participants: const [],
      playerSkillStatus: null,
    );
  }

  double get fillPercent {
    if (activeCells == BigInt.zero) {
      return 0;
    }
    if (maxPlayers <= 0) return 0;
    return (activeCells.toDouble() / maxPlayers * 100).clamp(0, 100);
  }

  bool get canUseFreezeSkills => playerActive && freezeWindowOpen;

  MatrixParticipant? participantAt(int cellId) {
    for (final participant in participants) {
      if (participant.cellId == BigInt.from(cellId)) return participant;
    }
    return null;
  }
}

class _MatrixSkillRules {
  final int freezeLimit;
  final int freezeHitsTaken;

  const _MatrixSkillRules({
    required this.freezeLimit,
    required this.freezeHitsTaken,
  });

  factory _MatrixSkillRules.fromArena({
    int freezeLimit = 10,
    int freezeHitsTaken = 0,
  }) {
    return _MatrixSkillRules(
      freezeLimit: freezeLimit,
      freezeHitsTaken: freezeHitsTaken,
    );
  }

  factory _MatrixSkillRules.empty() {
    return _MatrixSkillRules(
      freezeLimit: 10,
      freezeHitsTaken: 0,
    );
  }

  int get freezesRemaining => math.max(0, freezeLimit - freezeHitsTaken);
}

class _StatisticsSnapshot {
  final String contractAddress;
  final int activeLevels;
  final int frozenLevels;
  final BigInt matrixNodes;
  final BigInt totalLevelCostWei;
  final BigInt totalPrizePoolWei;
  final BigInt totalWeight;
  final BigInt playerRewardsWei;
  final List<_LevelArenaStat> levelRows;

  const _StatisticsSnapshot({
    required this.contractAddress,
    required this.activeLevels,
    required this.frozenLevels,
    required this.matrixNodes,
    required this.totalLevelCostWei,
    required this.totalPrizePoolWei,
    required this.totalWeight,
    required this.playerRewardsWei,
    required this.levelRows,
  });
}

class _RoundStatisticsSample {
  final int level;
  final BigInt priceWei;
  final RoundMatrixStats matrix;
  final bool playerActive;
  final bool playerFrozen;

  const _RoundStatisticsSample({
    required this.level,
    required this.priceWei,
    required this.matrix,
    required this.playerActive,
    required this.playerFrozen,
  });
}

class _MemberPreviewRoundState {
  final bool active;
  final bool frozen;

  const _MemberPreviewRoundState({
    this.active = false,
    this.frozen = false,
  });
}

class _MemberPreviewSnapshot {
  final String query;
  final String normalizedAddress;
  final List<_MemberPreviewRoundState> rounds;
  final BigInt claimableEth;

  const _MemberPreviewSnapshot({
    required this.query,
    required this.normalizedAddress,
    required this.rounds,
    required this.claimableEth,
  });

  bool get isWallet => normalizedAddress.isNotEmpty;

  int get activeCount => rounds.where((state) => state.active).length;

  int get frozenCount => rounds.where((state) => state.frozen).length;

  BigInt get earnedWei => claimableEth;
}

class _InfoSplitRow {
  final String percent;
  final String label;
  final String description;
  final Color color;
  final double ratio;

  const _InfoSplitRow(
    this.percent,
    this.label,
    this.description,
    this.color,
    this.ratio,
  );
}

class _InfoFlowStep {
  final IconData icon;
  final String text;

  const _InfoFlowStep(this.icon, this.text);
}

class _InfoResource {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _InfoResource(
    this.icon,
    this.title,
    this.text,
    this.color,
  );
}

String _shortAddress(String address) {
  if (address.length <= 12) {
    return address;
  }
  return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}

String _formatWei(BigInt wei) {
  final base = BigInt.from(10).pow(18);
  final whole = wei ~/ base;
  final fraction = (wei % base).toString().padLeft(18, '0');
  final trimmedFraction =
      fraction.substring(0, 4).replaceFirst(RegExp(r'0+$'), '');
  if (trimmedFraction.isEmpty) {
    return whole.toString();
  }
  return '$whole.$trimmedFraction';
}

String _formatChance(BigInt bps) {
  final whole = bps ~/ BigInt.from(100);
  final fraction = (bps % BigInt.from(100)).toString().padLeft(2, '0');
  return '$whole.$fraction%';
}
