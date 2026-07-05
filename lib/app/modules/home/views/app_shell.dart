import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/language_selector.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';

import '../../../services/Notifications.dart';

class ExpressAppShell extends StatelessWidget {
  final Widget child;
  final String title;
  final String? breadcrumb;
  final String? balanceLabel;
  final VoidCallback? onRefresh;
  final String? activeSection;

  ExpressAppShell({
    Key? key,
    required this.child,
    required this.title,
    this.breadcrumb,
    this.balanceLabel,
    this.onRefresh,
    this.activeSection,
  }) : super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EasyGameTheme.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 920;
          return Stack(
            children: [
              Row(
                children: [
                  if (showSidebar)
                    _ExpressSidebar(activeSection: activeSection ?? title),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(
                              color: EasyGameTheme.page,
                              gradient: EasyGameTheme.shellGlow,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: SafeArea(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                showSidebar ? 32 : 18,
                                showSidebar ? 92 : 86,
                                showSidebar ? 32 : 18,
                                24,
                              ),
                              child: child,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: _ExpressTopBar(
                              title: title,
                              breadcrumb: breadcrumb,
                              balanceLabel: balanceLabel,
                              onRefresh: onRefresh,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const _FloatingHelpButtons(),
            ],
          );
        },
      ),
    );
  }
}

class _ExpressSidebar extends StatelessWidget {
  final String activeSection;

  const _ExpressSidebar({required this.activeSection});

  bool _isSelected(String value) =>
      activeSection.toLowerCase().contains(value.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 214,
      decoration: const BoxDecoration(
        color: EasyGameTheme.shell,
        border: Border(right: BorderSide(color: EasyGameTheme.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 18, 34),
              child: _ExpressLogo(),
            ),
            _ShellNavItem(
              icon: Icons.grid_view_rounded,
              label: 'nav.dashboard'.tr,
              selected: _isSelected('Dashboard') || _isSelected('Profile'),
              onTap: () => Get.toNamed('/profile'),
            ),
            _ShellNavItem(
              icon: Icons.grid_on_rounded,
              label: 'nav.easyGames'.tr,
              selected: _isSelected('Levels') || _isSelected('Easy Games'),
              onTap: UiNavigationService.openLevels,
            ),
            _ShellNavItem(
              icon: Icons.account_tree_outlined,
              label: 'nav.matrix'.tr,
              selected: _isSelected('Matrix'),
              onTap: UiNavigationService.openMatrix,
            ),
            _ShellNavItem(
              icon: Icons.donut_large,
              label: 'nav.stats'.tr,
              selected: _isSelected('Statistics') || _isSelected('Stats'),
              onTap: UiNavigationService.openStatistics,
            ),
            _ShellNavItem(
              icon: Icons.group_outlined,
              label: 'nav.partnerBonus'.tr,
              selected: _isSelected('Partner'),
              onTap: () => Get.toNamed('/partner-bonus'),
            ),
            _ShellNavItem(
              icon: Icons.bookmark_border,
              label: 'nav.information'.tr,
              selected: _isSelected('Information'),
              onTap: UiNavigationService.openInformation,
            ),
            _ShellNavItem(
              icon: Icons.send_outlined,
              label: 'nav.telegramBots'.tr,
              selected: _isSelected('Telegram'),
              onTap: UiNavigationService.openTelegramBots,
            ),
            _ShellNavItem(
              icon: Icons.campaign_outlined,
              label: 'nav.promo'.tr,
              selected: _isSelected('Promo'),
              onTap: UiNavigationService.openPromo,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 24, 10),
              child: _ShellNavItem(
                icon: Icons.notifications_none,
                label: 'nav.notifierBot'.tr,
                selected: _isSelected('Notifier'),
                onTap: UiNavigationService.openNotifierBot,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 24, 22),
              child: _ShellNavItem(
                icon: Icons.telegram,
                label: 'nav.telegramChannel'.tr,
                compact: true,
                onTap: UiNavigationService.openTelegramBots,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpressTopBar extends StatelessWidget {
  final String title;
  final String? breadcrumb;
  final String? balanceLabel;
  final VoidCallback? onRefresh;

  const _ExpressTopBar({
    required this.title,
    this.breadcrumb,
    this.balanceLabel,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 22, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          return Row(
            children: [
              if (MediaQuery.of(context).size.width < 920) ...[
                const _ExpressLogo(),
                const SizedBox(width: 18),
              ],
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!compact)
                          Obx(
                            () => _TopChip(
                              icon: Icons.hexagon,
                              label: walletService.networkLabel,
                            ),
                          ),
                        if (!compact) const SizedBox(width: 10),
                        _BalanceChip(balanceLabel: balanceLabel),
                        const SizedBox(width: 10),
                        Obx(
                          () => _TopChip(
                            icon: Icons.account_balance_wallet_outlined,
                            label: walletService.isConnected.value
                                ? walletService.shortAddress
                                : 'top.signInBase'.tr,
                            emphasized: !walletService.isConnected.value,
                            onTap: () => _handleWalletChipTap(
                              context,
                              walletService,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _RoundIconButton(icon: Icons.search, onTap: onRefresh),
                        const SizedBox(width: 8),
                        _RoundIconButton(
                          icon: Icons.notifications_none,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              backgroundColor: Colors.black,
                              builder: (context) => NotificationsBottomSheet(),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _RoundIconButton(
                          icon: Icons.logout,
                          onTap: () {
                            walletService.disconnectWallet();
                            Get.offAllNamed('/home');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleWalletChipTap(
    BuildContext context,
    WalletConnectService walletService,
  ) async {
    if (walletService.isConnected.value) {
      await walletService.refreshNativeBalance();
      return;
    }

    try {
      await walletService.connectBaseAccount();
    } catch (e) {
      Get.snackbar(
        'common.error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _BalanceChip extends StatelessWidget {
  final String? balanceLabel;

  const _BalanceChip({this.balanceLabel});

  @override
  Widget build(BuildContext context) {
    if (balanceLabel != null) {
      return _TopChip(
        icon: Icons.monetization_on,
        label: balanceLabel!,
      );
    }

    final walletService = Get.find<WalletConnectService>();
    return Obx(
      () => _TopChip(
        icon: Icons.monetization_on,
        label:
            '${_formatShellWei(walletService.nativeBalanceWei.value ?? BigInt.zero)} ${walletService.nativeSymbol}',
      ),
    );
  }
}

class _ExpressLogo extends StatelessWidget {
  const _ExpressLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'EASY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 0,
              height: 0.9,
            ),
          ),
          Text(
            'Games',
            style: TextStyle(
              color: EasyGameTheme.tealSoft,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  const _ShellNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, compact ? 2 : 5, 18, compact ? 2 : 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 8 : 13,
          ),
          decoration: BoxDecoration(
            color: selected ? EasyGameTheme.surfaceHigh : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : Colors.white54,
                size: compact ? 16 : 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: compact ? 11 : 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool emphasized;
  final VoidCallback? onTap;

  const _TopChip({
    required this.icon,
    required this.label,
    this.emphasized = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: emphasized ? null : EasyGameTheme.surfaceHigh,
            gradient: emphasized ? EasyGameTheme.actionGradient : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: emphasized ? Colors.transparent : EasyGameTheme.borderSoft,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: EasyGameTheme.gold, size: 17),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: EasyGameTheme.surfaceHigh,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 19),
      ),
    );
  }
}

class _FloatingHelpButtons extends StatelessWidget {
  const _FloatingHelpButtons();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _FloatingPill(
            icon: Icons.send,
            label: 'floating.news'.tr,
            color: EasyGameTheme.blue,
            onTap: UiNavigationService.openTelegramBots,
          ),
          const SizedBox(height: 12),
          _FloatingPill(
            icon: Icons.language,
            label: 'floating.language'.tr,
            color: EasyGameTheme.blue,
            onTap: () => showLanguageSelector(context),
          ),
          const SizedBox(height: 16),
          _FloatingPill(
            icon: Icons.chat_bubble_outline,
            label: 'floating.chat'.tr,
            color: const Color(0xFF351083),
            onTap: UiNavigationService.openSupport,
          ),
        ],
      ),
    );
  }
}

String _formatShellWei(BigInt wei, {int decimals = 4}) {
  final negative = wei < BigInt.zero;
  final value = negative ? -wei : wei;
  final divisor = BigInt.from(10).pow(18);
  final whole = value ~/ divisor;
  final fraction = value % divisor;
  if (fraction == BigInt.zero || decimals <= 0) {
    return '${negative ? '-' : ''}$whole';
  }
  final padded = fraction.toString().padLeft(18, '0');
  final clipped =
      padded.substring(0, decimals).replaceFirst(RegExp(r'0+$'), '');
  if (clipped.isEmpty) {
    return '${negative ? '-' : ''}$whole';
  }
  return '${negative ? '-' : ''}$whole.$clipped';
}

class _FloatingPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 21),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
