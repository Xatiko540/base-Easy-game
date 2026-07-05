part of '../views/start_page.dart';

class _LandingTopBar extends StatelessWidget {
  final WalletConnectService walletService;
  final VoidCallback onConnect;

  const _LandingTopBar({
    required this.walletService,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _EasyLogo(),
        const Spacer(),
        Obx(
          () => _TopPill(
            icon: Icons.hexagon,
            label: walletService.networkLabel,
          ),
        ),
        const SizedBox(width: 12),
        Obx(
          () => _TopPill(
            icon: Icons.account_balance_wallet_outlined,
            label: walletService.isConnected.value
                ? walletService.shortAddress
                : 'start.connectWallet'.tr,
            gradient: !walletService.isConnected.value,
            onTap: walletService.isConnected.value
                ? walletService.refreshNativeBalance
                : onConnect,
          ),
        ),
      ],
    );
  }
}
