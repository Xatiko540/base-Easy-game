import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationsService {
  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
  }

  Future<void> showNotification(
      {required String title, required String body, int id = 0}) async {
    const android = AndroidNotificationDetails(
      'easy_game_channel',
      'Easy Game',
      channelDescription: 'Notifications from Easy Game smart contract events',
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    const platform = NotificationDetails(android: android, iOS: ios);

    await _plugin.show(id, title, body, platform);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
