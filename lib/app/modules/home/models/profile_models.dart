part of '../views/profilescreen.dart';

class _ProfileDashboardSnapshot {
  final String contractAddress;
  final EasyGamePlayerSummary? player;
  final List<_ProfileLevelState> levels;
  final int activeCount;
  final int frozenCount;
  final BigInt totalEarnedWei;
  final BigInt totalPrizePoolWei;
  final BigInt totalActiveCells;
  final BigInt totalWeight;

  const _ProfileDashboardSnapshot({
    required this.contractAddress,
    required this.player,
    required this.levels,
    required this.activeCount,
    required this.frozenCount,
    required this.totalEarnedWei,
    required this.totalPrizePoolWei,
    required this.totalActiveCells,
    required this.totalWeight,
  });

  factory _ProfileDashboardSnapshot.empty() {
    return _ProfileDashboardSnapshot(
      contractAddress: '0x0000000000000000000000000000000000000000',
      player: null,
      levels: [],
      activeCount: 0,
      frozenCount: 0,
      totalEarnedWei: BigInt.zero,
      totalPrizePoolWei: BigInt.zero,
      totalActiveCells: BigInt.zero,
      totalWeight: BigInt.zero,
    );
  }

  BigInt get claimableWei {
    final summary = player;
    if (summary == null) {
      return BigInt.zero;
    }
    return summary.claimablePrizeWei + summary.claimableReferralBonusWei;
  }

  BigInt get claimablePrizeWei => player?.claimablePrizeWei ?? BigInt.zero;
  BigInt get referralBonusWei =>
      player?.claimableReferralBonusWei ?? BigInt.zero;
  BigInt get pendingWei => player?.pendingPrizeWei ?? BigInt.zero;
  BigInt get tickets => player?.totalTickets ?? BigInt.zero;
  BigInt get boxTokens => player?.boxTokens ?? BigInt.zero;
  BigInt get recycleCount => player?.recycleCount ?? BigInt.zero;
  BigInt get baseWeight => player?.baseWeight ?? BigInt.zero;
  BigInt get referralWeight => player?.referralWeight ?? BigInt.zero;
  BigInt get matrixWeight => player?.matrixWeight ?? BigInt.zero;
  BigInt get nftWeight => player?.nftWeight ?? BigInt.zero;
}

class _ProfileLevelState {
  final int level;
  final EasyGameLevelState state;
  final EasyGameAdvanceLevelStats? stats;
  final BigInt priceWei;
  final bool available;

  const _ProfileLevelState({
    required this.level,
    required this.state,
    required this.stats,
    required this.priceWei,
    required this.available,
  });
}

String _shortAddress(String address) {
  if (address.length <= 12) {
    return address;
  }
  return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}
