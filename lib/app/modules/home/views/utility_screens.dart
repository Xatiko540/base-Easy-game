import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/services/firebase_data_service.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/app/models/matrix_round_models.dart';
import 'package:lottery_advance/app/models/game_round_settlement_models.dart';
import 'package:lottery_advance/app/models/game_round_phase.dart';
import 'package:lottery_advance/app/modules/home/controllers/game_rounds_controller.dart';
import 'package:lottery_advance/app/services/game_settlement_service.dart';
import 'package:lottery_advance/app/services/game_round_blockchain_service.dart';
import 'package:lottery_advance/utils/theme.dart';
import '../models/levels_models.dart';
import '../widgets/neon_honeycomb.dart';

part '../models/utility_screen_models.dart';
part '../controllers/statistics_controller.dart';
part '../controllers/matrix_arena_controller.dart';
part '../controllers/member_preview_controller.dart';
part '../widgets/utility_common_widgets.dart';
part '../widgets/matrix_arena_widgets.dart';
part '../widgets/matrix_stats_widgets.dart';
part '../widgets/matrix_picker_widgets.dart';
part '../widgets/matrix_tree_widgets.dart';
part '../widgets/neon_honeycomb_widget.dart';
part '../widgets/information_widgets.dart';
part '../widgets/information_panels_widgets.dart';
part '../widgets/information_diagram_widgets.dart';
part '../widgets/information_common_widgets.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<_StatisticsController>(
      init: _StatisticsController(),
      dispose: (_) {
        if (Get.isRegistered<_StatisticsController>()) {
          Get.delete<_StatisticsController>();
        }
      },
      builder: (statisticsController) {
        final walletService = Get.find<WalletConnectService>();
        final data = statisticsController.snapshot.value;
        final loading = statisticsController.isLoading.value;
        final errorMessage = statisticsController.errorMessage.value;
        final currency = walletService.nativeSymbol;
        return _UtilityScaffold(
          title: 'nav.stats'.tr,
          activeSection: 'Statistics',
          icon: CupertinoIcons.chart_bar,
          onRefresh: statisticsController.refreshStats,
          children: [
            if (loading)
              const LinearProgressIndicator(
                color: EasyGameTheme.teal,
                backgroundColor: EasyGameTheme.border,
              ),
            if (loading) const SizedBox(height: 18),
            if (errorMessage.isNotEmpty)
              _InfoBlock(
                title: 'common.notLoaded'.tr,
                text: errorMessage,
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 520
                    ? 1
                    : constraints.maxWidth < 900
                        ? 2
                        : 4;
                final cards = [
                  _ArenaStatCard(
                    icon: CupertinoIcons.person_2,
                    title: 'stats.participants'.tr,
                    value: data?.matrixNodes.toString() ?? '-',
                    delta: '+ ${data?.activeLevels ?? 0}',
                    color: EasyGameTheme.teal,
                  ),
                  _ArenaStatCard(
                    icon: CupertinoIcons.creditcard,
                    title: 'stats.prizeVolume'.tr,
                    value: data == null
                        ? '-'
                        : '${_formatWei(data.totalPrizePoolWei)} $currency',
                    delta: '75.5%',
                    color: Colors.greenAccent,
                  ),
                  _ArenaStatCard(
                    icon: CupertinoIcons.arrow_clockwise,
                    title: 'stats.transactions'.tr,
                    value: data?.matrixNodes.toString() ?? '-',
                    delta: '+${data?.frozenLevels ?? 0} frozen',
                    color: EasyGameTheme.orange,
                  ),
                  _ArenaStatCard(
                    icon: CupertinoIcons.arrow_up_right,
                    title: 'stats.weight'.tr,
                    value: data?.totalWeight.toString() ?? '-',
                    delta: 'weighted draw',
                    color: EasyGameTheme.purple,
                  ),
                ];
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    mainAxisExtent: 170,
                  ),
                  itemBuilder: (context, index) => cards[index],
                );
              },
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final distribution = _PayoutDistributionPanel(
                  totalPrizePoolWei: data?.totalPrizePoolWei ?? BigInt.zero,
                  currency: currency,
                );
                final levels = _LevelVolumePanel(
                  rows: data?.levelRows ?? const <_LevelArenaStat>[],
                  currency: currency,
                );
                if (compact) {
                  return Column(
                    children: [
                      distribution,
                      levels,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: distribution),
                    const SizedBox(width: 18),
                    Expanded(flex: 7, child: levels),
                  ],
                );
              },
            ),
            _InfoBlock(
              title: 'stats.strategyTitle'.tr,
              text: 'stats.strategyText'.tr,
            ),
            _StatusCard(
              title: 'utility.easyGameContract'.tr,
              value: data == null
                  ? 'common.loading'.tr
                  : _shortAddress(data.contractAddress),
              icon: CupertinoIcons.doc_text,
            ),
          ],
        );
      },
    );
  }
}

class MatrixArenaScreen extends StatelessWidget {
  const MatrixArenaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetX<_MatrixArenaController>(
      init: _MatrixArenaController(),
      dispose: (_) {
        if (Get.isRegistered<_MatrixArenaController>()) {
          Get.delete<_MatrixArenaController>();
        }
      },
      builder: (matrixController) {
        final walletService = Get.find<WalletConnectService>();
        final selectedLevel = matrixController.selectedLevel.value;
        final data = matrixController.snapshot.value;
        final loading = matrixController.isLoading.value;
        final errorMessage = matrixController.errorMessage.value;
        return ExpressAppShell(
          title: 'matrix.title'.tr,
          breadcrumb: '${'app.name'.tr} / ${'nav.matrix'.tr}',
          activeSection: 'Matrix',
          onRefresh: matrixController.refreshArena,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'matrix.subtitle'.tr,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (loading)
                    const LinearProgressIndicator(
                      color: EasyGameTheme.teal,
                      backgroundColor: EasyGameTheme.border,
                    ),
                  if (loading) const SizedBox(height: 18),
                  if (errorMessage.isNotEmpty) ...[
                    _InfoBlock(
                      title: 'common.notLoaded'.tr,
                      text: errorMessage,
                    ),
                    const SizedBox(height: 18),
                  ],
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 900;
                      final side = SizedBox(
                        width: compact ? double.infinity : 360,
                        child: Column(
                          children: [
                            _MatrixLevelPicker(
                              selectedLevel: selectedLevel,
                              onChanged: matrixController.selectLevel,
                            ),
                            const SizedBox(height: 18),
                            _MatrixLegend(),
                          ],
                        ),
                      );
                      final panel = _MatrixArenaPanel(
                        data: data,
                        currency: walletService.nativeSymbol,
                        selectedOpponent:
                            matrixController.selectedOpponent.value,
                        actionsBusy:
                            matrixController.isSkillActionRunning.value,
                        onSelectOpponent: matrixController.selectOpponent,
                        onBuyFreeze: () => matrixController.buyFreezeSkill(),
                        onFreeze: () =>
                            matrixController.freezeClosestOpponent(),
                        onUnfreeze: () => matrixController.buyUnfreezeSkill(),
                        onSettle: () => matrixController.settleRound(),
                        onClaimSettlement: () =>
                            matrixController.claimSettlementPrize(),
                      );
                      if (compact) {
                        return Column(
                          children: [
                            side,
                            const SizedBox(height: 22),
                            panel,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          side,
                          const SizedBox(width: 22),
                          Expanded(child: panel),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class MemberPreviewScreen extends StatelessWidget {
  final String query;

  const MemberPreviewScreen({
    Key? key,
    required this.query,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tag = 'member-preview-$query';
    return GetX<_MemberPreviewController>(
      init: _MemberPreviewController(query: query),
      tag: tag,
      dispose: (_) {
        if (Get.isRegistered<_MemberPreviewController>(tag: tag)) {
          Get.delete<_MemberPreviewController>(tag: tag);
        }
      },
      builder: (previewController) {
        final walletService = Get.find<WalletConnectService>();
        final loading = previewController.isLoading.value;
        final errorMessage = previewController.errorMessage.value;
        final data = previewController.snapshot.value ??
            _MemberPreviewSnapshot(
              query: query,
              normalizedAddress: ReferralLinkService.normalizeAddress(
                query,
              ),
              levels: const [],
            );

        return _UtilityScaffold(
          title: 'utility.memberPreview'.tr,
          icon: CupertinoIcons.slider_horizontal_3,
          onRefresh: previewController.refreshPreview,
          children: [
            if (loading)
              const LinearProgressIndicator(
                color: EasyGameTheme.teal,
                backgroundColor: EasyGameTheme.border,
              ),
            if (loading) const SizedBox(height: 18),
            if (errorMessage.isNotEmpty)
              _InfoBlock(
                title: 'common.notLoaded'.tr,
                text: errorMessage,
              ),
            _StatusCard(
              title: data.isWallet
                  ? 'utility.walletAddress'.tr
                  : 'utility.memberId'.tr,
              value: data.isWallet ? data.normalizedAddress : query,
              icon: data.isWallet ? CupertinoIcons.creditcard : CupertinoIcons.creditcard,
            ),
            if (!data.isWallet)
              _InfoBlock(
                title: 'utility.idLookup'.tr,
                text: 'utility.idLookupText'.tr,
              ),
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'utility.activeLevels'.tr,
                    value: data.isWallet
                        ? previewController.snapshot.value == null
                            ? '-'
                            : data.activeCount.toString()
                        : 'common.notAvailable'.tr,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    title: 'utility.frozenLevels'.tr,
                    value: data.isWallet
                        ? previewController.snapshot.value == null
                            ? '-'
                            : data.frozenCount.toString()
                        : 'common.notAvailable'.tr,
                  ),
                ),
              ],
            ),
            _StatusCard(
              title: 'utility.earnedOnLevels'.tr,
              value: data.isWallet
                  ? previewController.snapshot.value == null
                      ? 'common.loading'.tr
                      : '${_formatWei(data.earnedWei)} ${walletService.nativeSymbol}'
                  : 'common.notAvailable'.tr,
              icon: CupertinoIcons.money_dollar_circle,
            ),
            _ActionTile(
              icon: CupertinoIcons.square_grid_2x2,
              title: 'utility.openLevels'.tr,
              subtitle: data.isWallet
                  ? 'utility.openFiltered'.tr
                  : 'utility.openProgramView'.tr,
              onTap: () => Get.to(
                () => LevelsScreen(
                  walletAddress: data.isWallet ? data.normalizedAddress : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class InformationScreen extends StatelessWidget {
  const InformationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'nav.information'.tr,
      activeSection: 'Information',
      icon: CupertinoIcons.info,
      children: [
        _InfoHeroCard(
          title: 'info.advanceTitle'.tr,
          text: 'info.advanceText'.tr,
        ),
        _InfoBlock(
          title: 'info.matrixTitle'.tr,
          text: 'info.matrixText'.tr,
        ),
        const _InfoMatrixStructurePanel(),
        _InfoBlock(
          title: 'info.rewardTitle'.tr,
          text: 'info.rewardText'.tr,
        ),
        const _InfoPaymentSplitPanel(),
        const _InfoRoundLifecyclePanel(),
        const _InfoWinningCellsPanel(),
        _InfoBlock(
          title: 'info.freezeTitle'.tr,
          text: 'info.freezeText'.tr,
        ),
        const _InfoGameResourcesPanel(),
      ],
    );
  }
}

class TelegramBotsScreen extends StatelessWidget {
  const TelegramBotsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'nav.telegramBots'.tr,
      activeSection: 'Telegram',
      icon: CupertinoIcons.paperplane_fill,
      children: [
        _ActionTile(
          icon: CupertinoIcons.bell_fill,
          title: 'nav.notifierBot'.tr,
          subtitle: 'utility.openNotifierSetup'.tr,
          onTap: () => Get.to(() => NotifierBotScreen()),
        ),
        _ActionTile(
          icon: CupertinoIcons.headphones,
          title: 'common.support'.tr,
          subtitle: 'utility.openSupportChannels'.tr,
          onTap: () => Get.to(() => const SupportScreen()),
        ),
        _InfoBlock(
          title: 'utility.configuration'.tr,
          text: 'utility.telegramConfigText'.tr,
        ),
      ],
    );
  }
}

class PromoScreen extends StatelessWidget {
  PromoScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    final link = ReferralLinkService.buildReferralLink(
      walletService.currentAddress.value,
    );

    return _UtilityScaffold(
      title: 'nav.promo'.tr,
      activeSection: 'Promo',
      icon: CupertinoIcons.hifispeaker,
      children: [
        _InfoBlock(
          title: 'utility.partnerLink'.tr,
          text: link,
        ),
        _ActionTile(
          icon: CupertinoIcons.doc_on_doc,
          title: 'utility.copyPartnerLink'.tr,
          subtitle: 'utility.copyInviteUrl'.tr,
          onTap: () {
            Clipboard.setData(ClipboardData(text: link));
            Get.snackbar(
              'common.copied'.tr,
              link,
              snackPosition: SnackPosition.BOTTOM,
            );
          },
        ),
        _ActionTile(
          icon: CupertinoIcons.play_arrow,
          title: 'utility.openLevels'.tr,
          subtitle: 'utility.openProgramView'.tr,
          onTap: () => Get.to(() => LevelsScreen()),
        ),
      ],
    );
  }
}

class NotifierBotScreen extends StatelessWidget {
  NotifierBotScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'nav.notifierBot'.tr,
      activeSection: 'Notifier',
      icon: CupertinoIcons.bell,
      children: [
        Obx(
          () => _StatusCard(
            title: 'utility.walletNotifications'.tr,
            value: walletService.isConnected.value
                ? 'utility.readyFor'
                    .trParams({'wallet': walletService.shortAddress})
                : 'utility.connectWalletFirst'.tr,
            icon: CupertinoIcons.person_crop_circle,
          ),
        ),
        _InfoBlock(
          title: 'utility.eventsToNotify'.tr,
          text: 'utility.eventsToNotifyText'.tr,
        ),
        _ActionTile(
          icon: CupertinoIcons.gear,
          title: 'utility.notificationSettings'.tr,
          subtitle: 'utility.notificationSettingsText'.tr,
          onTap: () => Get.to(() => SettingsScreen()),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key? key}) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'common.settings'.tr,
      icon: CupertinoIcons.gear,
      children: [
        Obx(
          () => _StatusCard(
            title: 'utility.connectedWallet'.tr,
            value: walletService.isConnected.value
                ? walletService.currentAddress.value
                : 'common.notConnected'.tr,
            icon: CupertinoIcons.creditcard,
          ),
        ),
        Obx(
          () => _StatusCard(
            title: 'utility.chainId'.tr,
            value:
                walletService.chainId.value?.toString() ?? 'common.unknown'.tr,
            icon: CupertinoIcons.globe,
          ),
        ),
        _ActionTile(
          icon: CupertinoIcons.wifi,
          title: 'utility.checkNetwork'.tr,
          subtitle: 'utility.checkNetworkText'.tr,
          onTap: () async {
            try {
              await walletService.ensureBaseNetwork();
              Get.snackbar(
                'utility.networkOk'.tr,
                'utility.walletOnNetwork'
                    .trParams({'network': walletService.networkLabel}),
                snackPosition: SnackPosition.BOTTOM,
              );
            } catch (e) {
              Get.snackbar(
                'utility.networkFailed'.tr,
                '$e',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
        ),
        _ActionTile(
          icon: CupertinoIcons.square_arrow_left,
          title: 'utility.disconnectWallet'.tr,
          subtitle: 'utility.disconnectWalletText'.tr,
          onTap: () {
            walletService.disconnectWallet();
            Get.offAllNamed('/home');
          },
        ),
      ],
    );
  }
}

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'common.support'.tr,
      icon: CupertinoIcons.headphones,
      children: [
        _InfoBlock(
          title: 'utility.supportStatus'.tr,
          text: 'utility.supportStatusText'.tr,
        ),
        _ActionTile(
          icon: CupertinoIcons.envelope,
          title: 'utility.emailSupport'.tr,
          subtitle: 'utility.openMailDraft'.tr,
          onTap: _showContactUnavailable,
        ),
        _ActionTile(
          icon: CupertinoIcons.paperplane_fill,
          title: 'nav.telegramChannel'.tr,
          subtitle: 'utility.telegramChannelText'.tr,
          onTap: _showContactUnavailable,
        ),
      ],
    );
  }
}

class ExpressInfoScreen extends StatelessWidget {
  const ExpressInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'utility.about'.tr,
      icon: CupertinoIcons.book,
      children: [
        _InfoBlock(
          title: 'utility.smartContractGame'.tr,
          text: 'utility.smartContractGameText'.tr,
        ),
        _InfoBlock(
          title: 'utility.userFlow'.tr,
          text: 'utility.userFlowText'.tr,
        ),
      ],
    );
  }
}

class RecentActivityScreen extends StatelessWidget {
  const RecentActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _UtilityScaffold(
      title: 'utility.recentActivity'.tr,
      icon: CupertinoIcons.clock,
      children: [
        _InfoBlock(
          title: 'utility.currentState'.tr,
          text: 'utility.currentStateText'.tr,
        ),
        _InfoBlock(
          title: 'utility.events'.tr,
          text: 'utility.eventsText'.tr,
        ),
      ],
    );
  }
}
