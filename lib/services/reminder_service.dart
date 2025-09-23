import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService(this._notifications);

  final FlutterLocalNotificationsPlugin _notifications;

  static const _unpaidNotificationId = 1;
  static const _plannedNotificationId = 2;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
    _initialized = true;
  }

  Future<void> scheduleDailyUnpaidReminder() async {
    await initialize();
    await _notifications.zonedSchedule(
      _unpaidNotificationId,
      '未払いがあります',
      '今日の未払いを確認しましょう',
      _nextInstanceAt20(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'unpaid_channel',
          '未払いリマインド',
          channelDescription: '未払いが残っているときに毎日20:00に通知します。',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelUnpaidReminder() async {
    await _notifications.cancel(_unpaidNotificationId);
  }

  Future<void> schedulePlannedReminder() async {
    await initialize();
    await _notifications.zonedSchedule(
      _plannedNotificationId,
      '明日の支払い予定を確認',
      '予定の支払いに備えてください。',
      _nextInstanceAt20(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'planned_channel',
          '予定リマインド',
          channelDescription: '予定の前日に20:00に通知します。',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelPlannedReminder() async {
    await _notifications.cancel(_plannedNotificationId);
  }

  Future<void> cancelAll() => _notifications.cancelAll();

  tz.TZDateTime _nextInstanceAt20() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
