part of '../views/registrationlevel.dart';

class _PaymentSummary extends StatelessWidget {
  final double amount;
  final String currencySymbol;

  const _PaymentSummary({
    required this.amount,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      SplitRow('registration.matrixPrizePool'.tr, 75.5, amount * 0.755),
      SplitRow('registration.directReferral'.tr, 9.5, amount * 0.095),
      SplitRow('registration.secondReferral'.tr, 6.0, amount * 0.06),
      SplitRow('registration.thirdReferral'.tr, 4.0, amount * 0.04),
      SplitRow('registration.projectFee'.tr, 5.0, amount * 0.05),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EasyGameTheme.teal.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryRow(
            title: 'registration.paymentContract'.tr,
            value: '${amount.toStringAsFixed(6)} $currencySymbol',
            strong: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24),
          ),
          for (final row in rows) ...[
            _SummaryRow(
              title: '${row.label} (${row.percent.toStringAsFixed(1)}%)',
              value: '${row.value.toStringAsFixed(6)} $currencySymbol',
            ),
            const SizedBox(height: 8),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: Colors.white12),
          ),
          _SummaryRow(
            title: 'registration.networkFee'.tr,
            value: 'registration.estimatedSigning'.tr,
          ),
        ],
      ),
    );
  }
}
