String formatNativeBalanceWei(BigInt wei, {int decimals = 6}) {
  final negative = wei < BigInt.zero;
  final value = negative ? -wei : wei;
  final divisor = BigInt.from(10).pow(18);
  final whole = value ~/ divisor;
  final fraction = value % divisor;
  if (fraction == BigInt.zero || decimals <= 0) {
    return '${negative ? '-' : ''}$whole';
  }

  final padded = fraction.toString().padLeft(18, '0');
  final clipped =
      padded.substring(0, decimals).replaceFirst(RegExp(r'0+$'), '');
  if (clipped.isEmpty) {
    if (value != BigInt.zero) {
      final leadingZeros = ''.padRight(decimals - 1, '0');
      return '${negative ? '-' : ''}<0.${leadingZeros}1';
    }
    return '${negative ? '-' : ''}$whole';
  }
  return '${negative ? '-' : ''}$whole.$clipped';
}
