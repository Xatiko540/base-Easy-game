import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class PartnerArenaSnapshot {
  final BigInt totalTickets;
  final BigInt baseWeight;
  final BigInt referralWeight;
  final BigInt totalWeight;
  final BigInt claimableReferralBonusWei;

  PartnerArenaSnapshot({EasyGamePlayerSummary? player})
      : totalTickets = player?.totalTickets ?? BigInt.zero,
        baseWeight = player?.baseWeight ?? BigInt.zero,
        referralWeight = player?.referralWeight ?? BigInt.zero,
        totalWeight = player?.totalWeight ?? BigInt.zero,
        claimableReferralBonusWei =
            player?.claimableReferralBonusWei ?? BigInt.zero;

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
