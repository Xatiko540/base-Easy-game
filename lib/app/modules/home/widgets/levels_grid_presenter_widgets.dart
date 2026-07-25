part of '../views/levels.dart';

class _LevelCardPresenter extends StatelessWidget {
  final RoundLevelCardState level;
  final String currencySymbol;

  const _LevelCardPresenter({
    required this.level,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final roundsController = Get.find<GameRoundsController>();
    return Obx(() {
      final liveRound = roundsController.roundForLevel(level.level);
      final card = _buildCard(liveRound);
      final stateKey = [
        liveRound?.schedule.roundId ?? 0,
        liveRound?.phase.name ?? 'none',
        level.resolveViewMode().name,
      ].join('-');
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        reverseDuration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          fit: StackFit.expand,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        child: SizedBox.expand(
          key: ValueKey(stateKey),
          child: card,
        ),
      );
    });
  }

  Widget _buildCard(GameRoundViewState? round) {
    final priceWei = round?.ethPriceWei ?? level.ethPriceWei;

    void openDetail(GameRoundViewState? targetRound) {
      if (targetRound == null) return;
      Get.to(
        () => EasyGameLevelDetailScreen(
          level: targetRound.schedule.level,
          roundId: BigInt.from(targetRound.schedule.roundId),
        ),
      );
    }

    void detailTap() => openDetail(round);

    switch (level.resolveViewMode()) {
      case RoundLevelCardViewMode.awaiting:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: round != null
              ? 'levels.availableIn'.tr
              : 'levels.gameNotStarted'.tr,
          subtitle: round != null
              ? localizedRoundCountdown(round)
              : 'levels.gameStartsSoon'.tr,
          icon: CupertinoIcons.timer,
          color: EasyGameTheme.tealSoft,
          round: round,
          showTimer: round != null,
          onTap: detailTap,
        );

      case RoundLevelCardViewMode.activation:
        return ActivateCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          round: round,
        );

      case RoundLevelCardViewMode.active:
        return LevelCard(
          data: level,
          currencySymbol: currencySymbol,
          roundId: BigInt.from(round!.schedule.roundId),
          round: round,
        );

      case RoundLevelCardViewMode.completed:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.settled'.tr,
          subtitle: 'round.openResults'.tr,
          icon: CupertinoIcons.star,
          color: EasyGameTheme.tealSoft,
          round: round,
          onTap: detailTap,
        );

      case RoundLevelCardViewMode.skipped:
        return MissedLevelCard(
          level: level.level,
          priceWei: priceWei,
          onTap: detailTap,
        );

      case RoundLevelCardViewMode.frozen:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'common.frozen'.tr,
          subtitle: 'levels.openMatrixToUnfreeze'.tr,
          icon: CupertinoIcons.snow,
          color: Colors.lightBlueAccent,
          onTap: () =>
              Get.toNamed('/matrix', arguments: {'level': level.level}),
          round: round,
        );

      case RoundLevelCardViewMode.paused:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: roundPhaseTranslationKey(round!.phase).tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: CupertinoIcons.pause_circle,
          color: Colors.redAccent,
          round: round,
          onTap: detailTap,
        );

      case RoundLevelCardViewMode.cancelled:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: roundPhaseTranslationKey(round!.phase).tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: CupertinoIcons.xmark_circle,
          color: Colors.redAccent,
          round: round,
          onTap: detailTap,
        );
    }
  }
}
