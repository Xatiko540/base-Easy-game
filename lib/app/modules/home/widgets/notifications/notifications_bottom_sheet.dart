import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/controllers/notifications_controller.dart';
import 'package:lottery_advance/utils/theme.dart';

class NotificationsBottomSheet extends StatelessWidget {
  const NotificationsBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.72,
          constraints: const BoxConstraints(maxWidth: 720),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: EasyGameTheme.shell,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => Row(
                  children: [
                    const Icon(
                      CupertinoIcons.bell_fill,
                      color: EasyGameTheme.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'notifications.title'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (controller.unreadCount.value > 0)
                      TextButton(
                        onPressed: controller.markAllAsRead,
                        child: Text(
                          'notifications.markAllRead'.tr,
                          style: const TextStyle(
                            color: EasyGameTheme.teal,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (controller.notifications.isEmpty) {
                    return Center(
                      child: Text(
                        'notifications.empty'.tr,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: controller.notifications.length,
                    itemBuilder: (context, index) {
                      final notification = controller.notifications[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _openNotification(
                          controller,
                          index,
                          notification.actionRoute,
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? EasyGameTheme.surface.withValues(alpha: 0.58)
                                : const Color(0xFF18203A),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: notification.isRead
                                  ? EasyGameTheme.border
                                  : EasyGameTheme.teal.withValues(alpha: 0.42),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 21,
                                backgroundColor: notification.iconColor
                                    .withValues(alpha: 0.15),
                                child: Icon(
                                  notification.icon,
                                  color: notification.iconColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notification.titleKey.tr,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notification.subtitleKey.tr,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (notification
                                        .descriptionKey.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        notification.descriptionKey.tr,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                    if (notification.actionLabelKey !=
                                        null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        notification.actionLabelKey!.tr,
                                        style: const TextStyle(
                                          color: EasyGameTheme.teal,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                notification.timeKey.tr,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNotification(
    NotificationsController controller,
    int index,
    String? route,
  ) {
    controller.markAsRead(index);
    if (route == null || route.isEmpty) return;
    Get.back<void>();
    Get.toNamed<void>(route);
  }
}
