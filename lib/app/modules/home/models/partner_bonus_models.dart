import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class PartnerArenaSnapshot {
  final BigInt totalTickets;
  final BigInt baseWeight;
  final BigInt referralWeight;
  final BigInt totalWeight;
  final BigInt claimableReferralBonusWei;
  final BigInt claimableReferralBonusUsdc;
  final BigInt boxTokens;
  final BigInt recycleCount;
  final String inviter;
  final BigInt loyaltyWeight;
  final BigInt matrixWeight;
  final int paymentSplitVersion;

  PartnerArenaSnapshot({EasyGamePlayerSummary? player, this.paymentSplitVersion = 1})
      : totalTickets = player?.totalTickets ?? BigInt.zero,
        baseWeight = player?.baseWeight ?? BigInt.zero,
        referralWeight = player?.referralWeight ?? BigInt.zero,
        totalWeight = player?.totalWeight ?? BigInt.zero,
        claimableReferralBonusWei =
            player?.claimableReferralBonusWei ?? BigInt.zero,
        claimableReferralBonusUsdc =
            player?.claimableReferralBonusUsdc ?? BigInt.zero,
        boxTokens = player?.boxTokens ?? BigInt.zero,
        recycleCount = player?.recycleCount ?? BigInt.zero,
        inviter = player?.inviter ?? '',
        loyaltyWeight = player?.loyaltyWeight ?? BigInt.zero,
        matrixWeight = player?.matrixWeight ?? BigInt.zero;

  factory PartnerArenaSnapshot.empty() => PartnerArenaSnapshot();
}

String formatPartnerWei(BigInt wei, {int decimals = 4}) {
  final base = BigInt.from(10).pow(18);
  final whole = wei ~/ base;
  final fraction = (wei % base).toString().padLeft(18, '0');
  final clipped = fraction.substring(0, decimals);
  final trimmed = clipped.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
}

String formatPartnerUsdc(BigInt usdc, {int decimals = 2}) {
  final base = BigInt.from(10).pow(6);
  final whole = usdc ~/ base;
  final fraction = (usdc % base).toString().padLeft(6, '0');
  final clipped = fraction.substring(0, decimals);
  final trimmed = clipped.replaceFirst(RegExp(r'0+$'), '');
  return trimmed.isEmpty ? whole.toString() : '$whole.$trimmed';
}
