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
      final card = _buildCard(
        liveRound,
        isScheduleLoading: roundsController.isScheduleLoading,
      );
      final stateKey = [
        liveRound?.schedule.roundId ?? 0,
        liveRound?.phase.name ?? 'none',
        level.playerStatus.name,
        level.isPlayerStatePending,
        level.hasError,
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

  Widget _buildCard(
    GameRoundViewState? round, {
    required bool isScheduleLoading,
  }) {
    final roundsController = Get.find<GameRoundsController>();
    final priceWei = round?.ethPriceWei ?? level.ethPriceWei;
    final mode = level.resolveViewMode(
      liveRound: round,
      isScheduleLoading: isScheduleLoading,
    );

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

    switch (mode) {
      case RoundLevelCardViewMode.scheduleLoading:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'common.loading'.tr,
          subtitle: 'levels.loadingSchedule'.tr,
          icon: CupertinoIcons.arrow_2_circlepath,
          color: EasyGameTheme.tealSoft,
        );
      case RoundLevelCardViewMode.awaitingRound:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'levels.gameNotStarted'.tr,
          subtitle: 'levels.gameStartsSoon'.tr,
          icon: CupertinoIcons.timer,
          color: EasyGameTheme.tealSoft,
        );
      case RoundLevelCardViewMode.refreshingRound:
      case RoundLevelCardViewMode.playerLoading:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'common.loading'.tr,
          subtitle: 'levels.roundDataRefreshing'.tr,
          icon: CupertinoIcons.arrow_2_circlepath,
          color: EasyGameTheme.tealSoft,
          round: round,
        );
      case RoundLevelCardViewMode.configurationMismatch:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.configurationMismatch'.tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: CupertinoIcons.shield_slash,
          color: Colors.redAccent,
          round: round,
        );
      case RoundLevelCardViewMode.dataError:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'common.error'.tr,
          subtitle: 'levels.roundDataUnavailable'.tr,
          icon: CupertinoIcons.exclamationmark_triangle,
          color: Colors.orangeAccent,
          round: round,
        );
      case RoundLevelCardViewMode.scheduled:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'levels.availableIn'.tr,
          subtitle: localizedRoundCountdown(round!),
          icon: CupertinoIcons.timer,
          color: Colors.orangeAccent,
          round: round,
          showTimer: true,
          onTap: detailTap,
        );
      case RoundLevelCardViewMode.active:
        return LevelCard(
          data: level,
          currencySymbol: currencySymbol,
          roundId: BigInt.from(round!.schedule.roundId),
          round: round,
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
      case RoundLevelCardViewMode.missed:
        return MissedLevelCard(
          level: level.level,
          priceWei: priceWei,
          onTap: detailTap,
        );
      case RoundLevelCardViewMode.progressionFrozen:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'levels.progressionFrozen'.tr,
          subtitle: 'levels.unfreezeCurrentLevel'.tr,
          icon: CupertinoIcons.snow,
          color: Colors.lightBlueAccent,
          onTap: () => Get.toNamed('/matrix', arguments: {
            'level': level.requiredLevel > 0 ? level.requiredLevel - 1 : 1,
          }),
          round: round,
        );
      case RoundLevelCardViewMode.progressionBlocked:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'levels.nextLevelRequired'.tr,
          subtitle: 'levels.activateRequiredLevel'.trParams({
            'level': '${level.requiredLevel}',
          }),
          icon: CupertinoIcons.lock,
          color: Colors.orangeAccent,
          onTap: () {
            final requiredRound = round == null
                ? null
                : roundsController.roundForLevelInSeason(
                    level.requiredLevel,
                    round.schedule.seasonId,
                  );
            openDetail(requiredRound ?? round);
          },
          round: round,
        );
      case RoundLevelCardViewMode.emergencyPaused:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'payment.levelEmergencyPaused'.tr,
          subtitle: 'payment.levelEmergencyPausedHint'.tr,
          icon: CupertinoIcons.pause_circle,
          color: Colors.redAccent,
          onTap: detailTap,
          round: round,
        );
      case RoundLevelCardViewMode.entryUnavailable:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.actionsUnavailable'.tr,
          subtitle: 'levels.entryUnavailable'.tr,
          icon: CupertinoIcons.lock,
          color: Colors.orangeAccent,
          onTap: detailTap,
          round: round,
        );
      case RoundLevelCardViewMode.activationAvailable:
        return ActivateCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          round: round,
        );
      case RoundLevelCardViewMode.entryClosed:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.locked'.tr,
          subtitle: 'levels.entryClosedHint'.tr,
          icon: CupertinoIcons.lock_circle,
          color: Colors.orangeAccent,
          onTap: detailTap,
          round: round,
          showTimer: true,
        );
      case RoundLevelCardViewMode.entryClosedActive:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.locked'.tr,
          subtitle: localizedRoundCountdown(round!),
          icon: CupertinoIcons.clock,
          color: Colors.orangeAccent,
          onTap: detailTap,
          round: round,
          showTimer: true,
        );
      case RoundLevelCardViewMode.settlementFinished:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.finished'.tr,
          subtitle: 'levels.roundFinishedNoTicket'.tr,
          icon: CupertinoIcons.flag,
          color: EasyGameTheme.tealSoft,
          onTap: detailTap,
          round: round,
        );
      case RoundLevelCardViewMode.settlementActive:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.settlementReady'.tr,
          subtitle: 'round.waitingSettlement'.tr,
          icon: CupertinoIcons.building_2_fill,
          color: EasyGameTheme.tealSoft,
          onTap: detailTap,
          round: round,
        );
      case RoundLevelCardViewMode.settledWithoutEntry:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.settled'.tr,
          subtitle: 'levels.roundSettledNoTicket'.tr,
          icon: CupertinoIcons.checkmark_seal,
          color: EasyGameTheme.tealSoft,
          onTap: detailTap,
          round: round,
        );
      case RoundLevelCardViewMode.settledActive:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.settled'.tr,
          subtitle: level.isPlayerActive
              ? 'round.openResults'.tr
              : 'round.finished'.tr,
          icon: CupertinoIcons.star,
          color: EasyGameTheme.tealSoft,
          onTap: detailTap,
          round: round,
        );
      case RoundLevelCardViewMode.cancelled:
      case RoundLevelCardViewMode.paused:
        final paused = mode == RoundLevelCardViewMode.paused;
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: roundPhaseTranslationKey(round!.phase).tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: paused
              ? CupertinoIcons.pause_circle
              : CupertinoIcons.xmark_circle,
          color: Colors.redAccent,
          onTap: detailTap,
          round: round,
        );
      case RoundLevelCardViewMode.uninitialized:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.uninitialized'.tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: CupertinoIcons.exclamationmark_circle,
          color: Colors.orangeAccent,
          onTap: detailTap,
          round: round,
        );
    }
  }
}
