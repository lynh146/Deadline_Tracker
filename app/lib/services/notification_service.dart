import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // CHANNEL IDS (mới)
  static const String chGeneral = 'general_channel';
  static const String chStart = 'start_channel';
  static const String chReminder = 'reminder_channel';
  static const String chDeadline = 'deadline_channel';
  static const String chOverdue = 'overdue_channel';
  static const String chProgress = 'progress_channel';

  // ALIAS (để code cũ khỏi lỗi)
  static const String deadlineChannelId = chDeadline;

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(initSettings);

    // Android 13+ cần xin quyền
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
    }
  }

  AndroidNotificationDetails _androidDetails(
    String channelId,
    String channelName,
    String channelDesc,
  ) {
    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );
  }

  NotificationDetails _details(
    String channelId,
    String channelName,
    String channelDesc,
  ) {
    return NotificationDetails(
      android: _androidDetails(channelId, channelName, channelDesc),
      iOS: const DarwinNotificationDetails(),
    );
  }

  /// Show ngay (tạo task / update progress...)
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String channelId = chGeneral,
    String channelName = 'General',
    String channelDesc = 'General notifications',
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      _details(channelId, channelName, channelDesc),
    );
  }

  /// Schedule
  /// - Mặc định inexactAllowWhileIdle (không cần exact alarm)
  /// - Nếu time < now => bỏ qua
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    String channelId = chDeadline,
    String channelName = 'Deadline',
    String channelDesc = 'Nhắc hạn công việc',
  }) async {
    if (time.isBefore(DateTime.now())) return;

    final scheduledTime = tz.TZDateTime.from(time, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      _details(channelId, channelName, channelDesc),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();

  // FIRESTORE LOG NOTIFICATIONS
  Future<void> saveToFirestore({
    required String userId,
    required String title,
    required String body,
    required String
    type, // create/progress/start/reminder/deadline/overdue/delete
    required DateTime createdAt,
    DateTime? scheduledFor,
    String? taskDocId,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');

    await ref.add({
      'title': title,
      'body': body,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledFor': scheduledFor == null
          ? null
          : Timestamp.fromDate(scheduledFor),
      'taskDocId': taskDocId,
      'isRead': false,
    });
  }
}
