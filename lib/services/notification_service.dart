import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// INIT (panggil di main.dart)
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  /// ✅ FIX ERROR: REQUEST PERMISSION (Android 13+)
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
  }

  /// 🔔 STICKY NOTIFICATION (JADWAL SHOLAT)
  Future<void> showStickyPrayerNotification({
    required Map timings,
    required String nextPrayer,
    required DateTime nextTime,
    required bool isId,
  }) async {
    final text =
        "Fajr ${timings['Fajr']} • "
        "Dhuhr ${timings['Dhuhr']} • "
        "Asr ${timings['Asr']} • "
        "Maghrib ${timings['Maghrib']} • "
        "Isha ${timings['Isha']}\n"
        "${isId ? 'Berikutnya' : 'Next'}: $nextPrayer ${_fmt(nextTime)}";

    const android = AndroidNotificationDetails(
      'sticky_prayer_channel',
      'Jadwal Sholat',
      channelDescription: 'Jadwal sholat harian',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
    );

    await _plugin.show(
      9999,
      isId ? 'Jadwal Sholat' : 'Prayer Schedule',
      text,
      const NotificationDetails(android: android),
    );
  }

  /// ⚠️ ISTIMA (10 MENIT SEBELUM)
  Future<void> showIstimaNotification(bool isId) async {
    const android = AndroidNotificationDetails(
      'istima_channel',
      'Istima',
      channelDescription: 'Peringatan waktu istima',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true, // default sound user
    );

    await _plugin.show(
      2002,
      isId ? 'Peringatan Istima' : 'Istima Warning',
      isId ? 'Hentikan sholat sunnah' : 'Stop voluntary prayers',
      const NotificationDetails(android: android),
    );
  }

  /// 🔊 ADZAN (PAKAI DEFAULT SOUND DEVICE)
  Future<void> showAdzanNotification(String prayerName, bool isId) async {
    const android = AndroidNotificationDetails(
      'adzan_channel',
      'Adzan',
      channelDescription: 'Notifikasi adzan',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      fullScreenIntent: true,
    );

    await _plugin.show(
      1001,
      isId ? 'Waktu Sholat' : 'Prayer Time',
      isId ? 'Telah masuk waktu $prayerName' : 'It is time for $prayerName',
      const NotificationDetails(android: android),
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

final notificationService = NotificationService();
