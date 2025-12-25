// main.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'screens/language_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await notificationService.init();
  await notificationService.requestPermissions();

  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('selected_language');
  runApp(ProviderScope(child: MyApp(initialLang: lang)));
}

class MyApp extends ConsumerWidget {
  final String? initialLang;
  const MyApp({super.key, required this.initialLang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ThemeData theme;
    switch (settings.theme) {
      case AppThemeType.dark:
        theme = AppTheme.darkTheme;
        break;
      case AppThemeType.pink:
        theme = AppTheme.pinkTheme;
        break;
      default:
        theme = AppTheme.lightTheme;
    }
    return MaterialApp(
      title: 'Mushaf',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home:
          initialLang == null
              ? const LanguageSelectorScreen()
              : const SplashScreen(),
    );
  }
}
