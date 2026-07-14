import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/views/utility_screens.dart';
import 'package:url_launcher/url_launcher.dart';

class UiNavigationService {
  static Future<void> openMemberSearchDialog() async {
    final controller = TextEditingController();
    final query = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: const Color(0xFF1F2223),
        title: Text(
          'common.search'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'start.previewInput'.tr,
            hintStyle: const TextStyle(color: Colors.white38),
            prefixIcon: const Icon(CupertinoIcons.search),
          ),
          onSubmitted: (value) => Get.back(result: value),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text('common.close'.tr),
          ),
          FilledButton.icon(
            onPressed: () => Get.back(result: controller.text),
            icon: const Icon(CupertinoIcons.search, size: 18),
            label: Text('common.search'.tr),
          ),
        ],
      ),
    );
    controller.dispose();
    if (query != null) openMemberPreview(query);
  }

  static void openLevels({String? walletAddress}) {
    Get.toNamed(
      '/levels',
      parameters: walletAddress?.trim().isNotEmpty == true
          ? {'wallet': walletAddress!.trim()}
          : null,
    );
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
