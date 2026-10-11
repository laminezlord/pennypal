import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PennyPalNotificationService {
  PennyPalNotificationService._();

  static final instance = PennyPalNotificationService._();
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('ic_stat_pennypal');
    const settings = InitializationSettings(
      android: android,
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(settings);

    // Permission is requested only when a budget alert actually needs to be
    // shown, so first launch is not interrupted by a system prompt.
  }

  Future<void> showBudgetAlert(String message) async {
    final androidImpl = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'budget_alerts',
        'Budget alerts',
        channelDescription: 'Spending threshold notifications from PennyPal.',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_stat_pennypal',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      'PennyPal budget alert',
      message,
      details,
    );
  }
}
