import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/controllers/notifications_controller.dart';

class NotificationsBottomSheet extends StatelessWidget {
  const NotificationsBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationsController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Notifications",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (controller.unreadCount.value > 0)
                TextButton(
                  onPressed: () => controller.markAllAsRead(),
                  child: const Text(
                    "Mark all read",
                    style: TextStyle(color: Colors.blueAccent, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Obx(() {
              if (controller.notifications.isEmpty) {
                return const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                );
              }
              return ListView.builder(
                itemCount: controller.notifications.length,
                itemBuilder: (context, index) {
                  final notification = controller.notifications[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1F2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: notification.iconColor,
                          child: Icon(notification.icon,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.subtitle,
                                style:
                                    const TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                              if (notification.description.isNotEmpty)
                                Text(
                                  notification.description,
                                  style:
                                      const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              notification.time,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const Icon(CupertinoIcons.share, color: Colors.grey, size: 20),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
