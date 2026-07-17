import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/utils/wallet_balance_formatter.dart';

void main() {
  group('formatNativeBalanceWei', () {
    test('keeps a small Base Sepolia ETH balance visible', () {
      expect(
        formatNativeBalanceWei(BigInt.parse('300000000000000')),
        '0.0003',
      );
    });

    test('trims insignificant trailing zeroes', () {
      expect(
        formatNativeBalanceWei(BigInt.parse('1250000000000000000')),
        '1.25',
      );
    });

    test('does not render a positive sub-precision balance as zero', () {
      expect(formatNativeBalanceWei(BigInt.one), '<0.000001');
    });
  });
}
