part of '../views/utility_screens.dart';

class _MatrixLevelPicker extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onChanged;

  const _MatrixLevelPicker({
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'matrix.chooseLevel'.tr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              for (var level = 16; level >= 1; level--)
                _LevelChoiceButton(
                  level: level,
                  selected: level == selectedLevel,
                  locked: level <= 2,
                  onTap: () => onChanged(level),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelChoiceButton extends StatelessWidget {
  final int level;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _LevelChoiceButton({
    required this.level,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? EasyGameTheme.purple.withValues(alpha: 0.28)
              : locked
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFF192334),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? EasyGameTheme.purple
                : locked
                    ? Colors.white10
                    : EasyGameTheme.teal.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          '$level',
          style: TextStyle(
            color: locked
                ? Colors.white24
                : selected
                    ? EasyGameTheme.teal
                    : Colors.white60,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _MatrixLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _LegendItem('matrix.you'.tr, EasyGameTheme.teal, CupertinoIcons.person),
      _LegendItem('common.active'.tr, Colors.greenAccent, CupertinoIcons.person),
      _LegendItem('matrix.empty'.tr, Colors.white24, CupertinoIcons.circle),
      _LegendItem('common.frozen'.tr, EasyGameTheme.teal, CupertinoIcons.snow),
      _LegendItem('matrix.recycle'.tr, EasyGameTheme.orange, CupertinoIcons.refresh),
      _LegendItem(
          'matrix.winningCell'.tr, EasyGameTheme.gold, CupertinoIcons.star_fill),
    ];
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'matrix.legend'.tr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _MatrixNodeIcon(
                      color: item.color, icon: item.icon, small: true),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w800,
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
