import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/modules/home/models/profile_session_model.dart';

void main() {
  group('resolveProfileSessionStatus', () {
    test('reports disconnected without a wallet session', () {
      expect(
        resolveProfileSessionStatus(
          walletConnected: false,
          playerExists: true,
        ),
        ProfileSessionStatus.disconnected,
      );
    });

    test('keeps connected wallet separate from game registration', () {
      expect(
        resolveProfileSessionStatus(
          walletConnected: true,
          playerExists: false,
        ),
        ProfileSessionStatus.connected,
      );
    });

    test('reports registered only after on-chain player creation', () {
      expect(
        resolveProfileSessionStatus(
          walletConnected: true,
          playerExists: true,
        ),
        ProfileSessionStatus.registered,
      );
    });
  });
}
