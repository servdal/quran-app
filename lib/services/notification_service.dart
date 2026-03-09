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

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const linux = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const windows = WindowsInitializationSettings(
      appName: 'Quran App',
      appUserModelId: 'quran_app',
      guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
    );

    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
      linux: linux,
      windows: windows,
    );

    await _plugin.initialize(settings);

    /// Android permission
    if (Platform.isAndroid) {
      final androidImplementation =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  /// ================= PERMISSION =================
  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
    }
  }

  /// ================= ISTIMA =================
  Future<void> showIstimaNotification(bool isId) async {
    const android = AndroidNotificationDetails(
      'istima_channel',
      'Istima',
      channelDescription: 'Waktu istima akan segera tiba',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const linux = LinuxNotificationDetails(defaultActionName: 'Open');
    const windows = WindowsNotificationDetails();

    await _plugin.show(
      2002,
      isId ? 'Waktu Istima' : 'Istima Time',
      isId
          ? 'Bersiaplah adzan akan segera berkumandang'
          : 'Get ready, adzan will soon sound',
      const NotificationDetails(
        android: android,
        linux: linux,
        windows: windows,
      ),
    );
  }

  /// ================= ADZAN =================
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

    const linux = LinuxNotificationDetails(defaultActionName: 'Open');
    const windows = WindowsNotificationDetails();

    await _plugin.show(
      1001,
      isId ? 'Waktu Sholat' : 'Prayer Time',
      isId ? 'Telah masuk waktu $prayerName' : 'It is time for $prayerName',
      const NotificationDetails(
        android: android,
        linux: linux,
        windows: windows,
      ),
    );
  }

  /// ================= ISTIMA SCHEDULE =================
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
        linux: LinuxNotificationDetails(defaultActionName: 'Open'),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// ================= ADZAN SCHEDULE =================
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
        linux: LinuxNotificationDetails(defaultActionName: 'Open'),
        windows: WindowsNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// ================= STICKY =================
  Future<void> showSticky({
    required Map timings,
    required String nextPrayer,
    required DateTime nextTime,
    required bool isId,
    required String location,
  }) async {
    final tableContent = '''
$location

Subuh   Dzuhur  Ashar   Maghrib Isya
${timings['Fajr']}   ${timings['Dhuhr']}   ${timings['Asr']}   ${timings['Maghrib']}   ${timings['Isha']}

${isId ? 'Berikutnya' : 'Next'}: $nextPrayer ${_fmt(nextTime)}
''';

    const android = AndroidNotificationDetails(
      'sticky_prayer_channel',
      'Jadwal Sholat',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      showWhen: false,
    );

    await _plugin.show(
      9999,
      isId ? 'Jadwal Sholat' : 'Prayer Schedule',
      tableContent,
      const NotificationDetails(
        android: android,
        linux: LinuxNotificationDetails(defaultActionName: 'Open'),
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

final notificationService = NotificationService();