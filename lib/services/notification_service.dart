import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    // We use the default flutter launcher icon. If you have custom icon, update this.
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    
    await flutterLocalNotificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleInstallmentNotifications(String id, String itemName, DateTime dueDate) async {
    // Schedule notifications at 7 AM for the 5 days prior to the due date
    for (int i = 5; i > 0; i--) {
      final scheduleDate = dueDate.subtract(Duration(days: i));
      
      // Target time: 7:00 AM on the scheduled date
      var targetTime = tz.TZDateTime.local(scheduleDate.year, scheduleDate.month, scheduleDate.day, 7, 0);
      
      // If the target time is in the past, skip it
      if (targetTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

      // Unique ID for this specific day of this specific installment
      final notificationId = id.hashCode + i;

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: notificationId,
        title: 'Installment Due Soon',
        body: '$itemName is due in $i day(s). Please ensure sufficient balance.',
        scheduledDate: targetTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'installment_channel',
            'Installment Reminders',
            channelDescription: 'Reminders for upcoming installments',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelInstallmentNotifications(String id) async {
    for (int i = 5; i > 0; i--) {
      await flutterLocalNotificationsPlugin.cancel(id: id.hashCode + i);
    }
  }
  
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
