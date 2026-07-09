part of '../views/levels.dart';

class _LevelDetailPanel extends StatelessWidget {
  final String title;
  final List<DetailRow> rows;

  const _LevelDetailPanel({
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(row.label,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LevelEventsTable extends StatelessWidget {
  final int level;

  const _LevelEventsTable({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'levelDetail.transactionsHistory'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              dataTextStyle: const TextStyle(color: Colors.grey),
              columnSpacing: 28,
              columns: [
                DataColumn(label: Text('levels.event'.tr)),
                DataColumn(label: Text('common.level'.tr)),
                DataColumn(label: Text('levelDetail.meaning'.tr)),
                DataColumn(label: Text('levels.status'.tr)),
              ],
              rows: [
                DataRow(cells: [
                  const DataCell(Text('MatrixPlaced')),
                  DataCell(Text('$level')),
                  DataCell(Text('levelDetail.positionCreated'.tr)),
                  DataCell(Text('common.contractEvent'.tr)),
                ]),
                DataRow(cells: [
                  const DataCell(Text('PrizePositionReached')),
                  DataCell(Text('$level')),
                  DataCell(Text('levelDetail.rewardMeaning'.tr)),
                  DataCell(Text('common.contractEvent'.tr)),
                ]),
                DataRow(cells: [
                  const DataCell(Text('ReferralBonusAdded')),
                  DataCell(Text('$level')),
                  DataCell(Text('levelDetail.referralMeaning'.tr)),
                  DataCell(Text('common.contractEvent'.tr)),
                ]),
                DataRow(cells: [
                  const DataCell(Text('Recycled / Frozen')),
                  DataCell(Text('$level')),
                  DataCell(Text('levelDetail.cycleMeaning'.tr)),
                  DataCell(Text('common.contractEvent'.tr)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'levelDetail.exactRows'.tr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LevelNavButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool trailing;
  final bool enabled;
  final VoidCallback onTap;

  const _LevelNavButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.trailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = [
      Icon(icon, color: enabled ? Colors.white : Colors.grey, size: 16),
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.grey,
          fontSize: 14,
        ),
      ),
    ];
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: trailing ? content.reversed.toList() : content,
        ),
      ),
    );
  }
}
