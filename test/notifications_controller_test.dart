import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lottery_advance/app/modules/home/controllers/notifications_controller.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  test('loads only the welcome notification', () {
    final controller = Get.put(NotificationsController());

    expect(controller.notifications, hasLength(1));
    expect(
      controller.notifications.single.titleKey,
      'notifications.welcomeTitle',
    );
    expect(controller.notifications.single.actionRoute, '/information');
    expect(controller.unreadCount.value, 1);
  });

  test('marks the welcome notification as read', () {
    final controller = Get.put(NotificationsController());

    controller.markAsRead(0);

    expect(controller.notifications.single.isRead, isTrue);
    expect(controller.unreadCount.value, 0);
  });
}
