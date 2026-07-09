import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/app_shell.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/services/firebase_data_service.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';
import '../models/levels_models.dart';

part '../models/utility_screen_models.dart';
part '../controllers/statistics_controller.dart';
part '../controllers/matrix_arena_controller.dart';
part '../controllers/member_preview_controller.dart';
part '../widgets/utility_common_widgets.dart';
part '../widgets/matrix_arena_widgets.dart';
part '../widgets/matrix_stats_widgets.dart';
part '../widgets/matrix_picker_widgets.dart';
part '../widgets/matrix_tree_widgets.dart';
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
      dispose: (_) => Get.delete<_StatisticsController>(),
      builder: (statisticsController) {
        final walletService = Get.find<WalletConnectService>();
        return Obx(
          () {
            final data = statisticsController.snapshot.value;
            final currency = walletService.nativeSymbol;
            return _UtilityScaffold(
              title: 'nav.stats'.tr,
              activeSection: 'Statistics',
              icon: Icons.bar_chart,
              onRefresh: statisticsController.refreshStats,
              children: [
                if (statisticsController.isLoading.value)
                  const LinearProgressIndicator(
                    color: EasyGameTheme.teal,
                    backgroundColor: EasyGameTheme.border,
                  ),
                if (statisticsController.isLoading.value)
                  const SizedBox(height: 18),
                if (statisticsController.errorMessage.value.isNotEmpty)
                  _InfoBlock(
                    title: 'common.notLoaded'.tr,
                    text: statisticsController.errorMessage.value,
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
                        icon: Icons.groups_2_outlined,
                        title: 'stats.participants'.tr,
                        value: data?.matrixNodes.toString() ?? '-',
                        delta: '+ ${data?.activeLevels ?? 0}',
                        color: EasyGameTheme.teal,
                      ),
                      _ArenaStatCard(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'stats.prizeVolume'.tr,
                        value: data == null
                            ? '-'
                            : '${_formatWei(data.totalPrizePoolWei)} $currency',
                        delta: '75.5%',
                        color: Colors.greenAccent,
                      ),
                      _ArenaStatCard(
                        icon: Icons.sync_alt,
                        title: 'stats.transactions'.tr,
                        value: data?.matrixNodes.toString() ?? '-',
                        delta: '+${data?.frozenLevels ?? 0} frozen',
                        color: EasyGameTheme.orange,
                      ),
                      _ArenaStatCard(
                        icon: Icons.trending_up,
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
                  icon: Icons.description,
                ),
              ],
            );
          },
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
      dispose: (_) => Get.delete<_MatrixArenaController>(),
      builder: (matrixController) {
        final walletService = Get.find<WalletConnectService>();
        return Obx(
          () {
            final selectedLevel = matrixController.selectedLevel.value;
            final data = matrixController.snapshot.value;
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
                      if (matrixController.isLoading.value)
                        const LinearProgressIndicator(
                          color: EasyGameTheme.teal,
                          backgroundColor: EasyGameTheme.border,
                        ),
                      if (matrixController.isLoading.value)
                        const SizedBox(height: 18),
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
      dispose: (_) => Get.delete<_MemberPreviewController>(tag: tag),
      builder: (previewController) {
        final walletService = Get.find<WalletConnectService>();
        return Obx(
          () {
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
              icon: Icons.manage_search,
              onRefresh: previewController.refreshPreview,
              children: [
                if (previewController.isLoading.value)
                  const LinearProgressIndicator(
                    color: EasyGameTheme.teal,
                    backgroundColor: EasyGameTheme.border,
                  ),
                if (previewController.isLoading.value) const SizedBox(height: 18),
                if (previewController.errorMessage.value.isNotEmpty)
                  _InfoBlock(
                    title: 'common.notLoaded'.tr,
                    text: previewController.errorMessage.value,
                  ),
                _StatusCard(
                  title: data.isWallet
                      ? 'utility.walletAddress'.tr
                      : 'utility.memberId'.tr,
                  value: data.isWallet ? data.normalizedAddress : query,
                  icon: data.isWallet ? Icons.account_balance_wallet : Icons.badge,
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
                  icon: Icons.payments,
                ),
                _ActionTile(
                  icon: Icons.grid_view,
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
      icon: Icons.info_outline,
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
      icon: Icons.telegram,
      children: [
        _ActionTile(
          icon: Icons.notifications_active,
          title: 'nav.notifierBot'.tr,
          subtitle: 'utility.openNotifierSetup'.tr,
          onTap: () => Get.to(() => NotifierBotScreen()),
        ),
        _ActionTile(
          icon: Icons.support_agent,
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
      icon: Icons.campaign,
      children: [
        _InfoBlock(
          title: 'utility.partnerLink'.tr,
          text: link,
        ),
        _ActionTile(
          icon: Icons.copy,
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
          icon: Icons.play_arrow,
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
      icon: Icons.notifications,
      children: [
        Obx(
          () => _StatusCard(
            title: 'utility.walletNotifications'.tr,
            value: walletService.isConnected.value
                ? 'utility.readyFor'
                    .trParams({'wallet': walletService.shortAddress})
                : 'utility.connectWalletFirst'.tr,
            icon: Icons.account_circle,
          ),
        ),
        _InfoBlock(
          title: 'utility.eventsToNotify'.tr,
          text: 'utility.eventsToNotifyText'.tr,
        ),
        _ActionTile(
          icon: Icons.settings,
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
      icon: Icons.settings,
      children: [
        Obx(
          () => _StatusCard(
            title: 'utility.connectedWallet'.tr,
            value: walletService.isConnected.value
                ? walletService.currentAddress.value
                : 'common.notConnected'.tr,
            icon: Icons.account_balance_wallet,
          ),
        ),
        Obx(
          () => _StatusCard(
            title: 'utility.chainId'.tr,
            value:
                walletService.chainId.value?.toString() ?? 'common.unknown'.tr,
            icon: Icons.language,
          ),
        ),
        _ActionTile(
          icon: Icons.network_check,
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
          icon: Icons.logout,
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
      icon: Icons.support_agent,
      children: [
        _InfoBlock(
          title: 'utility.supportStatus'.tr,
          text: 'utility.supportStatusText'.tr,
        ),
        _ActionTile(
          icon: Icons.email,
          title: 'utility.emailSupport'.tr,
          subtitle: 'utility.openMailDraft'.tr,
          onTap: _showContactUnavailable,
        ),
        _ActionTile(
          icon: Icons.telegram,
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
      icon: Icons.school,
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
      icon: Icons.history,
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
