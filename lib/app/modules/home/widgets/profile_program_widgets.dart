part of '../views/profilescreen.dart';

class _ProgramPanel extends StatelessWidget {
  final ProfileDashboardSnapshot data;

  const _ProgramPanel({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D1E2E), Color(0xFF073D38)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: EasyGameTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'app.name'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.circle,
                        color: EasyGameTheme.gold,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatWeiToEth(data.totalPrizePoolWei)} ${walletService.nativeSymbol}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: compact ? double.infinity : 390,
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: compact ? 6 : 8,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: easyGameLevelCount,
                        itemBuilder: (context, index) {
                          final level = easyGameLevelCount - index;
                          final levelState = data.levels.firstWhereOrNull(
                            (entry) => entry.level == level,
                          );
                          return _MatrixCell(
                            level: level,
                            levelState: levelState,
                          );
                        },
                      ),
                    ),
                  ),
                  if (!compact) const Spacer(),
                  if (!compact)
                    _ProgramCta(
                      onTap: () => Get.toNamed('/levels'),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.question_circle,
                    color: Colors.white.withValues(alpha: 0.42),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'profile.easyGameLegend'.tr,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (compact) const Spacer(),
                  if (compact)
                    _ProgramCta(
                      onTap: () => Get.toNamed('/levels'),
                      compact: true,
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProgramCta extends StatelessWidget {
  final VoidCallback onTap;
  final bool compact;

  const _ProgramCta({
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C45F6), Color(0xFF00B9B1)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(CupertinoIcons.arrow_up_right,
            color: Colors.white, size: 16),
        label: Text(
          compact ? 'profile.programViewShort'.tr : 'profile.programView'.tr,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 22,
            vertical: compact ? 10 : 16,
          ),
        ),
      ),
    );
  }
}

class _MatrixCell extends StatelessWidget {
  final int level;
  final RoundLevelCardState? levelState;

  const _MatrixCell({
    required this.level,
    required this.levelState,
  });

  @override
  Widget build(BuildContext context) {
    final round = levelState?.round ??
        Get.find<GameRoundsController>().roundForLevel(level);
    // The program overview is public. Keep its pre-login appearance while
    // round data is still loading; wallet-only state is layered on top below.
    final available = round?.canEnter ?? level >= 3;
    final active = levelState?.isPlayerActive == true;
    final frozen = levelState?.isFrozen == true;
    final borderColor = frozen
        ? const Color(0xFFFFA62B)
        : active
            ? EasyGameTheme.teal
            : available
                ? Colors.white24
                : Colors.white10;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: round == null
          ? null
          : active
              ? () => Get.to(() => EasyGameLevelDetailScreen(
                    level: level,
                    roundId: BigInt.from(round.schedule.roundId),
                  ))
              : () => Get.toNamed('/levels'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF6F40F4), Color(0xFF00B2AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: active
              ? null
              : available
                  ? const Color(0xFF242338)
                  : const Color(0xFF151523),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$level',
                style: TextStyle(
                  fontSize: 14,
                  color: active
                      ? Colors.white
                      : available
                          ? Colors.white38
                          : EasyGameTheme.gold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (frozen) ...[
                const SizedBox(height: 3),
                const Icon(CupertinoIcons.snow,
                    color: Color(0xFFFFA62B), size: 12),
              ] else if (active) ...[
                const SizedBox(height: 3),
                const Icon(CupertinoIcons.checkmark,
                    color: Colors.white, size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
