import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/widgets/game_round_presentation.dart';

import '../models/levels_models.dart';
import '../controllers/levels_provider.dart';
import '../controllers/level_detail_controller.dart';
part '../widgets/levels_grid_widgets.dart';
part '../widgets/levels_grid_presenter_widgets.dart';
part '../widgets/levels_grid_card_widgets.dart';
part '../widgets/levels_grid_common_widgets.dart';
part '../widgets/levels_grid_status_widgets.dart';
part '../widgets/level_detail_widgets.dart';
part '../widgets/level_detail_hero_widgets.dart';
part '../widgets/level_detail_matrix_widgets.dart';
part '../widgets/level_detail_claim_widgets.dart';
part '../widgets/level_detail_common_widgets.dart';

class LevelsScreen extends StatelessWidget {
  final String? walletAddress;

  const LevelsScreen({Key? key, this.walletAddress}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tag = walletAddress ?? 'connected-wallet';
    return GetX<LevelsProvider>(
      init: LevelsProvider()..configure(playerAddress: walletAddress),
      tag: tag,
      dispose: (_) {
        if (Get.isRegistered<LevelsProvider>(tag: tag)) {
          Get.delete<LevelsProvider>(tag: tag);
        }
      },
      builder: (levelsProvider) {
        final walletService = Get.find<WalletConnectService>();
        final levelCount = levelsProvider.levels.length;
        final loading = levelsProvider.isLoading.value;
        final errorMessage = levelsProvider.errorMessage.value;
        final currency = walletService.nativeSymbol;
        final totalEarnedWei = levelsProvider.totalEarnedWei;
        final connected = walletService.isConnected.value;
        return ExpressAppShell(
          title: 'levels.title'.tr,
          breadcrumb:
              '${connected ? walletService.shortAddress : 'ID 325234'} / Easy Games',
          balanceLabel: '${formatWeiToEth(totalEarnedWei)} $currency',
          onRefresh: levelsProvider.fetchLevels,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;

              int crossAxisCount = width < 480
                  ? 2
                  : width < 800
                      ? 2
                      : width < 1200
                          ? 3
                          : 4;

              double childAspectRatio = width < 480
                  ? 0.82
                  : width < 800
                      ? 1.05
                      : 1.26;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              walletAddress == null
                                  ? 'ID 325234 / Easy Games'
                                  : "Preview ${walletAddress!.substring(0, 6)}...${walletAddress!.substring(walletAddress!.length - 4)} / Easy Games",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'levels.title'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${formatWeiToEth(levelsProvider.totalEarnedWei)} $currency",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202223).withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          if (errorMessage.isNotEmpty)
                            _LevelStateBanner(
                              message: errorMessage,
                              onRefresh: levelsProvider.fetchLevels,
                            ),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(),
                            ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemCount: levelCount,
                            itemBuilder: (context, index) {
                              final level = levelsProvider.levels[index];
                              return _LevelCardPresenter(
                                level: level,
                                currencySymbol: currency,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF426CF8),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.help,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'levels.marketingLegend'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'levels.pricesCurrency'.tr,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const BottomTableSection(),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class EasyGameLevelDetailScreen extends StatelessWidget {
  final int level;

  const EasyGameLevelDetailScreen({Key? key, required this.level})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tag = 'level-detail-$level';
    return GetX<LevelDetailController>(
      init: LevelDetailController(level: level),
      tag: tag,
      dispose: (_) {
        if (Get.isRegistered<LevelDetailController>(tag: tag)) {
          Get.delete<LevelDetailController>(tag: tag);
        }
      },
      builder: (detailController) {
        final walletService = Get.find<WalletConnectService>();
        detailController.snapshot.value;
        detailController.isLoading.value;
        detailController.errorMessage.value;
        return ExpressAppShell(
          title: 'levels.levelTitle'.trParams({'level': '$level'}),
          breadcrumb: 'levels.breadcrumbLevel'.trParams({'level': '$level'}),
          activeSection: 'Dashboard',
          onRefresh: detailController.refreshDetail,
          child: Obx(
            () {
              final data = detailController.snapshot.value;
              final width = MediaQuery.of(context).size.width;
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: width < 700 ? 0 : 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(
                      () => Text(
                        walletService.isConnected.value
                            ? 'levels.walletBreadcrumb'.trParams({
                                'wallet': walletService.shortAddress,
                                'level': '$level',
                              })
                            : 'levels.previewBreadcrumb'
                                .trParams({'level': '$level'}),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _LevelNavButton(
                          label: 'levels.levelTitle'.trParams(
                              {'level': '${level <= 1 ? 1 : level - 1}'}),
                          icon: Icons.arrow_back_ios,
                          enabled: level > 1,
                          onTap: () => Get.off(
                            () => EasyGameLevelDetailScreen(level: level - 1),
                          ),
                        ),
                        _LevelNavButton(
                          label: 'levels.levelTitle'.trParams({
                            'level':
                                '${level >= easyGameLevelCount ? easyGameLevelCount : level + 1}'
                          }),
                          icon: Icons.arrow_forward_ios,
                          trailing: true,
                          enabled: level < easyGameLevelCount,
                          onTap: () => Get.off(
                            () => EasyGameLevelDetailScreen(level: level + 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (detailController.isLoading.value)
                      const LinearProgressIndicator(),
                    if (detailController.errorMessage.value.isNotEmpty)
                      _LevelStateBanner(
                        message: 'levels.unableLoadDetails'.trParams(
                            {'error': detailController.errorMessage.value}),
                        onRefresh: detailController.refreshDetail,
                      ),
                    if (data != null) ...[
                      _LevelHeroPanel(
                        level: level,
                        priceWei: data.priceWei,
                        stateLabel: detailController.stateLabel(data),
                        progress: detailController.fillPercent(data),
                        walletLabel: walletService.isConnected.value
                            ? walletService.shortAddress
                            : 'common.notConnected'.tr,
                        onActivate: data.state.active
                            ? null
                            : () {
                                Get.to(() => RegistrationScreen(
                                      LevelStatus.waiting,
                                      level: level,
                                      amount: weiToEthDouble(data.priceWei),
                                      inviter: walletService.activeInviter,
                                    ));
                              },
                      ),
                      const SizedBox(height: 16),
                      _LevelStatsStrip(
                        stats: [
                          DetailRow(
                            'levelDetail.prizePool'.tr,
                            '${formatWeiToEth(data.advanceStats.prizePoolWei)} ${walletService.nativeSymbol}',
                          ),
                          DetailRow('levelDetail.playerWeight'.tr,
                              data.playerWeight.toString()),
                          DetailRow('levelDetail.chance'.tr,
                              formatBpsToPercent(data.playerChanceBps)),
                          DetailRow('levelDetail.boxTokens'.tr,
                              data.player?.boxTokens.toString() ?? '0'),
                          DetailRow('levelDetail.cycles'.tr,
                              data.state.cycles.toString()),
                          DetailRow('levelDetail.earned'.tr,
                              '${formatWeiToEth(data.state.earnedWei)} ${walletService.nativeSymbol}'),
                          DetailRow('levelDetail.position'.tr,
                              data.state.positionId.toString()),
                          DetailRow('levelDetail.matrixSize'.tr,
                              data.stats.size.toString()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LevelMatrixPanel(
                        level: level,
                        positionId: data.state.positionId,
                        nextOpenParentId: data.advanceStats.nextOpenParentId,
                        nextCellId: data.advanceStats.nextCellId,
                        activeCells: data.advanceStats.activeCells,
                        isFrozen: data.state.frozen,
                      ),
                      const SizedBox(height: 16),
                      _LevelDetailPanel(
                        title: 'levelDetail.contractData'.tr,
                        rows: [
                          DetailRow('levelDetail.matrixType'.tr,
                              'levelDetail.binaryMatrix'.tr),
                          DetailRow('levelDetail.rewardModel'.tr,
                              'levelDetail.rewardModelValue'.tr),
                          DetailRow('levelDetail.totalWeight'.tr,
                              data.advanceStats.totalWeight.toString()),
                          DetailRow('levelDetail.activeCells'.tr,
                              data.advanceStats.activeCells.toString()),
                        ],
                      ),
                      _LevelDetailPanel(
                        title: 'levelDetail.liveState'.tr,
                        rows: [
                          DetailRow(
                              'common.active'.tr,
                              data.state.active
                                  ? 'common.yes'.tr
                                  : 'common.no'.tr),
                          DetailRow(
                              'common.frozen'.tr,
                              data.state.frozen
                                  ? 'common.yes'.tr
                                  : 'common.no'.tr),
                          DetailRow(
                            'levelDetail.nextOpenParent'.tr,
                            data.stats.nextOpenParentId.toString(),
                          ),
                          DetailRow(
                            'levels.currentLineFill'.tr,
                            data.stats.size == BigInt.zero
                                ? 'levelDetail.noMatrixData'.tr
                                : '${detailController.fillPercent(data).toStringAsFixed(2)}%',
                          ),
                        ],
                      ),
                      _LevelClaimPanel(
                        level: level,
                        player: data.player,
                        isFrozen: data.state.frozen,
                      ),
                      const SizedBox(height: 12),
                      _LevelEventsTable(level: level),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
