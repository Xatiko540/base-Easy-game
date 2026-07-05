part of '../views/registrationlevel.dart';

class _SplitRow {
  final String label;
  final double percent;
  final double value;

  const _SplitRow(this.label, this.percent, this.value);
}

String _formatRegistrationAmount(double amount) {
  final fixed = amount.toStringAsFixed(amount >= 1 ? 1 : 2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
