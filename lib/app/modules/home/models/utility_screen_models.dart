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

  const _MatrixArenaSnapshot({
    required this.level,
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
  });

  factory _MatrixArenaSnapshot.empty(int level) {
    return _MatrixArenaSnapshot(
      level: level,
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
    );
  }

  double get fillPercent {
    if (activeCells == BigInt.zero) {
      return 0;
    }
    final slots = BigInt.one << level;
    return activeCells.toDouble() / slots.toDouble() * 100;
  }
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
