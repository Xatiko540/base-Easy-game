import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/levels.dart';
import 'package:lottery_advance/app/modules/home/views/utility_screens.dart';
import 'package:url_launcher/url_launcher.dart';

class UiNavigationService {
  static void openLevels() {
    Get.to(() => const LevelsScreen());
  }

  static void openMatrix() {
    Get.to(() => MatrixArenaScreen());
  }

  static void openStatistics() {
    Get.to(() => StatisticsScreen());
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
    Get.to(() => const InformationScreen());
  }

  static void openTelegramBots() {
    Get.to(() => const TelegramBotsScreen());
  }

  static void openPromo() {
    Get.to(() => PromoScreen());
  }

  static void openNotifierBot() {
    Get.to(() => NotifierBotScreen());
  }

  static void openSettings() {
    Get.to(() => SettingsScreen());
  }

  static void openSupport() {
    Get.to(() => const SupportScreen());
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
