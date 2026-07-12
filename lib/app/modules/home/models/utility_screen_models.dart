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

class _TreeNodeSpec {
  final int cellId;
  final Offset position;

  const _TreeNodeSpec(this.cellId, this.position);
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
  final _MatrixSkillRules skillRules;
  final List<MatrixParticipant> participants;
  final ArenaSkillStatus? playerSkillStatus;
  final SettlementClaimable settlementClaimable;
  final bool canSettle;
  final bool roundSettled;

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
    required this.skillRules,
    required this.participants,
    required this.playerSkillStatus,
    required this.settlementClaimable,
    required this.canSettle,
    required this.roundSettled,
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
      skillRules: _MatrixSkillRules.empty(),
      participants: const [],
      playerSkillStatus: null,
      settlementClaimable: SettlementClaimable.zero,
      canSettle: false,
      roundSettled: false,
    );
  }

  double get fillPercent {
    if (activeCells == BigInt.zero) {
      return 0;
    }
    final slots = BigInt.one << level;
    return activeCells.toDouble() / slots.toDouble() * 100;
  }

  MatrixParticipant? participantAt(int cellId) {
    for (final participant in participants) {
      if (participant.cellId == BigInt.from(cellId)) return participant;
    }
    return null;
  }
}

class _MatrixSkillRules {
  final int roundHours;
  final int freezeLimit;
  final int freezeHitsTaken;
  final double freezePriceUsd;
  final double unfreezeBaseUsd;
  final BigInt unfreezePrizeWei;

  const _MatrixSkillRules({
    required this.roundHours,
    required this.freezeLimit,
    required this.freezeHitsTaken,
    required this.freezePriceUsd,
    required this.unfreezeBaseUsd,
    required this.unfreezePrizeWei,
  });

  factory _MatrixSkillRules.fromArena({
    required BigInt prizePoolWei,
    required bool playerFrozen,
    int freezeLimit = 10,
    int freezeHitsTaken = 0,
    int roundHours = 24,
  }) {
    return _MatrixSkillRules(
      roundHours: roundHours,
      freezeLimit: freezeLimit,
      freezeHitsTaken: freezeHitsTaken,
      freezePriceUsd: 0.30,
      unfreezeBaseUsd: 1,
      unfreezePrizeWei: prizePoolWei * BigInt.from(7) ~/ BigInt.from(100),
    );
  }

  factory _MatrixSkillRules.empty() {
    return _MatrixSkillRules(
      roundHours: 24,
      freezeLimit: 10,
      freezeHitsTaken: 0,
      freezePriceUsd: 0.30,
      unfreezeBaseUsd: 1,
      unfreezePrizeWei: BigInt.zero,
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

class _MemberPreviewSnapshot {
  final String query;
  final String normalizedAddress;
  final List<EasyGameLevelState> levels;

  const _MemberPreviewSnapshot({
    required this.query,
    required this.normalizedAddress,
    required this.levels,
  });

  bool get isWallet => normalizedAddress.isNotEmpty;

  int get activeCount => levels.where((state) => state.active).length;

  int get frozenCount => levels.where((state) => state.frozen).length;

  BigInt get earnedWei => levels.fold<BigInt>(
        BigInt.zero,
        (sum, state) => sum + state.earnedWei,
      );
}

class _InfoSplitRow {
  final String percent;
  final String label;
  final Color color;
  final double ratio;

  const _InfoSplitRow(this.percent, this.label, this.color, this.ratio);
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

  const _InfoResource(this.icon, this.title, this.text, this.color);
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
