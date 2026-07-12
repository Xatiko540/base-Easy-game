part of '../views/levels.dart';

class _LevelCardPresenter extends StatelessWidget {
  final Level level;
  final String currencySymbol;

  const _LevelCardPresenter({
    required this.level,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final roundsController = Get.find<GameRoundsController>();
    return Obx(() {
      final round = roundsController.roundForLevel(level.levelNumber);
      final scheduledCard = _buildRoundPhaseCard(round);
      return scheduledCard ?? _buildLevelCard(round);
    });
  }

  Widget? _buildRoundPhaseCard(GameRoundViewState? round) {
    if (round == null) {
      return level.status == LevelStatus.waiting
          ? StatusCard(
              level: level.levelNumber,
              coin: level.coin,
              currencySymbol: currencySymbol,
              title: 'round.unavailable'.tr,
              subtitle: 'levels.scheduleUnavailable'.tr,
              icon: CupertinoIcons.calendar_badge_minus,
              color: Colors.orangeAccent,
            )
          : null;
    }
    if (!round.isConfigurationTrusted) {
      return StatusCard(
        level: level.levelNumber,
        coin: level.coin,
        currencySymbol: currencySymbol,
        title: 'round.configurationMismatch'.tr,
        subtitle: 'round.actionsUnavailable'.tr,
        icon: CupertinoIcons.shield_slash,
        color: Colors.redAccent,
      );
    }
    if (round.phase == GameRoundPhase.open) return null;

    VoidCallback? detailTap;
    if (level.status == LevelStatus.active ||
        level.status == LevelStatus.frozen ||
        level.status == LevelStatus.completed) {
      detailTap = () => Get.to(
            () => EasyGameLevelDetailScreen(level: level.levelNumber),
          );
    }

    switch (round.phase) {
      case GameRoundPhase.scheduled:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: 'levels.availableIn'.tr,
          subtitle: round.countdownLabel,
          icon: CupertinoIcons.timer,
          color: Colors.orangeAccent,
        );
      case GameRoundPhase.locked:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: 'round.locked'.tr,
          subtitle: round.countdownLabel,
          icon: CupertinoIcons.clock,
          color: Colors.orangeAccent,
          onTap: detailTap,
        );
      case GameRoundPhase.settlementReady:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: 'round.settlementReady'.tr,
          subtitle: 'round.waitingSettlement'.tr,
          icon: CupertinoIcons.building_2_fill,
          color: EasyGameTheme.tealSoft,
          onTap: detailTap,
        );
      case GameRoundPhase.cancelled:
      case GameRoundPhase.paused:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: roundPhaseTranslationKey(round.phase).tr,
          subtitle: 'round.actionsUnavailable'.tr,
          icon: round.phase == GameRoundPhase.paused
              ? CupertinoIcons.pause_circle
              : CupertinoIcons.xmark_circle,
          color: Colors.redAccent,
          onTap: detailTap,
        );
      case GameRoundPhase.settled:
        if (detailTap == null) {
          return StatusCard(
            level: level.levelNumber,
            coin: level.coin,
            currencySymbol: currencySymbol,
            title: 'round.settled'.tr,
            subtitle: 'round.finished'.tr,
            icon: CupertinoIcons.star,
            color: EasyGameTheme.tealSoft,
          );
        }
        return null;
      case GameRoundPhase.uninitialized:
      case GameRoundPhase.open:
        return null;
    }
  }

  Widget _buildLevelCard(GameRoundViewState? round) {
    switch (level.status) {
      case LevelStatus.locked:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: 'levels.availableIn'.tr,
          subtitle: 'levels.scheduleUnavailable'.tr,
          icon: CupertinoIcons.timer,
          color: Colors.orangeAccent,
        );
      case LevelStatus.frozen:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: 'common.frozen'.tr,
          subtitle: 'levels.activateNext'.tr,
          icon: CupertinoIcons.snow,
          color: Colors.lightBlueAccent,
          onTap: () => Get.to(
            () => EasyGameLevelDetailScreen(level: level.levelNumber),
          ),
        );
      case LevelStatus.waiting:
        return ActivateCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          status: level.status,
          round: round,
        );
      case LevelStatus.active:
      case LevelStatus.completed:
        return LevelCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          partnerBonus: level.partnerBonus,
          levelProfit: level.levelProfit,
          fillPercent: level.fillPercent,
          cycles: level.cycles,
          positionId: level.positionId,
          earnedWei: level.earnedWei,
          matrixSize: level.matrixSize,
          prizePoolWei: level.prizePoolWei,
          totalWeight: level.totalWeight,
          activeCells: level.activeCells,
          playerWeight: level.playerWeight,
          playerChanceBps: level.playerChanceBps,
        );
    }
  }
}
