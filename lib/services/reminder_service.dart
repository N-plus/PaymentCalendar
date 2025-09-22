import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/expense.dart';

class ReminderService {
  ReminderService._internal();

  static final ReminderService _instance = ReminderService._internal();

  factory ReminderService() => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int _dailyNotificationId = 1;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(initSettings);
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
    }
    _initialized = true;
  }

  Future<void> scheduleDailyReminder() async {
    await initialize();
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 20);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notificationsPlugin.zonedSchedule(
      _dailyNotificationId,
      '未払いの確認',
      '未払いの支払いを忘れていませんか？',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: '毎日20時の未払い通知',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await initialize();
    await _notificationsPlugin.cancel(_dailyNotificationId);
  }

  Future<void> schedulePlannedReminder(Expense expense) async {
    await initialize();
    if (!expense.isPlanned || expense.isPaid) {
      return;
    }
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      expense.date.year,
      expense.date.month,
      expense.date.day,
      20,
    ).subtract(const Duration(days: 1));
    if (scheduled.isBefore(now)) {
      return;
    }
    await _notificationsPlugin.zonedSchedule(
      _plannedNotificationId(expense.id),
      '予定の支払い',
      '${expense.memo?.isNotEmpty == true ? expense.memo : '支払い予定'}の前日リマインド',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'planned_reminder',
          'Planned Reminder',
          channelDescription: '予定支払いの前日通知',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
    );
  }

  Future<void> cancelPlannedReminder(String expenseId) async {
    await initialize();
    await _notificationsPlugin.cancel(_plannedNotificationId(expenseId));
  }

  Future<void> cancelAllPlannedReminders(Iterable<String> expenseIds) async {
    for (final id in expenseIds) {
      await cancelPlannedReminder(id);
    }
  }

  int _plannedNotificationId(String expenseId) => expenseId.hashCode & 0x7fffffff;
}
