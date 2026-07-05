part of '../views/start_page.dart';

class _LandingFloatingButtons extends StatelessWidget {
  const _LandingFloatingButtons();

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
