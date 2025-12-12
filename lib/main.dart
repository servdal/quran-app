// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'screens/language_selector_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Tafsir Jalalayn dan Audio KH. Bahauddin Nursalim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initialLang == null
          ? const LanguageSelectorScreen()
          : const SplashScreen(),
    );
  }
}