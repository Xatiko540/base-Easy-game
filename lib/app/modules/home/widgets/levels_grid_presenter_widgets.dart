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
    switch (level.status) {
      case LevelStatus.locked:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: 'levels.availableIn'.tr,
          subtitle: level.levelNumber == 1
              ? 'levels.fourDays'.tr
              : 'levels.hours41'.tr,
          icon: Icons.timer_outlined,
          color: Colors.orangeAccent,
        );
      case LevelStatus.frozen:
        return StatusCard(
          level: level.levelNumber,
          coin: level.coin,
          currencySymbol: currencySymbol,
          title: 'common.frozen'.tr,
          subtitle: 'levels.activateNext'.tr,
          icon: Icons.ac_unit,
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
