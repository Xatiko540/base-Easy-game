import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/language_selector.dart';
import 'package:lottery_advance/app/modules/home/views/registrationlevel.dart';
import 'package:lottery_advance/app/services/referral_link_service.dart';
import 'package:lottery_advance/app/services/firebase_backend_service.dart';
import 'package:lottery_advance/app/modules/home/models/levels_models.dart';
import 'package:lottery_advance/app/services/ui_navigation_service.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class InviteScreen extends StatelessWidget {
  final String inviter;

  InviteScreen({Key? key, String? inviter})
      : inviter = ReferralLinkService.normalizeAddress(
          inviter ?? ReferralLinkService.inviterFromCurrentUrl(),
        ),
        super(key: key);

  final WalletConnectService walletService = Get.find<WalletConnectService>();

  @override
  Widget build(BuildContext context) {
    if (inviter.isNotEmpty) {
      walletService.setReferralInviter(inviter);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 0.82,
                  colors: [
                    Color(0xFF0B2B24),
                    Color(0xFF030504),
                    Color(0xFF000000),
                  ],
                  stops: [0, 0.62, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 22, 36, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _InviteLogo(),
                      Obx(
                        () => _ConnectButton(
                          label: walletService.isConnected.value
                              ? walletService.shortAddress
                              : 'start.connectWallet'.tr,
                          onPressed: _connectWallet,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _InviteAvatar(),
                            const SizedBox(height: 28),
                            Text(
                              _displayInviterId,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFE36E),
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'invite.invitesYou'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                height: 1.12,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'app.name'.tr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 46,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 54),
                            SizedBox(
                              width: 430,
                              height: 58,
                              child: ElevatedButton(
                                onPressed: _connectAndPlay,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF63D3BE),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  'invite.connectAndPlay'.tr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const _InviteFloatingButtons(),
        ],
      ),
    );
  }

  String get _displayInviterId {
    if (inviter.isEmpty) {
      return 'Partner link';
    }
    final seed = inviter.codeUnits.fold<int>(0, (sum, code) => sum + code);
    final id = 300000 + (seed % 699999);
    return 'ID $id';
  }

  Future<void> _connectWallet() async {
    try {
      await walletService.connectBaseAccount();
      if (Get.isRegistered<FirebaseBackendService>()) {
        final backend = Get.find<FirebaseBackendService>();
        if (backend.isReady.value) {
          await backend.ensureCurrentWalletLinked();
        }
      }
    } catch (e) {
      Get.snackbar(
        'Failed to connect wallet',
        '$e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _connectAndPlay() async {
    if (!walletService.isConnected.value) {
      await _connectWallet();
    }
    Get.to(
      () => RegistrationScreen(
        LevelStatus.waiting,
        level: 3,
        amount: levelPrice(3),
        inviter: inviter,
      ),
    );
  }
}

class _InviteLogo extends StatelessWidget {
  const _InviteLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'EASY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 0.9,
            ),
          ),
          Text(
            'Games',
            style: TextStyle(
              color: Color(0xFF5ED6C1),
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              height: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _ConnectButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF242526),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InviteAvatar extends StatelessWidget {
  const _InviteAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: const BoxDecoration(
        color: Color(0xFF22352F),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 74,
        height: 74,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: Color(0xFF45A6A8),
          size: 54,
        ),
      ),
    );
  }
}

class _InviteFloatingButtons extends StatelessWidget {
  const _InviteFloatingButtons();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      bottom: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _FloatingActionPill(
            icon: Icons.send,
            label: 'floating.news'.tr,
            color: const Color(0xFF426CF8),
            onTap: UiNavigationService.openTelegramBots,
          ),
          const SizedBox(height: 16),
          _FloatingActionPill(
            icon: Icons.language,
            label: 'floating.language'.tr,
            color: const Color(0xFF426CF8),
            onTap: () => showLanguageSelector(context),
          ),
          const SizedBox(height: 20),
          _FloatingActionPill(
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

class _FloatingActionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FloatingActionPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
