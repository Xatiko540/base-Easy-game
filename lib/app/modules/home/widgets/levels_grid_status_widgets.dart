part of '../views/levels.dart';

class _LevelStateBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const _LevelStateBanner({
    required this.message,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orangeAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            child: Text('common.refresh'.tr),
          ),
        ],
      ),
    );
  }
}

class BottomTableSection extends StatelessWidget {
  const BottomTableSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.10,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'levels.transactions'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
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
                  DataColumn(label: Text('levels.source'.tr)),
                  DataColumn(label: Text('common.level'.tr)),
                  DataColumn(label: Text('levels.contractLogic'.tr)),
                  DataColumn(label: Text('levels.status'.tr)),
                ],
                rows: [
                  DataRow(cells: [
                    const DataCell(Text("MatrixPlaced")),
                    const DataCell(Text("EasyGameAdvance event")),
                    DataCell(Text('levels.allLevels'.tr)),
                    DataCell(Text('levels.binaryPlacement'.tr)),
                    DataCell(Text('levels.emitted'.tr)),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("PaymentSplit")),
                    const DataCell(Text("EasyGameAdvance event")),
                    DataCell(Text('levels.activeLevel'.tr)),
                    DataCell(Text('levels.baseReward'.tr)),
                    DataCell(Text('levels.emitted'.tr)),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("ReferralBonusAdded")),
                    const DataCell(Text("EasyGameAdvance event")),
                    DataCell(Text('levels.activeLevel'.tr)),
                    DataCell(Text('levels.referralSplit'.tr)),
                    DataCell(Text('levels.emitted'.tr)),
                  ]),
                  DataRow(cells: [
                    const DataCell(Text("Recycled / Frozen")),
                    const DataCell(Text("EasyGameAdvance event")),
                    DataCell(Text('levels.filledMatrix'.tr)),
                    DataCell(Text('levels.cycleState'.tr)),
                    DataCell(Text('levels.emitted'.tr)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'levels.historyAfterIndex'.tr,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
