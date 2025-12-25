// main.dart
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'screens/language_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && Platform.isAndroid) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(android: android),
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('selected_language');
  runApp(ProviderScope(child: MyApp(initialLang: lang)));
}

class MyApp extends StatelessWidget {
  final String? initialLang;
  const MyApp({super.key, required this.initialLang});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mushaf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home:
          initialLang == null
              ? const LanguageSelectorScreen()
              : const SplashScreen(),
    );
  }
}
