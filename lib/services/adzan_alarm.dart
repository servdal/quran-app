import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void adzanAlarmCallback() async {
  final plugin = FlutterLocalNotificationsPlugin();

  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('adzan_sound_enabled') ?? true;
  final modeIndex = prefs.getInt('adzan_sound_mode') ?? 0; // 0=native, 1=adzan
  final soundName = prefs.getString('adzan_sound_name') ?? 'azan1';

  final useCustom =
      enabled && Platform.isAndroid && modeIndex == 1 && soundName.isNotEmpty;
  final channelId =
      !enabled
          ? 'adzan_channel_silent'
          : (useCustom ? 'adzan_channel_$soundName' : 'adzan_channel_native');

  if (Platform.isAndroid) {
    final androidImplementation =
        plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final channel = AndroidNotificationChannel(
      channelId,
      'Adzan',
      description: 'Alarm adzan',
      importance: Importance.max,
      playSound: enabled,
      sound: useCustom ? RawResourceAndroidNotificationSound(soundName) : null,
    );
    await androidImplementation?.createNotificationChannel(channel);
  }

  final android = AndroidNotificationDetails(
    channelId,
    'Adzan',
    channelDescription: 'Alarm adzan',
    importance: Importance.max,
    priority: Priority.max,
    playSound: enabled,
    sound: useCustom ? RawResourceAndroidNotificationSound(soundName) : null,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
  );

  await plugin.show(
    1001,
    'Waktu Sholat',
    'Sudah masuk waktu sholat',
    NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(presentSound: enabled),
      macOS: DarwinNotificationDetails(presentSound: enabled),
    ),
  );
}
