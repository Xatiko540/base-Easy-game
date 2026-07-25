import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_advance/app/models/round_payment_models.dart';

void main() {
  group('RoundPaymentGasQuote', () {
    test('adds the reserve margin to the network fee', () {
      final quote = RoundPaymentGasQuote.conservative(
        gasUnits: BigInt.from(100),
        gasPriceWei: BigInt.from(20),
        includesUsdcApproval: false,
      );

      expect(quote.feeReserveWei, BigInt.from(2500));
    });

    test('native payment requires ticket price plus gas reserve', () {
      final quote = RoundPaymentGasQuote(
        gasUnits: BigInt.from(100),
        gasPriceWei: BigInt.from(20),
        feeReserveWei: BigInt.from(2500),
        includesUsdcApproval: false,
      );

      expect(
        quote.requiredNativeWei(
          ticketPriceWei: BigInt.from(10000),
          paysWithUsdc: false,
        ),
        BigInt.from(12500),
      );
    });

    test('USDC payment requires only the native gas reserve in ETH', () {
      final quote = RoundPaymentGasQuote(
        gasUnits: BigInt.from(200),
        gasPriceWei: BigInt.from(20),
        feeReserveWei: BigInt.from(5000),
        includesUsdcApproval: true,
      );

      expect(
        quote.requiredNativeWei(
          ticketPriceWei: BigInt.from(10000),
          paysWithUsdc: true,
        ),
        BigInt.from(5000),
      );
    });
  });
}
