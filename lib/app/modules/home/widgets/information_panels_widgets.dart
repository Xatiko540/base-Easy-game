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
            icon: Icons.account_tree_outlined,
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
            icon: Icons.pie_chart_outline,
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
      _InfoFlowStep(Icons.wallet, 'info.stepConnect'.tr),
      _InfoFlowStep(Icons.confirmation_number_outlined, 'info.stepTicket'.tr),
      _InfoFlowStep(Icons.grid_on_rounded, 'info.stepMatrix'.tr),
      _InfoFlowStep(Icons.sync, 'info.stepRecycle'.tr),
      _InfoFlowStep(Icons.emoji_events_outlined, 'info.stepPrize'.tr),
      _InfoFlowStep(Icons.savings_outlined, 'info.stepClaim'.tr),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoSectionTitle(
            icon: Icons.route,
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
            icon: Icons.emoji_events_outlined,
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
                  icon: Icons.emoji_events_outlined,
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
        Icons.inventory_2_outlined,
        'boxToken',
        'info.boxTokenText'.tr,
        EasyGameTheme.gold,
      ),
      _InfoResource(
        Icons.ac_unit,
        'freezeToken',
        'info.freezeTokenText'.tr,
        EasyGameTheme.teal,
      ),
      _InfoResource(
        Icons.shield_outlined,
        'shieldToken',
        'info.shieldTokenText'.tr,
        EasyGameTheme.blue,
      ),
      _InfoResource(
        Icons.bolt,
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
            icon: Icons.auto_awesome,
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
