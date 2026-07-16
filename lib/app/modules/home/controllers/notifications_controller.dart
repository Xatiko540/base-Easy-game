import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/models/notification_models.dart';

class NotificationsController extends GetxController {
  final notifications = <NotificationItem>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetch();
  }

  void fetch() {
    isLoading.value = true;
    notifications.assignAll(const [
      NotificationItem(
        titleKey: 'notifications.welcomeTitle',
        subtitleKey: 'notifications.welcomeSubtitle',
        descriptionKey: 'notifications.welcomeDescription',
        timeKey: 'notifications.now',
        actionLabelKey: 'notifications.readRules',
        actionRoute: '/information',
        icon: CupertinoIcons.info_circle_fill,
        iconColor: Color(0xFF00B9B1),
      ),
    ]);
    _updateUnreadCount();
    isLoading.value = false;
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void markAsRead(int index) {
    if (index < 0 || index >= notifications.length) return;
    notifications[index] = notifications[index].copyWith(isRead: true);
    _updateUnreadCount();
  }

  void markAllAsRead() {
    notifications.assignAll(
      notifications.map((notification) => notification.copyWith(isRead: true)),
    );
    unreadCount.value = 0;
  }
}
