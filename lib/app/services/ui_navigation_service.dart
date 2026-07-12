import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/modules/home/views/utility_screens.dart';
import 'package:url_launcher/url_launcher.dart';

class UiNavigationService {
  static void openLevels() {
    Get.to(() => const LevelsScreen());
  }

  static void openMatrix() {
    Get.toNamed('/matrix');
  }

  static void openStatistics() {
    Get.toNamed('/stats');
  }

  static void openMemberPreview(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      Get.snackbar(
        'Preview search',
        'Enter a wallet address or member ID.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    Get.to(() => MemberPreviewScreen(query: trimmed));
  }

  static void openInformation() {
    Get.toNamed('/information');
  }

  static void openTelegramBots() {
    Get.toNamed('/telegram-bots');
  }

  static void openPromo() {
    Get.toNamed('/promo');
  }

  static void openNotifierBot() {
    Get.toNamed('/notifier-bot');
  }

  static void openSettings() {
    Get.to(() => SettingsScreen());
  }

  static void openSupport() {
    Get.toNamed('/support');
  }

  static void openExpressInfo() {
    Get.to(() => const ExpressInfoScreen());
  }

  static void openRecentActivity() {
    Get.to(() => const RecentActivityScreen());
  }

  static Future<void> openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    Get.snackbar(
      'Link unavailable',
      url,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
