// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:f5_health/main.dart'; // navigatorKey 사용을 위해

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotification() async {
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings settings = InitializationSettings(
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      _onNotificationClicked();
    },
  );

  tz.initializeTimeZones();
}

void _onNotificationClicked() {
  navigatorKey.currentState?.pushNamed('/entry');
}

Future<void> scheduleDailyAlarm(TimeOfDay time) async {
  final now = DateTime.now();
  final scheduledDate =
      DateTime(now.year, now.month, now.day, time.hour, time.minute);
  final alarmTime = scheduledDate.isBefore(now)
      ? scheduledDate.add(const Duration(days: 1))
      : scheduledDate;

  await flutterLocalNotificationsPlugin.zonedSchedule(
    0, // 알람 ID
    '입력 알림',
    '하루를 마무리하는 일괄 입력을 할 시간이에요!',
    tz.TZDateTime.from(alarmTime, tz.local),
    const NotificationDetails(
      iOS: DarwinNotificationDetails(),
    ),
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
    androidAllowWhileIdle: true,
  );
}

Future<void> cancelAlarm() async {
  await flutterLocalNotificationsPlugin.cancel(0);
}
