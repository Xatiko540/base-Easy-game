part of '../views/utility_screens.dart';

class _InfoMatrixStructurePanel extends StatelessWidget {
  const _InfoMatrixStructurePanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSectionTitle(
            icon: CupertinoIcons.square_list,
            title: 'info.structure'.tr,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final diagram = _BinaryTreeDiagram(compact: compact);
              final rules = _InfoRuleList(
                rules: [
                  'info.ruleTicketCell'.tr,
                  'info.ruleFillLeftRight'.tr,
                  'info.ruleRecycle'.tr,
                  'info.ruleChance'.tr,
                ],
              );
              if (compact) {
                return Column(
                  children: [
                    diagram,
                    const SizedBox(height: 16),
                    rules,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: diagram),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: rules),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoPaymentSplitPanel extends StatelessWidget {
  const _InfoPaymentSplitPanel();

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoSplitRow('75.5%', 'info.splitPool'.tr, EasyGameTheme.teal, 0.755),
      _InfoSplitRow('9.5%', 'info.splitDirect'.tr, EasyGameTheme.purple, 0.095),
      _InfoSplitRow('6.0%', 'info.splitSecond'.tr, EasyGameTheme.blue, 0.06),
      _InfoSplitRow(
          '4.0%', 'info.splitThird'.tr, const Color(0xFFA855F7), 0.04),
      _InfoSplitRow('5.0%', 'info.splitProject'.tr, EasyGameTheme.orange, 0.05),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSectionTitle(
            icon: CupertinoIcons.chart_pie,
            title: 'info.paymentRouteTitle'.tr,
          ),
          const SizedBox(height: 16),
          for (final row in rows) _InfoSplitBar(row: row),
          const SizedBox(height: 12),
          Text(
            'info.paymentRouteText'.tr,
            style: const TextStyle(
              color: Colors.white54,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRoundLifecyclePanel extends StatelessWidget {
  const _InfoRoundLifecyclePanel();

  @override
  Widget build(BuildContext context) {
    final steps = [
      _InfoFlowStep(CupertinoIcons.creditcard, 'info.stepConnect'.tr),
      _InfoFlowStep(CupertinoIcons.ticket, 'info.stepTicket'.tr),
      _InfoFlowStep(CupertinoIcons.square_grid_3x2, 'info.stepMatrix'.tr),
      _InfoFlowStep(CupertinoIcons.refresh, 'info.stepRecycle'.tr),
      _InfoFlowStep(CupertinoIcons.star, 'info.stepPrize'.tr),
      _InfoFlowStep(CupertinoIcons.money_dollar_circle, 'info.stepClaim'.tr),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSectionTitle(
            icon: CupertinoIcons.location,
            title: 'info.roundLifecycleTitle'.tr,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 520
                  ? 1
                  : constraints.maxWidth < 820
                      ? 2
                      : 3;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: steps.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 96,
                ),
                itemBuilder: (context, index) {
                  final step = steps[index];
                  return _InfoFlowCard(
                    index: index + 1,
                    icon: step.icon,
                    text: step.text,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoWinningCellsPanel extends StatelessWidget {
  const _InfoWinningCellsPanel();

  @override
  Widget build(BuildContext context) {
    const cells = [7, 15, 31, 63, 127, 255];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSectionTitle(
            icon: CupertinoIcons.star,
            title: 'info.winningCellsTitle'.tr,
          ),
          const SizedBox(height: 12),
          Text(
            'info.winningCellsText'.tr,
            style: const TextStyle(
              color: Colors.white54,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final cell in cells)
                _InfoCellChip(
                  label: '$cell',
                  icon: CupertinoIcons.star,
                  color: EasyGameTheme.gold,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoGameResourcesPanel extends StatelessWidget {
  const _InfoGameResourcesPanel();

  @override
  Widget build(BuildContext context) {
    final resources = [
      _InfoResource(
        CupertinoIcons.tray_full,
        'boxToken',
        'info.boxTokenText'.tr,
        EasyGameTheme.gold,
      ),
      _InfoResource(
        CupertinoIcons.snow,
        'freezeToken',
        'info.freezeTokenText'.tr,
        EasyGameTheme.teal,
      ),
      _InfoResource(
        CupertinoIcons.shield,
        'shieldToken',
        'info.shieldTokenText'.tr,
        EasyGameTheme.blue,
      ),
      _InfoResource(
        CupertinoIcons.bolt,
        'weightBoost',
        'info.weightBoostText'.tr,
        EasyGameTheme.purple,
      ),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSectionTitle(
            icon: CupertinoIcons.wand_stars,
            title: 'info.resourcesTitle'.tr,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 560 ? 1 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: resources.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: 132,
                ),
                itemBuilder: (context, index) {
                  final resource = resources[index];
                  return _InfoResourceCard(resource: resource);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
