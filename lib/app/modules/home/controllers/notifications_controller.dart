import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/models/notification_models.dart';
import 'package:lottery_advance/app/services/wallet_connect_service.dart';

class NotificationsController extends GetxController {
  final WalletConnectService walletService = Get.find<WalletConnectService>();

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
    final currency = walletService.nativeSymbol;
    notifications.value = [
      NotificationItem(
        title: '+ 0.1036 $currency received!',
        subtitle: 'Easy Games, level 4 от ID 310375',
        time: '1 minute',
        icon: CupertinoIcons.gift,
        iconColor: Colors.greenAccent,
      ),
      NotificationItem(
        title: '+ 0.0182 Affiliate $currency bonus received!',
        subtitle: 'Easy Games, level 4 от ID 310112',
        time: 'about 1 hour',
        icon: CupertinoIcons.person_2,
        iconColor: Colors.green,
      ),
      NotificationItem(
        title: 'New partner joins',
        subtitle: 'ID 310112 has joined your team!',
        time: 'about 1 hour',
        icon: CupertinoIcons.person_badge_plus,
        iconColor: Colors.blueAccent,
      ),
    ];
    _updateUnreadCount();
    isLoading.value = false;
  }
  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void markAllAsRead() {
    final updated = notifications.map((n) => NotificationItem(
      title: n.title,
      subtitle: n.subtitle,
      description: n.description,
      time: n.time,
      icon: n.icon,
      iconColor: n.iconColor,
      isRead: true,
    )).toList();
    notifications.value = updated;
    unreadCount.value = 0;
  }
}
