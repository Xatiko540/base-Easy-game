import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/language_selector.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';
import 'package:lottery_advance/utils/theme.dart';

import '../widgets/notifications/notifications_bottom_sheet.dart';
import '../controllers/notifications_controller.dart';

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
                              activeSection: activeSection ?? title,
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
              icon: CupertinoIcons.square_grid_2x2,
              label: 'nav.dashboard'.tr,
              selected: _isSelected('Dashboard') || _isSelected('Profile'),
              onTap: () => Get.toNamed('/profile'),
            ),
            _ShellNavItem(
              icon: CupertinoIcons.square_grid_3x2,
              label: 'nav.easyGames'.tr,
              selected: _isSelected('Levels') || _isSelected('Easy Games'),
              onTap: UiNavigationService.openLevels,
            ),
            _ShellNavItem(
              icon: CupertinoIcons.square_list,
              label: 'nav.matrix'.tr,
              selected: _isSelected('Matrix'),
              onTap: UiNavigationService.openMatrix,
            ),
            _ShellNavItem(
              icon: CupertinoIcons.circle_grid_3x3,
              label: 'nav.stats'.tr,
              selected: _isSelected('Statistics') || _isSelected('Stats'),
              onTap: UiNavigationService.openStatistics,
            ),
            _ShellNavItem(
              icon: CupertinoIcons.person_3,
              label: 'nav.partnerBonus'.tr,
              selected: _isSelected('Partner'),
              onTap: () => Get.toNamed('/partner-bonus'),
            ),
            _ShellNavItem(
              icon: CupertinoIcons.bookmark,
              label: 'nav.information'.tr,
              selected: _isSelected('Information'),
              onTap: UiNavigationService.openInformation,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 24, 10),
              child: _ShellNavItem(
                icon: CupertinoIcons.bell,
                label: 'nav.notifierBot'.tr,
                selected: _isSelected('Notifier'),
                onTap: UiNavigationService.openNotifierBot,
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
  final String activeSection;

  const _ExpressTopBar({
    required this.title,
    this.breadcrumb,
    this.balanceLabel,
    this.onRefresh,
    required this.activeSection,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 22, 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mobile = constraints.maxWidth < 600;
          final compact = constraints.maxWidth < 820;
          if (mobile) {
            return _MobileTopBar(
              title: title,
              activeSection: activeSection,
              walletService: walletService,
            );
          }
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
                              icon: CupertinoIcons.hexagon,
                              label: walletService.networkLabel,
                            ),
                          ),
                        if (!compact) const SizedBox(width: 10),
                        _BalanceChip(balanceLabel: balanceLabel),
                        const SizedBox(width: 10),
                        Obx(
                          () => _TopChip(
                            icon: CupertinoIcons.creditcard,
                            label: walletService.isConnected.value
                                ? walletService.shortAddress
                                : 'Base',
                            emphasized: !walletService.isConnected.value,
                            onTap: () => _handleWalletChipTap(
                              context,
                              walletService,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (onRefresh != null) ...[
                          _RoundIconButton(
                            icon: CupertinoIcons.refresh,
                            tooltip: 'common.refresh'.tr,
                            onTap: onRefresh,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _RoundIconButton(
                          icon: CupertinoIcons.search,
                          tooltip: 'common.search'.tr,
                          onTap: UiNavigationService.openMemberSearchDialog,
                        ),
                        const SizedBox(width: 8),
                        Obx(() {
                          final c = Get.find<NotificationsController>();
                          return _RoundIconButton(
                            icon: CupertinoIcons.bell,
                            tooltip: 'nav.notifierBot'.tr,
                            badgeCount: c.unreadCount.value,
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
                                builder: (context) =>
                                    const NotificationsBottomSheet(),
                              );
                            },
                          );
                        }),
                        const SizedBox(width: 8),
                        _RoundIconButton(
                          icon: CupertinoIcons.square_arrow_left,
                          tooltip: 'common.logout'.tr,
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
      if (Get.isRegistered<FirebaseBackendService>()) {
        final backend = Get.find<FirebaseBackendService>();
        if (backend.isReady.value) {
          backend.ensureCurrentWalletLinkedInBackground();
        }
      }
    } catch (e) {
      Get.snackbar(
        'common.error'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _MobileTopBar extends StatelessWidget {
  final String title;
  final String activeSection;
  final WalletConnectService walletService;

  const _MobileTopBar({
    required this.title,
    required this.activeSection,
    required this.walletService,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          icon: CupertinoIcons.bars,
          tooltip: 'common.menu'.tr,
          onTap: () => _showMobileShellMenu(
            context,
            activeSection,
            walletService,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Obx(
          () => _TopChip(
            icon: CupertinoIcons.hexagon,
            label: 'Base',
            emphasized: !walletService.isConnected.value,
            onTap: () => _handleMobileWalletTap(context, walletService),
          ),
        ),
        const SizedBox(width: 6),
        _RoundIconButton(
          icon: CupertinoIcons.search,
          tooltip: 'common.search'.tr,
          onTap: UiNavigationService.openMemberSearchDialog,
        ),
        const SizedBox(width: 6),
        Obx(() {
          final notifications = Get.find<NotificationsController>();
          return _RoundIconButton(
            icon: CupertinoIcons.bell,
            tooltip: 'nav.notifierBot'.tr,
            badgeCount: notifications.unreadCount.value,
            onTap: () => _showNotifications(context),
          );
        }),
      ],
    );
  }
}

Future<void> _handleMobileWalletTap(
  BuildContext context,
  WalletConnectService walletService,
) async {
  if (walletService.isConnected.value) {
    await walletService.refreshNativeBalance();
    return;
  }
  try {
    await walletService.connectBaseAccount();
    if (Get.isRegistered<FirebaseBackendService>()) {
      final backend = Get.find<FirebaseBackendService>();
      if (backend.isReady.value) {
        backend.ensureCurrentWalletLinkedInBackground();
      }
    }
  } catch (error) {
    Get.snackbar(
      'common.error'.tr,
      error.toString(),
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

void _showNotifications(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    backgroundColor: Colors.black,
    builder: (context) => const NotificationsBottomSheet(),
  );
}

void _showMobileShellMenu(
  BuildContext context,
  String activeSection,
  WalletConnectService walletService,
) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: EasyGameTheme.shell,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: _MobileShellMenu(
        activeSection: activeSection,
        walletService: walletService,
      ),
    ),
  );
}

class _MobileShellMenu extends StatelessWidget {
  final String activeSection;
  final WalletConnectService walletService;

  const _MobileShellMenu({
    required this.activeSection,
    required this.walletService,
  });

  bool _selected(String value) =>
      activeSection.toLowerCase().contains(value.toLowerCase());

  void _open(VoidCallback action) {
    Get.back<void>();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final items = <_MobileMenuItem>[
      _MobileMenuItem(
        icon: CupertinoIcons.square_grid_2x2,
        label: 'nav.dashboard'.tr,
        selected: _selected('Dashboard') || _selected('Profile'),
        onTap: () => Get.toNamed('/profile'),
      ),
      _MobileMenuItem(
        icon: CupertinoIcons.square_grid_3x2,
        label: 'nav.easyGames'.tr,
        selected: _selected('Levels') || _selected('Easy Games'),
        onTap: UiNavigationService.openLevels,
      ),
      _MobileMenuItem(
        icon: CupertinoIcons.square_list,
        label: 'nav.matrix'.tr,
        selected: _selected('Matrix'),
        onTap: UiNavigationService.openMatrix,
      ),
      _MobileMenuItem(
        icon: CupertinoIcons.circle_grid_3x3,
        label: 'nav.stats'.tr,
        selected: _selected('Statistics') || _selected('Stats'),
        onTap: UiNavigationService.openStatistics,
      ),
      _MobileMenuItem(
        icon: CupertinoIcons.person_3,
        label: 'nav.partnerBonus'.tr,
        selected: _selected('Partner'),
        onTap: () => Get.toNamed('/partner-bonus'),
      ),
      _MobileMenuItem(
        icon: CupertinoIcons.bookmark,
        label: 'nav.information'.tr,
        selected: _selected('Information'),
        onTap: UiNavigationService.openInformation,
      ),
    ];

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      children: [
        for (final item in items)
          ListTile(
            selected: item.selected,
            selectedTileColor: EasyGameTheme.surfaceHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: Icon(
              item.icon,
              color: item.selected ? EasyGameTheme.teal : Colors.white60,
            ),
            title: Text(
              item.label,
              style: TextStyle(
                color: item.selected ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
            onTap: () => _open(item.onTap),
          ),
        if (walletService.isConnected.value) ...[
          const Divider(color: EasyGameTheme.border),
          ListTile(
            leading: const Icon(
              CupertinoIcons.square_arrow_left,
              color: EasyGameTheme.orange,
            ),
            title: Text(
              'common.logout'.tr,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
            onTap: () {
              Get.back<void>();
              walletService.disconnectWallet();
              Get.offAllNamed('/home');
            },
          ),
        ],
      ],
    );
  }
}

class _MobileMenuItem {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MobileMenuItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class _BalanceChip extends StatelessWidget {
  final String? balanceLabel;

  const _BalanceChip({this.balanceLabel});

  @override
  Widget build(BuildContext context) {
    if (balanceLabel != null) {
      return _TopChip(
        icon: CupertinoIcons.money_dollar,
        label: balanceLabel!,
      );
    }

    final walletService = Get.find<WalletConnectService>();
    return Obx(
      () => _TopChip(
        icon: CupertinoIcons.money_dollar,
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

  const _ShellNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 18, 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 13,
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
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white54,
                    fontSize: 15,
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
  final int badgeCount;
  final String? tooltip;

  const _RoundIconButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: EasyGameTheme.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white70, size: 19),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) return button;
    return Tooltip(message: tooltip!, child: button);
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
          const SizedBox(height: 12),
          _FloatingPill(
            icon: CupertinoIcons.globe,
            label: 'floating.language'.tr,
            color: EasyGameTheme.blue,
            onTap: () => showLanguageSelector(context),
          ),
          const SizedBox(height: 16),
          _FloatingPill(
            icon: CupertinoIcons.chat_bubble,
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
