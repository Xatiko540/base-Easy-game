class SplitRow {
  final String label;
  final double percent;
  final BigInt value;

  const SplitRow(this.label, this.percent, this.value);
}

String formatRegistrationAmount(double amount) {
  final fixed = amount.toStringAsFixed(amount >= 1 ? 1 : 2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
