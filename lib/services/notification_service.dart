// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern
  static final NotificationService _notificationService = NotificationService._internal();
  factory NotificationService() {
    return _notificationService;
  }
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Inisialisasi Timezone
    tz.initializeTimeZones(); 

    // Pengaturan Inisialisasi untuk Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_notification');

    // Pengaturan Inisialisasi untuk iOS dan macOS (keduanya menggunakan Darwin)
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // --- PERUBAHAN DI SINI ---
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin, // Gunakan pengaturan Darwin
      macOS: initializationSettingsDarwin, // Tambahkan ini dan gunakan pengaturan Darwin yang sama
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> scheduleAdzanNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
  }) async {
    // Meminta izin notifikasi untuk Android 13+
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Waktu Sholat Telah Tiba',
      'Saatnya menunaikan sholat $prayerName',
      tz.TZDateTime.from(scheduledTime, tz.local), 
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adzan_channel_id',
          'Notifikasi Adzan',  
          channelDescription: 'Channel untuk notifikasi waktu sholat.',
          importance: Importance.max,
          priority: Priority.high,
          sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true, 
        ),
        // Untuk macOS, kita bisa biarkan kosong agar menggunakan default
        // atau definisikan secara spesifik jika perlu
        macOS: DarwinNotificationDetails(
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}