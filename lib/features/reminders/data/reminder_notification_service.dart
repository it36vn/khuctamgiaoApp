import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminder.dart';

class ReminderNotificationService {
  ReminderNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> start(GoRouter router) async {
    if (_initialized) return;
    final initializing = _initializing;
    if (initializing != null) return initializing;
    _initializing = _start(router);
    await _initializing;
  }

  Future<void> _start(GoRouter router) async {
    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
      onDidReceiveNotificationResponse: (response) {
        final route = _routeFromPayload(response.payload);
        if (route != null) router.go(route);
      },
    );
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
    await android?.requestFullScreenIntentPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedule(Reminder reminder) async {
    await _initializing;
    await cancel(reminder);
    if (!reminder.scheduledAt.isAfter(DateTime.now())) return;
    await requestPermissions();

    final scheduledAt = tz.TZDateTime.from(reminder.scheduledAt, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId(reminder.importance),
        _channelName(reminder.importance),
        channelDescription: 'Reminder alarms',
        importance: _androidImportance(reminder.importance),
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        id: reminder.notificationId,
        title: reminder.title,
        body: reminder.content,
        scheduledDate: scheduledAt,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        payload: '/reminders/${reminder.id}',
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: reminder.notificationId,
        title: reminder.title,
        body: reminder.content,
        scheduledDate: scheduledAt,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '/reminders/${reminder.id}',
      );
    }
  }

  Future<void> cancel(Reminder reminder) {
    return _plugin.cancel(id: reminder.notificationId);
  }

  Future<void> cancelById(String id) {
    final notificationId = id.codeUnits.fold<int>(0, (value, code) {
      return ((value * 31) + code) & 0x7fffffff;
    });
    return _plugin.cancel(id: notificationId);
  }

  String? _routeFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    if (payload == '/reminders' || payload.startsWith('/reminders/')) {
      return payload;
    }
    return null;
  }

  static String _channelId(ReminderImportance importance) {
    return switch (importance) {
      ReminderImportance.normal => 'reminders_normal',
      ReminderImportance.important => 'reminders_important',
      ReminderImportance.critical => 'reminders_critical',
    };
  }

  static String _channelName(ReminderImportance importance) {
    return switch (importance) {
      ReminderImportance.normal => 'Reminders',
      ReminderImportance.important => 'Important reminders',
      ReminderImportance.critical => 'Very important reminders',
    };
  }

  static Importance _androidImportance(ReminderImportance importance) {
    return switch (importance) {
      ReminderImportance.normal => Importance.defaultImportance,
      ReminderImportance.important => Importance.high,
      ReminderImportance.critical => Importance.max,
    };
  }
}
