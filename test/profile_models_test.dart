import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/modules/home/models/profile_models.dart';
import 'package:lottery_advance/app/modules/home/models/profile_session_model.dart';

void main() {
  group('resolveProfileSessionStatus', () {
    test('reports disconnected without a wallet session', () {
      expect(
        resolveProfileSessionStatus(
          walletAuthenticated: false,
          playerExists: true,
        ),
        ProfileSessionStatus.disconnected,
      );
    });

    test('keeps connected wallet separate from game registration', () {
      expect(
        resolveProfileSessionStatus(
          walletAuthenticated: true,
          playerExists: false,
        ),
        ProfileSessionStatus.connected,
      );
    });

    test('reports registered only after on-chain player creation', () {
      expect(
        resolveProfileSessionStatus(
          walletAuthenticated: true,
          playerExists: true,
        ),
        ProfileSessionStatus.registered,
      );
    });
  });

  group('ProfileDashboardSnapshot', () {
    test('keeps ETH and USDC prize pools separate', () {
      final snapshot = ProfileDashboardSnapshot.empty().copyWith(
        totalPrizePoolWei: BigInt.from(100000000000000),
        totalPrizePoolUsdc: BigInt.from(2500000),
      );

      expect(snapshot.totalPrizePoolWei, BigInt.from(100000000000000));
      expect(snapshot.totalPrizePoolUsdc, BigInt.from(2500000));
    });

    test('empty state never invents claimable balances', () {
      final snapshot = ProfileDashboardSnapshot.empty();

      expect(snapshot.claimableWei, BigInt.zero);
      expect(snapshot.referralBonusUsdc, BigInt.zero);
      expect(snapshot.totalPrizePoolWei, BigInt.zero);
      expect(snapshot.totalPrizePoolUsdc, BigInt.zero);
    });
  });
}
