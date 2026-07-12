part of '../views/utility_screens.dart';

class _InfoHeroCard extends StatefulWidget {
  final String title;
  final String text;

  const _InfoHeroCard({
    required this.title,
    required this.text,
  });

  @override
  State<_InfoHeroCard> createState() => _InfoHeroCardState();
}

class _InfoHeroCardState extends State<_InfoHeroCard> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 600;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EasyGameTheme.borderSoft.withValues(alpha: 0.35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.04),
                const Color(0xFF1A1F2E).withValues(alpha: 0.72),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 18 : 28,
                      vertical: compact ? 18 : 24,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: TextStyle(
                              color: EasyGameTheme.text,
                              fontSize: compact ? 21 : 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        AnimatedRotation(
                          turns: _isExpanded ? 0 : -0.25,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: EasyGameTheme.teal,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOutCubic,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 18 : 28,
                            0,
                            compact ? 18 : 28,
                            compact ? 20 : 28,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(
                                height: 1,
                                color: EasyGameTheme.borderSoft,
                              ),
                              SizedBox(height: compact ? 18 : 24),
                              Text(
                                widget.text,
                                style: TextStyle(
                                  color: EasyGameTheme.textMuted,
                                  fontSize: compact ? 15 : 17,
                                  height: 1.75,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InfoSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const _InfoSectionTitle({
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: EasyGameTheme.teal, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

class _InfoRuleList extends StatelessWidget {
  final List<String> rules;

  const _InfoRuleList({required this.rules});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rules.length; i++)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: i == rules.length - 1 ? 0 : 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EasyGameTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EasyGameTheme.borderSoft.withValues(alpha: 0.35)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  EasyGameTheme.cardDark.withValues(alpha: 0.72),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${i + 1}.',
                  style: const TextStyle(
                    color: EasyGameTheme.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rules[i],
                    style: const TextStyle(
                      color: Colors.white70,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoSplitBar extends StatefulWidget {
  final _InfoSplitRow row;

  const _InfoSplitBar({required this.row});

  @override
  State<_InfoSplitBar> createState() => _InfoSplitBarState();
}

class _InfoSplitBarState extends State<_InfoSplitBar> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isActive = _isHovered || _isSelected;
    final activeColor = Color.lerp(
      row.color,
      const Color(0xFF20E8FF),
      isActive ? 0.42 : 0,
    )!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isSelected = !_isSelected),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.07)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? activeColor.withValues(alpha: 0.42)
                  : Colors.transparent,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 58,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        color: activeColor,
                        fontSize: isActive ? 17 : 16,
                        fontWeight: FontWeight.w900,
                      ),
                      child: Text(row.percent),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.label,
                      style: TextStyle(
                        color: isActive ? EasyGameTheme.text : Colors.white70,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: row.ratio),
                duration: const Duration(milliseconds: 720),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    decoration: isActive
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: activeColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                              ),
                            ],
                          )
                        : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: isActive ? 11 : 9,
                        value: value,
                        backgroundColor: const Color(0xFF2A2948),
                        valueColor: AlwaysStoppedAnimation(activeColor),
                      ),
                    ),
                  );
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: isActive
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          row.description,
                          style: TextStyle(
                            color: activeColor.withValues(alpha: 0.88),
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoFlowCard extends StatefulWidget {
  final int index;
  final IconData icon;
  final String text;

  const _InfoFlowCard({
    required this.index,
    required this.icon,
    required this.text,
  });

  @override
  State<_InfoFlowCard> createState() => _InfoFlowCardState();
}

class _InfoFlowCardState extends State<_InfoFlowCard> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isSelected;
    const activeColor = Color(0xFF20E8FF);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isSelected = !_isSelected),
        child: AnimatedScale(
          scale: isActive ? 1.025 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withValues(alpha: 0.08)
                    : EasyGameTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? activeColor.withValues(alpha: 0.72)
                      : EasyGameTheme.borderSoft.withValues(alpha: 0.35),
                ),
                gradient: isActive
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          EasyGameTheme.cardDark.withValues(alpha: 0.72),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: isActive ? 1.12 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: AnimatedRotation(
                    turns: isActive ? 0.035 : 0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor.withValues(alpha: 0.18)
                            : EasyGameTheme.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: isActive ? activeColor : EasyGameTheme.teal,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.index}. ${widget.text}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? EasyGameTheme.text : Colors.white70,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCellChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoCellChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  State<_InfoCellChip> createState() => _InfoCellChipState();
}

class _InfoCellChipState extends State<_InfoCellChip> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isSelected;
    final activeColor = Color.lerp(
      widget.color,
      const Color(0xFF20E8FF),
      isActive ? 0.82 : 0,
    )!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isSelected = !_isSelected),
        child: AnimatedScale(
          scale: isActive ? 1.08 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 92,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.09)
                  : EasyGameTheme.cardDark.withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activeColor.withValues(alpha: isActive ? 0.78 : 0.30),
              ),
              gradient: isActive
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.04),
                        EasyGameTheme.cardDark.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.22),
                        blurRadius: 18,
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 56,
                  height: 50,
                  child: CustomPaint(
                    painter: _InfoHexCellPainter(
                      color: activeColor,
                      glowIntensity: isActive ? 1 : 0,
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: isActive ? 0.08 : 0,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          widget.icon,
                          color: activeColor,
                          size: isActive ? 21 : 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: isActive ? 17 : 16,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoResourceCard extends StatefulWidget {
  final _InfoResource resource;

  const _InfoResourceCard({required this.resource});

  @override
  State<_InfoResourceCard> createState() => _InfoResourceCardState();
}

class _InfoResourceCardState extends State<_InfoResourceCard> {
  bool _isHovered = false;
  bool _isSelected = false;

  @override
  Widget build(BuildContext context) {
    final resource = widget.resource;
    final isActive = _isHovered || _isSelected;
    final activeColor = Color.lerp(
      resource.color,
      const Color(0xFF20E8FF),
      isActive ? 0.78 : 0,
    )!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _isSelected = !_isSelected),
        child: AnimatedScale(
          scale: isActive ? 1.02 : 1,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? activeColor.withValues(alpha: 0.08)
                  : EasyGameTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: activeColor.withValues(alpha: isActive ? 0.72 : 0.28),
              ),
              gradient: isActive
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.04),
                        EasyGameTheme.cardDark.withValues(alpha: 0.72),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                    ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.18),
                        blurRadius: 18,
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isActive ? 1.1 : 1,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  child: SizedBox(
                    width: 52,
                    height: 48,
                    child: CustomPaint(
                      painter: _InfoHexCellPainter(
                        color: activeColor,
                        glowIntensity: isActive ? 1 : 0,
                      ),
                      child: Center(
                        child: AnimatedRotation(
                          turns: isActive ? 0.035 : 0,
                          duration: const Duration(milliseconds: 260),
                          child: Icon(
                            resource.icon,
                            color: activeColor,
                            size: isActive ? 23 : 21,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resource.title,
                        style: TextStyle(
                          color: isActive ? activeColor : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        resource.text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isActive ? Colors.white70 : Colors.white54,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
