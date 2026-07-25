class RoundPaymentGasQuote {
  const RoundPaymentGasQuote({
    required this.gasUnits,
    required this.gasPriceWei,
    required this.feeReserveWei,
    required this.includesUsdcApproval,
  });

  final BigInt gasUnits;
  final BigInt gasPriceWei;
  final BigInt feeReserveWei;
  final bool includesUsdcApproval;

  BigInt requiredNativeWei({
    required BigInt ticketPriceWei,
    required bool paysWithUsdc,
  }) {
    return feeReserveWei + (paysWithUsdc ? BigInt.zero : ticketPriceWei);
  }

  static RoundPaymentGasQuote conservative({
    required BigInt gasUnits,
    required BigInt gasPriceWei,
    required bool includesUsdcApproval,
    int reserveBps = 12500,
  }) {
    if (gasUnits <= BigInt.zero || gasPriceWei <= BigInt.zero) {
      throw ArgumentError('Gas units and gas price must be positive.');
    }
    final fee =
        gasUnits * gasPriceWei * BigInt.from(reserveBps) ~/ BigInt.from(10000);
    return RoundPaymentGasQuote(
      gasUnits: gasUnits,
      gasPriceWei: gasPriceWei,
      feeReserveWei: fee,
      includesUsdcApproval: includesUsdcApproval,
    );
  }
}
