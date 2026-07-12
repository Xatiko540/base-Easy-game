part of '../views/utility_screens.dart';

class _InfoMatrixStructurePanel extends StatefulWidget {
  const _InfoMatrixStructurePanel();

  @override
  State<_InfoMatrixStructurePanel> createState() =>
      _InfoMatrixStructurePanelState();
}

class _InfoMatrixStructurePanelState extends State<_InfoMatrixStructurePanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _InfoSectionTitle(
                icon: CupertinoIcons.square_list,
                title: 'info.structure'.tr,
                trailing: AnimatedRotation(
                  turns: _isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: EasyGameTheme.teal,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LayoutBuilder(
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InfoPaymentSplitPanel extends StatefulWidget {
  const _InfoPaymentSplitPanel();

  @override
  State<_InfoPaymentSplitPanel> createState() => _InfoPaymentSplitPanelState();
}

class _InfoPaymentSplitPanelState extends State<_InfoPaymentSplitPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _InfoSplitRow(
        '75.5%',
        'info.splitPool'.tr,
        'info.splitPoolHint'.tr,
        EasyGameTheme.teal,
        0.755,
      ),
      _InfoSplitRow(
        '9.5%',
        'info.splitDirect'.tr,
        'info.splitDirectHint'.tr,
        EasyGameTheme.purple,
        0.095,
      ),
      _InfoSplitRow(
        '6.0%',
        'info.splitSecond'.tr,
        'info.splitSecondHint'.tr,
        EasyGameTheme.blue,
        0.06,
      ),
      _InfoSplitRow(
        '4.0%',
        'info.splitThird'.tr,
        'info.splitThirdHint'.tr,
        const Color(0xFFA855F7),
        0.04,
      ),
      _InfoSplitRow(
        '5.0%',
        'info.splitProject'.tr,
        'info.splitProjectHint'.tr,
        EasyGameTheme.orange,
        0.05,
      ),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _InfoSectionTitle(
                icon: CupertinoIcons.chart_pie,
                title: 'info.paymentRouteTitle'.tr,
                trailing: AnimatedRotation(
                  turns: _isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: EasyGameTheme.teal,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? SelectionArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'info.rewardSystemIntro'.tr,
                            style: const TextStyle(
                              color: EasyGameTheme.textMuted,
                              height: 1.55,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 18),
                          for (final row in rows) _InfoSplitBar(row: row),
                          const SizedBox(height: 8),
                          Text(
                            'info.splitPoolDescription'.tr,
                            style: const TextStyle(
                              color: EasyGameTheme.textMuted,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
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
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InfoRoundLifecyclePanel extends StatefulWidget {
  const _InfoRoundLifecyclePanel();

  @override
  State<_InfoRoundLifecyclePanel> createState() =>
      _InfoRoundLifecyclePanelState();
}

class _InfoRoundLifecyclePanelState extends State<_InfoRoundLifecyclePanel> {
  bool _isExpanded = true;

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
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _InfoSectionTitle(
                icon: CupertinoIcons.location,
                title: 'info.roundLifecycleTitle'.tr,
                trailing: AnimatedRotation(
                  turns: _isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: EasyGameTheme.teal,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LayoutBuilder(
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
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InfoWinningCellsPanel extends StatefulWidget {
  const _InfoWinningCellsPanel();

  @override
  State<_InfoWinningCellsPanel> createState() => _InfoWinningCellsPanelState();
}

class _InfoWinningCellsPanelState extends State<_InfoWinningCellsPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    const cells = [7, 15, 31, 63, 127, 255];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _InfoSectionTitle(
                icon: CupertinoIcons.star,
                title: 'info.winningCellsTitle'.tr,
                trailing: AnimatedRotation(
                  turns: _isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: EasyGameTheme.teal,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectionArea(
                          child: Text(
                            'info.winningCellsText'.tr,
                            style: const TextStyle(
                              color: Colors.white54,
                              height: 1.5,
                              fontWeight: FontWeight.w700,
                            ),
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InfoGameResourcesPanel extends StatefulWidget {
  const _InfoGameResourcesPanel();

  @override
  State<_InfoGameResourcesPanel> createState() =>
      _InfoGameResourcesPanelState();
}

class _InfoGameResourcesPanelState extends State<_InfoGameResourcesPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final resources = [
      _InfoResource(
        CupertinoIcons.tray_full,
        'info.boxTokenTitle'.tr,
        'info.boxTokenText'.tr,
        EasyGameTheme.gold,
      ),
      _InfoResource(
        CupertinoIcons.snow,
        'info.freezeTokenTitle'.tr,
        'info.freezeTokenText'.tr,
        EasyGameTheme.teal,
      ),
      _InfoResource(
        CupertinoIcons.shield,
        'info.shieldTokenTitle'.tr,
        'info.shieldTokenText'.tr,
        EasyGameTheme.blue,
      ),
      _InfoResource(
        CupertinoIcons.bolt,
        'info.weightBoostTitle'.tr,
        'info.weightBoostText'.tr,
        EasyGameTheme.purple,
      ),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: _InfoSectionTitle(
                icon: CupertinoIcons.wand_stars,
                title: 'info.resourcesTitle'.tr,
                trailing: AnimatedRotation(
                  turns: _isExpanded ? 0 : -0.25,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: EasyGameTheme.teal,
                    size: 27,
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth < 560 ? 1 : 2;
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: resources.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
