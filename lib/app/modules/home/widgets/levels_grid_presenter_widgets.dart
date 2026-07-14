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
      return _buildCard(liveRound);
    });
  }

  Widget _buildCard(GameRoundViewState? round) {
    final coin = weiToEthDouble(
      round?.schedule.ethPriceWei ?? level.ethPriceWei,
    );
    if (round == null) {
      return StatusCard(
        level: level.level,
        coin: coin,
        currencySymbol: currencySymbol,
        title: 'round.unavailable'.tr,
        subtitle: 'levels.scheduleUnavailable'.tr,
        icon: CupertinoIcons.calendar_badge_minus,
        color: Colors.orangeAccent,
      );
    }
    if (level.hasRound &&
        level.roundId != BigInt.from(round.schedule.roundId)) {
      return StatusCard(
        level: level.level,
        coin: coin,
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
        coin: coin,
        currencySymbol: currencySymbol,
        title: 'round.configurationMismatch'.tr,
        subtitle: 'round.actionsUnavailable'.tr,
        icon: CupertinoIcons.shield_slash,
        color: Colors.redAccent,
        round: round,
      );
    }
    if (level.hasError) {
      return StatusCard(
        level: level.level,
        coin: coin,
        currencySymbol: currencySymbol,
        title: 'common.error'.tr,
        subtitle: 'levels.roundDataUnavailable'.tr,
        icon: CupertinoIcons.exclamationmark_triangle,
        color: Colors.orangeAccent,
        round: round,
      );
    }

    final detailTap = level.isPlayerActive
        ? () => Get.to(
              () => EasyGameLevelDetailScreen(
                level: level.level,
                roundId: BigInt.from(round.schedule.roundId),
              ),
            )
        : null;

    if (level.isFrozen) {
      return StatusCard(
        level: level.level,
        coin: coin,
        currencySymbol: currencySymbol,
        title: 'common.frozen'.tr,
        subtitle: 'levels.openMatrixToUnfreeze'.tr,
        icon: CupertinoIcons.snow,
        color: Colors.lightBlueAccent,
        onTap: detailTap,
        round: round,
      );
    }

    switch (round.phase) {
      case GameRoundPhase.scheduled:
        return StatusCard(
          level: level.level,
          coin: coin,
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
        return ActivateCard(
          level: level.level,
          coin: coin,
          currencySymbol: currencySymbol,
          round: round,
        );
      case GameRoundPhase.locked:
        return StatusCard(
          level: level.level,
          coin: coin,
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
        return StatusCard(
          level: level.level,
          coin: coin,
          currencySymbol: currencySymbol,
          title: 'round.settlementReady'.tr,
          subtitle: 'round.waitingSettlement'.tr,
          icon: CupertinoIcons.building_2_fill,
          color: EasyGameTheme.tealSoft,
          onTap: detailTap,
          round: round,
        );
      case GameRoundPhase.settled:
        return StatusCard(
          level: level.level,
          coin: coin,
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
          coin: coin,
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
          coin: coin,
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
