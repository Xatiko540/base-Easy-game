part of '../views/start_page.dart';

class _PreviewSearch extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onPreview;

  const _PreviewSearch({
    required this.onChanged,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: EasyGameTheme.teal.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EasyGameTheme.teal.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'start.previewMode'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'start.previewSubtitle'.tr,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final input = TextField(
                onChanged: onChanged,
                onSubmitted: (_) => onPreview(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  hintText: 'start.previewExample'.tr,
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 18,
                  ),
                ),
              );
              final button = _GradientButton(
                onTap: onPreview,
                child: Text(
                  'start.previewButton'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
              if (compact) {
                return Column(
                  children: [
                    input,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: button),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: input),
                  const SizedBox(width: 14),
                  button,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview();

  @override
  Widget build(BuildContext context) {
    final roundsController = Get.find<GameRoundsController>();
    return Obx(
      () {
        final rounds = roundsController.timeline.take(12).toList();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: EasyGameTheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'start.scheduleTitle'.tr,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              if (rounds.isEmpty)
                Text(
                  'start.scheduleUnavailable'.tr,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingTextStyle: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                    ),
                    dataTextStyle: const TextStyle(
                      color: Colors.white60,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: [
                      DataColumn(label: Text('start.startsAt'.tr)),
                      DataColumn(label: Text('common.level'.tr)),
                      DataColumn(label: Text('common.value'.tr)),
                      DataColumn(label: Text('levels.status'.tr)),
                    ],
                    rows: [
                      for (final round in rounds)
                        DataRow(
                          cells: [
                            DataCell(Text(
                                formatRoundStart(round.schedule.startsAt))),
                            DataCell(Text('${round.schedule.level}')),
                            DataCell(Text(
                              '${formatWeiToEth(round.ethPriceWei)} ETH',
                            )),
                            DataCell(
                              Text(
                                roundPhaseTranslationKey(round.phase).tr,
                                style: const TextStyle(
                                  color: EasyGameTheme.tealSoft,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
