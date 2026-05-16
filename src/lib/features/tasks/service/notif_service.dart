import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';


class NotifService {
  static final NotifService _instance = NotifService._internal();
  factory NotifService() => _instance;
  NotifService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<bool> requestNotificationPermission() async {

    var status = await Permission.notification.status;
    

    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.notification.request();
    }
    
    return status.isGranted;
  }

  Future<void> initNotification() async {
    tz.initializeTimeZones(); // Khởi tạo múi giờ

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Icon mặc định của app

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
  }

  // 2. Hàm cốt lõi: Hẹn giờ thông báo trước X khoảng thời gian
  Future<void> scheduleTaskNotification({
    required int taskId,
    required String taskTitle,
    required DateTime taskStartTime, // Giờ bắt đầu của task
    required Duration remindBefore,  // Khoảng thời gian muốn nhắc trước (1 ngày hoặc 1 tiếng)
    required String notificationMessage,
  }) async {
    
    // Tính thời điểm sẽ phát thông báo
    final notificationTime = taskStartTime.subtract(remindBefore);

    // Nếu thời điểm thông báo nằm trong quá khứ thì bỏ qua không hẹn nữa
    if (notificationTime.isBefore(DateTime.now())) return;

    // Chuyển đổi sang kiểu thời gian của thư viện timezone
    final tz.TZDateTime scheduledTZDateTime = tz.TZDateTime.from(notificationTime, tz.local);

    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'task_reminders_channel',
      'Task Reminders',
      channelDescription: 'Kênh thông báo nhắc nhở công việc',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    
    await _notificationsPlugin.zonedSchedule(
      taskId, 
      'Nhắc nhở: $taskTitle',
      notificationMessage,
      scheduledTZDateTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  
  Future<void> cancelNotification(int taskId) async {
    await _notificationsPlugin.cancel(taskId);
  }
}