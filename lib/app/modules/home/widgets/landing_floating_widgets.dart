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
