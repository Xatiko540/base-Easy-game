import 'package:lottery_advance/app/models/game_transaction_model.dart';
import 'package:lottery_advance/app/modules/home/models/round_level_card_state.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class ProfileDashboardSnapshot {
  final String contractAddress;
  final EasyGamePlayerSummary? player;
  final List<RoundLevelCardState> levels;
  final List<GameTransaction> transactions;
  final int activeCount;
  final int frozenCount;
  final BigInt totalEarnedWei;
  final BigInt totalPrizePoolWei;
  final BigInt totalActiveCells;
  final BigInt totalWeight;
  final BigInt settlementPrizeWei;
  final BigInt settlementPrizeUsdc;

  const ProfileDashboardSnapshot({
    required this.contractAddress,
    required this.player,
    required this.levels,
    required this.transactions,
    required this.activeCount,
    required this.frozenCount,
    required this.totalEarnedWei,
    required this.totalPrizePoolWei,
    required this.totalActiveCells,
    required this.totalWeight,
    required this.settlementPrizeWei,
    required this.settlementPrizeUsdc,
  });

  factory ProfileDashboardSnapshot.empty() {
    return ProfileDashboardSnapshot(
      contractAddress: '0x0000000000000000000000000000000000000000',
      player: null,
      levels: [],
      transactions: [],
      activeCount: 0,
      frozenCount: 0,
      totalEarnedWei: BigInt.zero,
      totalPrizePoolWei: BigInt.zero,
      totalActiveCells: BigInt.zero,
      totalWeight: BigInt.zero,
      settlementPrizeWei: BigInt.zero,
      settlementPrizeUsdc: BigInt.zero,
    );
  }

  ProfileDashboardSnapshot copyWith({
    String? contractAddress,
    EasyGamePlayerSummary? player,
    List<RoundLevelCardState>? levels,
    List<GameTransaction>? transactions,
    int? activeCount,
    int? frozenCount,
    BigInt? totalEarnedWei,
    BigInt? totalPrizePoolWei,
    BigInt? totalActiveCells,
    BigInt? totalWeight,
    BigInt? settlementPrizeWei,
    BigInt? settlementPrizeUsdc,
  }) {
    return ProfileDashboardSnapshot(
      contractAddress: contractAddress ?? this.contractAddress,
      player: player ?? this.player,
      levels: levels ?? this.levels,
      transactions: transactions ?? this.transactions,
      activeCount: activeCount ?? this.activeCount,
      frozenCount: frozenCount ?? this.frozenCount,
      totalEarnedWei: totalEarnedWei ?? this.totalEarnedWei,
      totalPrizePoolWei: totalPrizePoolWei ?? this.totalPrizePoolWei,
      totalActiveCells: totalActiveCells ?? this.totalActiveCells,
      totalWeight: totalWeight ?? this.totalWeight,
      settlementPrizeWei: settlementPrizeWei ?? this.settlementPrizeWei,
      settlementPrizeUsdc: settlementPrizeUsdc ?? this.settlementPrizeUsdc,
    );
  }

  BigInt get claimableWei => settlementPrizeWei + referralBonusWei;

  BigInt get claimablePrizeWei => settlementPrizeWei;
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

String shortProfileAddress(String address) {
  if (address.length <= 12) {
    return address;
  }
  return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
}
