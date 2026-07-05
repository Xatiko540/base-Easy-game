part of '../views/registrationlevel.dart';

class _ActiveGamesStrip extends StatelessWidget {
  final int selectedLevel;
  final String currencySymbol;
  final ValueChanged<int> onPickLevel;

  const _ActiveGamesStrip({
    required this.selectedLevel,
    required this.currencySymbol,
    required this.onPickLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: EasyGameTheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'registration.activeLevels'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'registration.chooseAny'.tr,
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 640
                  ? 2
                  : constraints.maxWidth < 900
                      ? 4
                      : 8;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount: easyGameLevelCount,
                itemBuilder: (context, index) {
                  final level = easyGameLevelCount - index;
                  final locked = level <= 2;
                  return _MiniLevelButton(
                    level: level,
                    amount: levelPrice(level),
                    currencySymbol: currencySymbol,
                    selected: selectedLevel == level,
                    locked: locked,
                    onTap: locked ? null : () => onPickLevel(level),
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

class _MiniLevelButton extends StatelessWidget {
  final int level;
  final double amount;
  final String currencySymbol;
  final bool selected;
  final bool locked;
  final VoidCallback? onTap;

  const _MiniLevelButton({
    required this.level,
    required this.amount,
    required this.currencySymbol,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: locked ? EasyGameTheme.card : EasyGameTheme.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? EasyGameTheme.tealSoft
                : locked
                    ? Colors.transparent
                    : EasyGameTheme.teal.withValues(alpha: 0.58),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lvl $level',
                    style: const TextStyle(
                      color: Color(0xFFB2B2B2),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.monetization_on,
                  color: Color(0xFFF7C948),
                  size: 15,
                ),
              ],
            ),
            Text(
              '${_formatRegistrationAmount(amount)} $currencySymbol',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              locked ? 'registration.schedule'.tr : 'registration.available'.tr,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: locked ? Colors.orangeAccent : const Color(0xFF63D3BE),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
