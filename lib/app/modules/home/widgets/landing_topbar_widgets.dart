part of '../views/start_page.dart';

class _LandingTopBar extends StatelessWidget {
  final VoidCallback onConnect;

  const _LandingTopBar({
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final walletService = Get.find<WalletConnectService>();
    return Row(
      children: [
        const _EasyLogo(),
        const Spacer(),
        Obx(
          () => _TopPill(
            icon: CupertinoIcons.hexagon,
            label: walletService.networkLabel,
          ),
        ),
        const SizedBox(width: 12),
        Obx(
          () => _TopPill(
            icon: CupertinoIcons.creditcard,
            label: walletService.isConnected.value
                ? walletService.shortAddress
                : 'start.connectWallet'.tr,
            gradient: !walletService.isConnected.value,
            onTap: walletService.isConnected.value
                ? walletService.refreshNativeBalanceSilently
                : onConnect,
          ),
        ),
      ],
    );
  }
}
