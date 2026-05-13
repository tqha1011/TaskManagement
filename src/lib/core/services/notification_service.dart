import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _hourKey = 'notif_hour';
  static const _minuteKey = 'notif_minute';
  static const _notifId = 1;

  Future<void> init() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<TimeOfDay> getSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey) ?? 8;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> scheduleDailyNotification({
    required TimeOfDay time,
    required int lowCount,
    required int mediumCount,
    required int highCount,
    required int urgentCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);

    await _plugin.cancel(_notifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = _buildNotificationBody(
      lowCount,
      mediumCount,
      highCount,
      urgentCount,
    );

    await _plugin.zonedSchedule(
      _notifId,
      '📋 Tổng quan công việc hôm nay',
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_task_channel',
          'Daily Task Summary',
          channelDescription: 'Thông báo tóm tắt task hàng ngày',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification() async {
    await _plugin.cancel(_notifId);
  }

  String _buildNotificationBody(int low, int medium, int high, int urgent) {
    final parts = <String>[];
    if (urgent > 0) parts.add('🔴 Khẩn cấp: $urgent');
    if (high > 0) parts.add('🟠 Cao: $high');
    if (medium > 0) parts.add('🔵 Trung bình: $medium');
    if (low > 0) parts.add('🟢 Thấp: $low');

    if (parts.isEmpty) {
      return 'Không có task nào hôm nay. Tận hưởng ngày của bạn! 🎉';
    }
    return parts.join(' · ');
  }
}
