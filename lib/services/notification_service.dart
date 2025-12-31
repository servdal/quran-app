import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// ================= INIT =================
  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          macOS: initializationSettingsDarwin,
          iOS: initializationSettingsDarwin,
        );

    await _plugin.initialize(initializationSettings);
  }

  /// ================= PERMISSION =================
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, sound: true);
    }
  }

  Future<void> showIstimaNotification(bool isId) async {
    const android = AndroidNotificationDetails(
      'istima_channel',
      'Istima',
      channelDescription: 'Waktu istima akan segera tiba',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    await _plugin.show(
      2002,
      isId ? 'Waktu Istima' : 'Istima Time',
      isId
          ? 'Bersiaplah adzan akan segera berkumandang'
          : 'Get ready, adzan will soon sound',
      const NotificationDetails(android: android),
    );
  }

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

  /// ================= ISTIMA =================
  Future<void> scheduleIstima({
    required DateTime prayerTime,
    required bool isId,
  }) async {
    final istimaTime = prayerTime.subtract(const Duration(minutes: 10));
    if (istimaTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      2002,
      isId ? 'Waktu Istima' : 'Istima Time',
      isId
          ? 'Bersiaplah adzan akan segera berkumandang'
          : 'Get ready, adzan will soon sound',
      tz.TZDateTime.from(istimaTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'istima_channel',
          'Istima',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// ================= ADZAN =================
  Future<void> scheduleAdzan({
    required DateTime time,
    required String prayer,
    required bool isId,
  }) async {
    await _plugin.zonedSchedule(
      1001,
      isId ? 'Waktu Sholat' : 'Prayer Time',
      isId ? 'Telah masuk waktu $prayer' : 'It is time for $prayer',
      tz.TZDateTime.from(time, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'adzan_channel',
          'Adzan',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// ================= STICKY =================
  String _buildTableBody({
    required bool isId,
    required String lokasi,
    required Map timings,
    required String nextPrayer,
    required String nextTime,
  }) {
    String line(String t) => t.padRight(7);
    final body = '''
    $lokasi
    
    ${line('Subuh')}${line('Dhuhr')}${line('Asr')}${line('Maghrib')}${line('Isha')}
    ${line(timings['Fajr'])}${line(timings['Dhuhr'])}${line(timings['Asr'])}${line(timings['Maghrib'])}${line(timings['Isha'])}

    ${isId ? 'Berikutnya' : 'Next'}: $nextPrayer $nextTime
    ''';
    return body;
  }

  Future<void> showSticky({
    required Map timings,
    required String nextPrayer,
    required DateTime nextTime,
    required bool isId,
    required String location,
  }) async {
    final String tableContent = _buildTableBody(
      isId: isId,
      lokasi: location,
      timings: timings,
      nextPrayer: nextPrayer,
      nextTime: _fmt(nextTime),
    );
    final notificationDetails = NotificationDetails(
      android: const AndroidNotificationDetails(
        'sticky_prayer_channel',
        'Jadwal Sholat',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        playSound: false,
        showWhen: false,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        threadIdentifier: "prayer_schedule",
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: false,
        interruptionLevel: InterruptionLevel.passive,
      ),
    );

    await _plugin.show(
      9999,
      isId ? 'Jadwal Sholat' : 'Prayer Schedule',
      tableContent,
      notificationDetails,
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

final notificationService = NotificationService();
