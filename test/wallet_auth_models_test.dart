import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/wallet_auth_models.dart';

void main() {
  group('WalletAuthSession', () {
    const session = WalletAuthSession(
      wallet: '0xeF9B7b298f821124c6c81D21e1cD99966a331a5A',
      chainId: 84532,
      firebaseUid: 'wallet_stable_hash',
    );

    test('matches the same wallet case-insensitively on the same chain', () {
      expect(
        session.matches(
          '0xef9b7b298f821124c6c81d21e1cd99966a331a5a',
          84532,
        ),
        isTrue,
      );
    });

    test('rejects another wallet or chain', () {
      expect(
        session.matches(
          '0x0000000000000000000000000000000000000001',
          84532,
        ),
        isFalse,
      );
      expect(
        session.matches(
          '0xeF9B7b298f821124c6c81D21e1cD99966a331a5A',
          8453,
        ),
        isFalse,
      );
    });
  });
}
