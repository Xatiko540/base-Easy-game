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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _ProgramPoolValue(
                        color: EasyGameTheme.gold,
                        value:
                            '${formatWeiToEth(data.totalPrizePoolWei)} ${walletService.nativeSymbol}',
                      ),
                      const SizedBox(height: 5),
                      _ProgramPoolValue(
                        color: const Color(0xFF2775CA),
                        value: '${formatUsdc(data.totalPrizePoolUsdc)} USDC',
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

class _ProgramPoolValue extends StatelessWidget {
  final Color color;
  final String value;

  const _ProgramPoolValue({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CupertinoIcons.circle_fill, color: color, size: 12),
        const SizedBox(width: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
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
    final available = levelState?.canEnter ?? false;
    final active = levelState?.isPlayerActive == true;
    final frozen = levelState?.isFrozen == true;
    final missed = levelState?.isMissed ?? false;
    final didWin = levelState?.didWin;
    final notStarted = round == null ||
        round.phase == GameRoundPhase.scheduled ||
        round.phase == GameRoundPhase.uninitialized;

    final borderColor = frozen
        ? const Color(0xFFFFA62B)
        : missed
            ? Colors.white24
            : didWin == true
                ? const Color(0xFF28D07F)
                : didWin == false
                    ? const Color(0xFFFF4444)
                    : active
                        ? EasyGameTheme.teal
                        : available
                            ? Colors.white24
                            : Colors.white10;

    final showingSettledOutcome = didWin != null;
    final inProgress = active && !showingSettledOutcome;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: round == null
          ? null
          : showingSettledOutcome || active
              ? () => Get.to(() => EasyGameLevelDetailScreen(
                    level: level,
                    roundId: BigInt.from(round.schedule.roundId),
                  ))
              : () => Get.toNamed('/levels'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
          gradient: inProgress
              ? const LinearGradient(
                  colors: [Color(0xFF6F40F4), Color(0xFF00B2AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: inProgress
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
                  color: frozen
                      ? Colors.white
                      : missed
                          ? Colors.white24
                          : showingSettledOutcome
                              ? Colors.white
                              : active
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
              ] else if (missed) ...[
                const SizedBox(height: 3),
                const Icon(CupertinoIcons.minus_circle,
                    color: Colors.white24, size: 12),
              ] else if (didWin == true) ...[
                const SizedBox(height: 3),
                const Icon(CupertinoIcons.checkmark,
                    color: Color(0xFF28D07F), size: 12),
              ] else if (didWin == false) ...[
                const SizedBox(height: 3),
                const Icon(CupertinoIcons.xmark,
                    color: Color(0xFFFF4444), size: 12),
              ] else if (inProgress) ...[
                const SizedBox(height: 3),
                const Icon(CupertinoIcons.checkmark,
                    color: Colors.white, size: 12),
              ] else if (notStarted) ...[
                const SizedBox(height: 3),
                const Icon(CupertinoIcons.clock,
                    color: Colors.white24, size: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
