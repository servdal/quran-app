// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:quran_app/theme/app_theme.dart'; // Import tema baru

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tafsir Jalalayn Audio KH. Bahauddin Nursalim',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Gunakan tema baru di sini
      home: const SplashScreen(),
    );
  }
}