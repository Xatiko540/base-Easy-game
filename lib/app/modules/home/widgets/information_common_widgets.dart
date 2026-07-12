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
            color: EasyGameTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EasyGameTheme.borderSoft),
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
              border: Border.all(color: EasyGameTheme.borderSoft),
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

class _InfoSplitBar extends StatelessWidget {
  final _InfoSplitRow row;

  const _InfoSplitBar({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 58,
                child: Text(
                  row.percent,
                  style: TextStyle(
                    color: row.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  row.label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: row.ratio,
              backgroundColor: const Color(0xFF2A2948),
              valueColor: AlwaysStoppedAnimation(row.color),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoFlowCard extends StatelessWidget {
  final int index;
  final IconData icon;
  final String text;

  const _InfoFlowCard({
    required this.index,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: EasyGameTheme.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: EasyGameTheme.teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: EasyGameTheme.teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$index. $text',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCellChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoCellChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 50,
            child: CustomPaint(
              painter: _InfoHexCellPainter(color: color),
              child: Center(
                child: Icon(icon, color: color, size: 18),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoResourceCard extends StatelessWidget {
  final _InfoResource resource;

  const _InfoResourceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EasyGameTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: resource.color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 48,
            padding: const EdgeInsets.all(2),
            child: CustomPaint(
              painter: _InfoHexCellPainter(color: resource.color),
              child: Center(
                child: Icon(
                  resource.icon,
                  color: resource.color,
                  size: 21,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  resource.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
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
