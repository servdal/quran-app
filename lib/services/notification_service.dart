import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum _AdzanSoundMode { native, adzan }

class _AdzanSoundConfig {
  final bool enabled;
  final _AdzanSoundMode mode;
  final String name; // android res/raw name, e.g. azan1

  const _AdzanSoundConfig({
    required this.enabled,
    required this.mode,
    required this.name,
  });

  bool get useCustomAndroidSound =>
      enabled && mode == _AdzanSoundMode.adzan && name.isNotEmpty;
}

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

  Future<_AdzanSoundConfig> _loadAdzanSoundConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('adzan_sound_enabled') ?? true;
    final modeIndex = prefs.getInt('adzan_sound_mode') ?? 0;
    final name = prefs.getString('adzan_sound_name') ?? 'azan1';
    final idx = modeIndex.clamp(0, _AdzanSoundMode.values.length - 1).toInt();
    final mode = _AdzanSoundMode.values[idx];
    return _AdzanSoundConfig(enabled: enabled, mode: mode, name: name);
  }

  Future<void> _ensureAndroidChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required Importance importance,
    required bool playSound,
    AndroidNotificationSound? sound,
  }) async {
    if (!Platform.isAndroid) return;
    final androidImplementation =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation == null) return;

    final channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: importance,
      playSound: playSound,
      sound: sound,
    );
    await androidImplementation.createNotificationChannel(channel);
  }

  String _adzanChannelId(_AdzanSoundConfig cfg) {
    if (!cfg.enabled) return 'adzan_channel_silent';
    if (cfg.useCustomAndroidSound) return 'adzan_channel_${cfg.name}';
    return 'adzan_channel_native';
  }

  String _istimaChannelId(_AdzanSoundConfig cfg) {
    if (!cfg.enabled) return 'istima_channel_silent';
    if (cfg.useCustomAndroidSound) return 'istima_channel_${cfg.name}';
    return 'istima_channel_native';
  }

  AndroidNotificationSound? _androidSound(_AdzanSoundConfig cfg) {
    if (!cfg.useCustomAndroidSound) return null;
    return RawResourceAndroidNotificationSound(cfg.name);
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
    final cfg = await _loadAdzanSoundConfig();
    final channelId = _istimaChannelId(cfg);
    await _ensureAndroidChannel(
      channelId: channelId,
      channelName: 'Istima',
      channelDescription: 'Waktu istima akan segera tiba',
      importance: Importance.high,
      playSound: cfg.enabled,
      sound: _androidSound(cfg),
    );

    final android = AndroidNotificationDetails(
      channelId,
      'Istima',
      channelDescription: 'Waktu istima akan segera tiba',
      importance: Importance.high,
      priority: Priority.high,
      playSound: cfg.enabled,
      sound: _androidSound(cfg),
    );

    const linux = LinuxNotificationDetails(defaultActionName: 'Open');
    const windows = WindowsNotificationDetails();

    await _plugin.show(
      2002,
      isId ? 'Waktu Istima' : 'Istima Time',
      isId
          ? 'Bersiaplah adzan akan segera berkumandang'
          : 'Get ready, adzan will soon sound',
      NotificationDetails(
        android: android,
        iOS: DarwinNotificationDetails(presentSound: cfg.enabled),
        macOS: DarwinNotificationDetails(presentSound: cfg.enabled),
        linux: linux,
        windows: windows,
      ),
    );
  }

  /// ================= ADZAN =================
  Future<void> showAdzanNotification(String prayerName, bool isId) async {
    final cfg = await _loadAdzanSoundConfig();
    final channelId = _adzanChannelId(cfg);
    await _ensureAndroidChannel(
      channelId: channelId,
      channelName: 'Adzan',
      channelDescription: 'Notifikasi adzan',
      importance: Importance.max,
      playSound: cfg.enabled,
      sound: _androidSound(cfg),
    );

    final android = AndroidNotificationDetails(
      channelId,
      'Adzan',
      channelDescription: 'Notifikasi adzan',
      importance: Importance.max,
      priority: Priority.max,
      playSound: cfg.enabled,
      sound: _androidSound(cfg),
      fullScreenIntent: true,
    );

    const linux = LinuxNotificationDetails(defaultActionName: 'Open');
    const windows = WindowsNotificationDetails();

    await _plugin.show(
      1001,
      isId ? 'Waktu Sholat' : 'Prayer Time',
      isId ? 'Telah masuk waktu $prayerName' : 'It is time for $prayerName',
      NotificationDetails(
        android: android,
        iOS: DarwinNotificationDetails(presentSound: cfg.enabled),
        macOS: DarwinNotificationDetails(presentSound: cfg.enabled),
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

    final cfg = await _loadAdzanSoundConfig();
    final channelId = _istimaChannelId(cfg);
    await _ensureAndroidChannel(
      channelId: channelId,
      channelName: 'Istima',
      channelDescription: 'Waktu istima akan segera tiba',
      importance: Importance.high,
      playSound: cfg.enabled,
      sound: _androidSound(cfg),
    );

    await _plugin.zonedSchedule(
      2002,
      isId ? 'Waktu Istima' : 'Istima Time',
      isId
          ? 'Bersiaplah adzan akan segera berkumandang'
          : 'Get ready, adzan will soon sound',
      tz.TZDateTime.from(istimaTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Istima',
          channelDescription: 'Waktu istima akan segera tiba',
          importance: Importance.high,
          priority: Priority.high,
          playSound: cfg.enabled,
          sound: _androidSound(cfg),
        ),
        iOS: DarwinNotificationDetails(presentSound: cfg.enabled),
        macOS: DarwinNotificationDetails(presentSound: cfg.enabled),
        linux: const LinuxNotificationDetails(defaultActionName: 'Open'),
        windows: const WindowsNotificationDetails(),
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
    final cfg = await _loadAdzanSoundConfig();
    final channelId = _adzanChannelId(cfg);
    await _ensureAndroidChannel(
      channelId: channelId,
      channelName: 'Adzan',
      channelDescription: 'Notifikasi adzan',
      importance: Importance.max,
      playSound: cfg.enabled,
      sound: _androidSound(cfg),
    );

    await _plugin.zonedSchedule(
      1001,
      isId ? 'Waktu Sholat' : 'Prayer Time',
      isId ? 'Telah masuk waktu $prayer' : 'It is time for $prayer',
      tz.TZDateTime.from(time, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Adzan',
          channelDescription: 'Notifikasi adzan',
          importance: Importance.max,
          priority: Priority.max,
          playSound: cfg.enabled,
          sound: _androidSound(cfg),
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(presentSound: cfg.enabled),
        macOS: DarwinNotificationDetails(presentSound: cfg.enabled),
        linux: const LinuxNotificationDetails(defaultActionName: 'Open'),
        windows: const WindowsNotificationDetails(),
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
        macOS: DarwinNotificationDetails(presentSound: false),
        linux: LinuxNotificationDetails(defaultActionName: 'Open'),
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

final notificationService = NotificationService();
