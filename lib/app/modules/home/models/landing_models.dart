part of '../views/start_page.dart';

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem(this.icon, this.title, this.subtitle);
}

class _ScheduleRow {
  final int level;
  final double price;
  final String status;

  const _ScheduleRow(this.level, this.price, this.status);
}

String _formatPrice(double value) {
  final fixed = value.toStringAsFixed(value >= 1 ? 1 : 2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
