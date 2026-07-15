import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';
import 'package:lottery_advance/app/models/game_round_models.dart';
import 'package:lottery_advance/app/models/game_transaction_model.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/modules/home/widgets/game_round_presentation.dart';

import '../models/levels_models.dart';
import '../models/round_level_card_state.dart';
import '../controllers/levels_provider.dart';
import '../controllers/level_detail_controller.dart';
import '../widgets/round_card_timer.dart';
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
        final connected = walletService.isConnected.value;
        final identity = walletAddress?.isNotEmpty == true
            ? _shortLevelIdentity(walletAddress!)
            : connected
                ? walletService.shortAddress
                : 'common.notConnected'.tr;
        return ExpressAppShell(
          title: 'levels.title'.tr,
          breadcrumb: '$identity / Easy Games',
          onRefresh: levelsProvider.refreshAll,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double width = constraints.maxWidth;

              int crossAxisCount = width < 600
                  ? 1
                  : width < 800
                      ? 2
                      : width < 1200
                          ? 3
                          : 4;

              double childAspectRatio = width < 600
                  ? 1.18
                  : width < 800
                      ? 0.9
                      : 1.26;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flex(
                      direction: width < 700 ? Axis.vertical : Axis.horizontal,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: width < 700
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                walletAddress == null
                                    ? '$identity / Easy Games'
                                    : 'Preview $identity / Easy Games',
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
                        ),
                        if (width < 700) const SizedBox(height: 14),
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
                    Column(
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
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.question_circle,
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
                        Text(
                          'levels.pricesCurrency'.tr,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    BottomTableSection(
                      transactions: levelsProvider.transactions.toList(),
                      isLoading: levelsProvider.isTransactionsLoading.value,
                      errorMessage: levelsProvider.transactionsError.value,
                      onRefresh: levelsProvider.refreshAll,
                    ),
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

String _shortLevelIdentity(String value) {
  if (value.length <= 13) return value;
  return '${value.substring(0, 7)}...${value.substring(value.length - 4)}';
}

class EasyGameLevelDetailScreen extends StatelessWidget {
  final int level;
  final BigInt roundId;

  const EasyGameLevelDetailScreen({
    Key? key,
    required this.level,
    required this.roundId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tag = 'level-detail-$roundId';
    return GetX<LevelDetailController>(
      init: LevelDetailController(level: level, roundId: roundId),
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
              final previousRoundId = level > 1
                  ? detailController.roundIdForLevel(level - 1)
                  : null;
              final nextRoundId = level < easyGameLevelCount
                  ? detailController.roundIdForLevel(level + 1)
                  : null;
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
                          icon: CupertinoIcons.chevron_back,
                          enabled: previousRoundId != null,
                          onTap: () => Get.off(
                            () => EasyGameLevelDetailScreen(
                              level: level - 1,
                              roundId: previousRoundId!,
                            ),
                          ),
                        ),
                        _LevelNavButton(
                          label: 'levels.levelTitle'.trParams({
                            'level':
                                '${level >= easyGameLevelCount ? easyGameLevelCount : level + 1}'
                          }),
                          icon: CupertinoIcons.chevron_forward,
                          trailing: true,
                          enabled: nextRoundId != null,
                          onTap: () => Get.off(
                            () => EasyGameLevelDetailScreen(
                              level: level + 1,
                              roundId: nextRoundId!,
                            ),
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
                        priceWei: data.card.ethPriceWei,
                        stateLabel: detailController.stateLabel(data),
                        progress: detailController.fillPercent(data),
                        walletLabel: walletService.isConnected.value
                            ? walletService.shortAddress
                            : 'common.notConnected'.tr,
                        onActivate:
                            data.card.isPlayerActive || !data.card.canEnter
                                ? null
                                : () {
                                    Get.to(() => RegistrationScreen(
                                          LevelStatus.waiting,
                                          level: level,
                                          inviter: walletService.activeInviter,
                                          round: data.card.round,
                                        ));
                                  },
                      ),
                      const SizedBox(height: 16),
                      _LevelStatsStrip(
                        stats: [
                          DetailRow(
                            'levelDetail.prizePool'.tr,
                            '${formatWeiToEth(data.card.prizePoolWei)} ${walletService.nativeSymbol}',
                          ),
                          DetailRow('levelDetail.playerWeight'.tr,
                              data.card.playerWeight.toString()),
                          DetailRow('levelDetail.chance'.tr,
                              formatBpsToPercent(data.card.playerChanceBps)),
                          DetailRow('levelDetail.boxTokens'.tr,
                              data.player?.boxTokens.toString() ?? '0'),
                          DetailRow('levelDetail.cycles'.tr,
                              data.card.cycles.toString()),
                          DetailRow('levelDetail.earned'.tr,
                              '${formatWeiToEth(data.settlement.ethAmount)} ${walletService.nativeSymbol}'),
                          DetailRow('levelDetail.position'.tr,
                              data.card.positionId.toString()),
                          DetailRow('levelDetail.matrixSize'.tr,
                              '${data.card.round?.schedule.maxPlayers ?? 0}'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _LevelMatrixPanel(
                        level: level,
                        positionId: data.card.positionId,
                        nextOpenParentId:
                            data.card.matrix?.nextOpenParentId ?? BigInt.zero,
                        nextCellId: data.card.matrix?.nextCellId ?? BigInt.zero,
                        activeCells: data.card.activeCells,
                        isFrozen: data.card.isFrozen,
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
                              data.card.totalWeight.toString()),
                          DetailRow('levelDetail.activeCells'.tr,
                              data.card.activeCells.toString()),
                          DetailRow(
                              'levelDetail.roundId'.tr, roundId.toString()),
                        ],
                      ),
                      _LevelDetailPanel(
                        title: 'levelDetail.liveState'.tr,
                        rows: [
                          DetailRow(
                              'common.active'.tr,
                              data.card.isPlayerActive
                                  ? 'common.yes'.tr
                                  : 'common.no'.tr),
                          DetailRow(
                              'common.frozen'.tr,
                              data.card.isFrozen
                                  ? 'common.yes'.tr
                                  : 'common.no'.tr),
                          DetailRow(
                            'levelDetail.nextOpenParent'.tr,
                            (data.card.matrix?.nextOpenParentId ?? BigInt.zero)
                                .toString(),
                          ),
                          DetailRow(
                            'levels.currentLineFill'.tr,
                            data.card.matrix == null
                                ? 'levelDetail.noMatrixData'.tr
                                : '${detailController.fillPercent(data).toStringAsFixed(2)}%',
                          ),
                        ],
                      ),
                      _LevelClaimPanel(
                        data: data,
                        controller: detailController,
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
