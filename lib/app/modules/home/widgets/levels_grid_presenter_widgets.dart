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
        isScheduleReady: roundsController.isScheduleReady.value,
        scheduleError: roundsController.scheduleError.value,
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
        child: KeyedSubtree(
          key: ValueKey(stateKey),
          child: card,
        ),
      );
    });
  }

  Widget _buildCard(
    GameRoundViewState? round, {
    required bool isScheduleReady,
    required String scheduleError,
  }) {
    final priceWei = round?.ethPriceWei ?? level.ethPriceWei;
    if (round == null) {
      if (!isScheduleReady) {
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'common.loading'.tr,
          subtitle: 'levels.loadingSchedule'.tr,
          icon: CupertinoIcons.arrow_2_circlepath,
          color: EasyGameTheme.tealSoft,
        );
      }
      if (scheduleError.isNotEmpty) {
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'common.error'.tr,
          subtitle: 'levels.scheduleLoadFailed'.tr,
          icon: CupertinoIcons.exclamationmark_triangle,
          color: Colors.orangeAccent,
        );
      }
      return StatusCard(
        level: level.level,
        priceWei: priceWei,
        currencySymbol: currencySymbol,
        title: 'levels.gameNotStarted'.tr,
        subtitle: 'levels.gameStartsSoon'.tr,
        icon: CupertinoIcons.timer,
        color: EasyGameTheme.tealSoft,
      );
    }
    if (level.hasRound &&
        level.roundId != BigInt.from(round.schedule.roundId)) {
      return StatusCard(
        level: level.level,
        priceWei: priceWei,
        currencySymbol: currencySymbol,
        title: 'common.loading'.tr,
        subtitle: 'levels.roundDataRefreshing'.tr,
        icon: CupertinoIcons.arrow_2_circlepath,
        color: EasyGameTheme.tealSoft,
      );
    }
    if (!round.isConfigurationTrusted) {
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
    }
    if (level.isPlayerStatePending) {
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
    }
    if (level.hasError) {
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
    }

    void detailTap() => Get.to(
          () => EasyGameLevelDetailScreen(
            level: level.level,
            roundId: BigInt.from(round.schedule.roundId),
          ),
        );

    if (level.isFrozen) {
      return StatusCard(
        level: level.level,
        priceWei: priceWei,
        currencySymbol: currencySymbol,
        title: 'common.frozen'.tr,
        subtitle: 'levels.openMatrixToUnfreeze'.tr,
        icon: CupertinoIcons.snow,
        color: Colors.lightBlueAccent,
        onTap: () => Get.toNamed('/matrix'),
        round: round,
      );
    }
    if (level.isMissed) {
      return MissedLevelCard(
        level: level.level,
        priceWei: priceWei,
        onTap: detailTap,
      );
    }
    if (level.isFrozenProgressionBlocked) {
      return StatusCard(
        level: level.level,
        priceWei: priceWei,
        currencySymbol: currencySymbol,
        title: 'levels.progressionFrozen'.tr,
        subtitle: 'levels.unfreezeCurrentLevel'.tr,
        icon: CupertinoIcons.snow,
        color: Colors.lightBlueAccent,
        onTap: () => Get.toNamed('/matrix'),
        round: round,
      );
    }
    if (level.isProgressionBlocked) {
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
        round: round,
      );
    }

    switch (round.phase) {
      case GameRoundPhase.scheduled:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'levels.availableIn'.tr,
          subtitle: localizedRoundCountdown(round),
          icon: CupertinoIcons.timer,
          color: Colors.orangeAccent,
          round: round,
          showTimer: true,
        );
      case GameRoundPhase.open:
        if (level.isPlayerActive) {
          return LevelCard(
            data: level,
            currencySymbol: currencySymbol,
            roundId: BigInt.from(round.schedule.roundId),
            round: round,
          );
        }
        if (level.isEmergencyPaused) {
          return StatusCard(
            level: level.level,
            priceWei: priceWei,
            currencySymbol: currencySymbol,
            title: 'payment.levelEmergencyPaused'.tr,
            subtitle: 'payment.levelEmergencyPausedHint'.tr,
            icon: CupertinoIcons.pause_circle,
            color: Colors.redAccent,
            round: round,
          );
        }
        if (!level.canEnter) {
          return StatusCard(
            level: level.level,
            priceWei: priceWei,
            currencySymbol: currencySymbol,
            title: 'round.actionsUnavailable'.tr,
            subtitle: 'levels.entryUnavailable'.tr,
            icon: CupertinoIcons.lock,
            color: Colors.orangeAccent,
            round: round,
          );
        }
        return ActivateCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          round: round,
        );
      case GameRoundPhase.locked:
        if (!level.isPlayerActive) {
          return StatusCard(
            level: level.level,
            priceWei: priceWei,
            currencySymbol: currencySymbol,
            title: 'levels.gameNotStarted'.tr,
            subtitle: 'levels.gameStartsSoon'.tr,
            icon: CupertinoIcons.timer,
            color: EasyGameTheme.tealSoft,
            round: round,
          );
        }
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.locked'.tr,
          subtitle: localizedRoundCountdown(round),
          icon: CupertinoIcons.clock,
          color: Colors.orangeAccent,
          onTap: detailTap,
          round: round,
          showTimer: true,
        );
      case GameRoundPhase.settlementReady:
        if (!level.isPlayerActive) {
          return StatusCard(
            level: level.level,
            priceWei: priceWei,
            currencySymbol: currencySymbol,
            title: 'round.finished'.tr,
            subtitle: 'levels.gameStartsSoon'.tr,
            icon: CupertinoIcons.timer,
            color: EasyGameTheme.tealSoft,
            round: round,
          );
        }
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
      case GameRoundPhase.settled:
        if (!level.isPlayerActive) {
          return StatusCard(
            level: level.level,
            priceWei: priceWei,
            currencySymbol: currencySymbol,
            title: 'levels.gameNotStarted'.tr,
            subtitle: 'levels.gameStartsSoon'.tr,
            icon: CupertinoIcons.timer,
            color: EasyGameTheme.tealSoft,
            round: round,
          );
        }
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
      case GameRoundPhase.cancelled:
      case GameRoundPhase.paused:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: roundPhaseTranslationKey(round.phase).tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: round.phase == GameRoundPhase.paused
              ? CupertinoIcons.pause_circle
              : CupertinoIcons.xmark_circle,
          color: Colors.redAccent,
          onTap: detailTap,
          round: round,
        );
      case GameRoundPhase.uninitialized:
        return StatusCard(
          level: level.level,
          priceWei: priceWei,
          currencySymbol: currencySymbol,
          title: 'round.uninitialized'.tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: CupertinoIcons.exclamationmark_circle,
          color: Colors.orangeAccent,
          round: round,
        );
    }
  }
}
