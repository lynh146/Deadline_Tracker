import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// NotificationService
// - Quản lý TẤT CẢ local notification
// - App tắt vẫn báo
// - Không phụ thuộc UI
// - Được gọi từ TaskService
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // INIT
  Future<void> init() async {
    // Init timezone
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);
  }

  // SCHEDULE NOTIFICATION
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    // Không schedule quá khứ
    if (time.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'deadline_channel',
          'Deadline Notification',
          channelDescription: 'Nhắc hạn công việc',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // =========================
  // CANCEL 1 NOTIFICATION
  // =========================
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  // =========================
  // CANCEL ALL (OPTIONAL)
  // =========================
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
