import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void adzanAlarmCallback() async {
  final plugin = FlutterLocalNotificationsPlugin();

  const android = AndroidNotificationDetails(
    'adzan_channel',
    'Adzan',
    channelDescription: 'Alarm adzan default device',
    importance: Importance.max,
    priority: Priority.max,
    playSound: true, // 🔥 DEFAULT DEVICE SOUND
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
  );

  await plugin.show(
    1001,
    'Waktu Sholat',
    'Sudah masuk waktu sholat',
    const NotificationDetails(android: android),
  );
}
