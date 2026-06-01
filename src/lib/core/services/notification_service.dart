import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';

const String _dailyTaskName = 'daily_task_summary';
const String _dailyTaskUniqueName = 'daily_task_summary_unique';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final service = NotificationService();
      final counts = await service.fetchTodayTaskCounts();
      await service.showImmediateNotification(
        lowCount: counts.low,
        mediumCount: counts.medium,
        highCount: counts.high,
        urgentCount: counts.urgent,
      );
    } catch (e) {
      debugPrint('Background notification error: $e');
    }
    return true;
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _hourKey = 'notif_hour';
  static const _minuteKey = 'notif_minute';
  static const _enabledKey = 'notif_enabled';
  static const _notifId = 1;

  bool _pluginInitialized = false;

  Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );
  }

  Future<void> _ensurePluginInitialized() async {
    if (_pluginInitialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _pluginInitialized = true;
  }

  Future<TimeOfDay> getSavedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey) ?? 8;
    final minute = prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setSavedTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, time.hour);
    await prefs.setInt(_minuteKey, time.minute);
  }

  Future<bool> getNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  Future<void> setNotificationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> showImmediateNotification({
    required int lowCount,
    required int mediumCount,
    required int highCount,
    required int urgentCount,
  }) async {
    await _ensurePluginInitialized();

    final body = _buildNotificationBody(
      lowCount,
      mediumCount,
      highCount,
      urgentCount,
    );

    await _plugin.show(
      _notifId,
      '📋 Tổng quan công việc hôm nay',
      body,
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
    );
  }

  Future<void> registerDailyTask(TimeOfDay time) async {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final initialDelay = scheduled.difference(now);

    await Workmanager().registerPeriodicTask(
      _dailyTaskUniqueName,
      _dailyTaskName,
      frequency: const Duration(hours: 24),
      initialDelay: initialDelay,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  Future<void> updateNotificationSettings({
    required bool isEnabled,
    TimeOfDay? time,
  }) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final resolvedTime = time ?? await getSavedTime();
    final timeString = _formatTime(resolvedTime);

    await setNotificationEnabled(isEnabled);
    await setSavedTime(resolvedTime);

    if (isEnabled) {
      await supabase.from('profile').update({
        'is_noti_enabled': true,
        'daily_reminder_time': timeString,
      }).eq('id', userId);

      await Workmanager().cancelByUniqueName(_dailyTaskUniqueName);
      await registerDailyTask(resolvedTime);
    } else {
      await supabase.from('profile').update({
        'is_noti_enabled': false,
      }).eq('id', userId);

      await Workmanager().cancelByUniqueName(_dailyTaskUniqueName);
    }
  }

  Future<({int low, int medium, int high, int urgent})>
      fetchTodayTaskCounts() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return (low: 0, medium: 0, high: 0, urgent: 0);
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final data = await supabase
        .from('task')
        .select('priority, start_time')
        .eq('profile_id', userId)
        .gte('start_time', startOfDay.toUtc().toIso8601String())
        .lt('start_time', endOfDay.toUtc().toIso8601String());

    int urgent = 0;
    int high = 0;
    int medium = 0;
    int low = 0;

    for (final item in data) {
      final priority = item['priority'];
      if (priority == 1) {
        urgent++;
      } else if (priority == 2) {
        high++;
      } else if (priority == 3) {
        medium++;
      } else if (priority == 4) {
        low++;
      }
    }

    return (low: low, medium: medium, high: high, urgent: urgent);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
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