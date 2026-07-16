import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/wallet_session_model.dart';

void main() {
  group('WalletSessionSnapshot', () {
    test('round-trips a Base Account session without auth secrets', () {
      const session = WalletSessionSnapshot(
        provider: WalletSessionProvider.baseAccount,
        address: '0x1111111111111111111111111111111111111111',
        chainId: 84532,
      );

      final json = session.toJson();
      final restored = WalletSessionSnapshot.fromJson(json);

      expect(restored.provider, WalletSessionProvider.baseAccount);
      expect(restored.address, session.address);
      expect(restored.chainId, 84532);
      expect(
          json.keys, containsAll(<String>['provider', 'address', 'chainId']));
      expect(json, isNot(contains('signature')));
      expect(json, isNot(contains('message')));
      expect(json, isNot(contains('nonce')));
    });

    test('rejects an unknown provider', () {
      expect(
        () => WalletSessionSnapshot.fromJson(<String, dynamic>{
          'provider': 'unknown',
          'address': '0x0',
          'chainId': 84532,
        }),
        throwsFormatException,
      );
    });
  });
}
