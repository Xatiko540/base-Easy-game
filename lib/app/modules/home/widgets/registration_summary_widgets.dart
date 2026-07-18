part of '../views/registrationlevel.dart';

class _PaymentSummary extends StatelessWidget {
  final BigInt amount;
  final bool paysWithUsdc;
  final String currencySymbol;

  const _PaymentSummary({
    required this.amount,
    required this.paysWithUsdc,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final rows = [
      SplitRow('registration.matrixPrizePool'.tr, 75.5,
          (amount * BigInt.from(7550)) ~/ BigInt.from(10000)),
      SplitRow('registration.directReferral'.tr, 9.5,
          (amount * BigInt.from(950)) ~/ BigInt.from(10000)),
      SplitRow('registration.secondReferral'.tr, 6.0,
          (amount * BigInt.from(600)) ~/ BigInt.from(10000)),
      SplitRow('registration.thirdReferral'.tr, 4.0,
          (amount * BigInt.from(400)) ~/ BigInt.from(10000)),
      SplitRow('registration.projectFee'.tr, 5.0,
          (amount * BigInt.from(500)) ~/ BigInt.from(10000)),
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
            title: 'registration.totalContractCharge'.tr,
            value: '${_format(amount)} $currencySymbol',
            strong: true,
          ),
          const SizedBox(height: 6),
          Text(
            'registration.gameFeesIncluded'.tr,
            style: const TextStyle(
              color: EasyGameTheme.teal,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white24),
          ),
          for (final row in rows) ...[
            _SummaryRow(
              title: '${row.label} (${row.percent.toStringAsFixed(1)}%)',
              value: '${_format(row.value)} $currencySymbol',
            ),
            const SizedBox(height: 8),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(color: Colors.white12),
          ),
          _SummaryRow(
            title: 'registration.networkFee'.tr,
            value: 'registration.networkGasExtra'.tr,
          ),
        ],
      ),
    );
  }

  String _format(BigInt value) => paysWithUsdc
      ? formatUsdc(value, decimals: 6)
      : formatWeiToEth(value, decimals: 8);
}
