// lib/theme/app_theme.dart
import 'package.flutter/material.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF16A34A), // Hijau (Tailwind Green 600)
    scaffoldBackgroundColor: const Color(0xFF111827), // Abu-abu Gelap (Tailwind Gray 900)
    
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF16A34A), // Warna utama untuk tombol, ikon aktif
      secondary: Color(0xFF4ADE80), // Hijau lebih terang sebagai aksen
      background: Color(0xFF111827),
      surface: Color(0xFF1F2937), // Warna Card (Tailwind Gray 800)
    ),

    fontFamily: 'Poppins', // Tetap gunakan Poppins atau ganti ke Inter
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.Bold, color: Colors.white),
      bodyMedium: TextStyle(fontFamily: 'Poppins', color: Colors.white70, height: 1.5),
      labelLarge: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F2937), // Sedikit lebih terang dari background
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
    ),

    cardTheme: CardTheme(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      color: const Color(0xFF1F2937), // Warna Card
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF374151), // Tailwind Gray 700
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}