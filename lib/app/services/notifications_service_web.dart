class NotificationsService {
  static final NotificationsService _instance =
      NotificationsService._internal();
  factory NotificationsService() => _instance;
  NotificationsService._internal();

  Future<void> init() async {
    return;
  }

  Future<void> showNotification(
      {required String title, required String body, int id = 0}) async {
    // Web notifications are not supported by the mobile notification plugin.
    // Use console logging for debugging and avoid plugin crashes.
    // ignore: avoid_print
    print('Notification (web skipped): $title - $body');
  }

  Future<void> cancelAll() async {
    return;
  }
}
