import 'package:flutter/material.dart';

class AppTheme {
  // Peta warna tajwid diperbarui sesuai referensi alquran.cloud/tajweed-guide
  static const Map<String, Color> tajweedColors = {
    // Kunci disesuaikan dengan aturan dasar dari API (huruf tunggal)
    'h': Color(0xFFAAAAAA), // hamza-wasl
    's': Color(0xFFAAAAAA), // silent
    'l': Color(0xFFAAAAAA), // laam-shamsiyah
    'n': Color(0xFF537FFF), // madda-normal (2)
    'p': Color(0xFF4050FF), // madda-permissible (2, 4, 6)
    'm': Color(0xFF000EBC), // madda-necessary (6)
    'q': Color(0xFFDD0008), // qalaqah
    'o': Color(0xFF2144C1), // madda-obligatory (4-5)
    'c': Color(0xFFD500B7), // ikhafa-shafawi
    'f': Color(0xFF9400A8), // ikhafa
    'w': Color(0xFF58B800), // idgham-shafawi
    'i': Color(0xFF26BFFD), // iqlab
    'a': Color(0xFF169777), // idgham-with-ghunnah
    'u': Color(0xFF169200), // idgham-without-ghunnah
    'd': Color(0xFFA1A1A1), // idgham-mutajanisayn
    'b': Color(0xFFA1A1A1), // idgham-mutaqaribayn
    'g': Color(0xFFFF7E1E), // ghunnah
  };

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF16A34A),
    scaffoldBackgroundColor: const Color(0xFF111827),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF16A34A),
      secondary: Color(0xFF4ADE80),
      background: Color(0xFF111827),
      surface: Color(0xFF1F2937),
    ),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white),
      bodyMedium: TextStyle(fontFamily: 'Poppins', color: Colors.white70, height: 1.5),
      labelLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.white),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F2937),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      color: const Color(0xFF1F2937),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF374151),
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

