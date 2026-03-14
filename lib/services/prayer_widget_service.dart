import 'dart:io';

import 'package:home_widget/home_widget.dart';

class PrayerWidgetService {
  static const String _androidProviderName = 'PrayerWidgetProvider';

  static Future<void> updateFromPrayerData(Map<String, dynamic> data) async {
    if (!Platform.isAndroid) return;

    final timings = (data['timings'] as Map?) ?? const <String, dynamic>{};
    await HomeWidget.saveWidgetData<String>(
      'location',
      (data['location'] ?? '').toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'hijriDate',
      (data['hijriDate'] ?? '').toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'closestPrayer',
      (data['closestPrayer'] ?? '').toString(),
    );
    await HomeWidget.saveWidgetData<String>(
      'closestTime',
      _fmtTime(data['closestTime']),
    );

    for (final key in const ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final v = timings[key];
      if (v != null) {
        await HomeWidget.saveWidgetData<String>(key, v.toString());
      }
    }

    await HomeWidget.updateWidget(androidName: _androidProviderName);
  }

  static Future<bool> requestPinWidget() async {
    if (!Platform.isAndroid) return false;
    try {
      await HomeWidget.requestPinWidget(
        androidName: _androidProviderName,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _fmtTime(dynamic value) {
    if (value is DateTime) {
      final hh = value.hour.toString().padLeft(2, '0');
      final mm = value.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }
    return (value ?? '').toString();
  }
}
