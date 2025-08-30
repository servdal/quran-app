import 'package:flutter/material.dart';

class AppTheme {
  // Peta warna tajwid tetap sama, tidak terpengaruh oleh tema
  static const Map<String, Color> tajweedColors = {
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

  // #### TEMA TERANG BARU DIDEFINISikan DI SINI ####
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF16A34A), // Hijau
    scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Latar belakang abu-abu sangat terang
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF16A34A),
      secondary: Color(0xFF1B7942), // Hijau lebih gelap untuk aksen
      background: Color(0xFFF8F9FA),
      surface: Colors.white, // Warna Card
      onPrimary: Colors.white, // Teks di atas warna primer (misal: tombol)
      onBackground: Color(0xFF212529), // Warna teks utama
      onSurface: Color(0xFF212529), // Warna teks di atas card
    ),

    fontFamily: 'Poppins',
    
    // Teks diubah menjadi warna gelap agar terbaca di latar terang
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF212529)),
      // Warna bodyMedium digelapkan sedikit untuk kontras yang lebih baik
      bodyMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFF212529), height: 1.5),
      labelLarge: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, // AppBar berwarna putih
      elevation: 1,
      centerTitle: true,
      // Ikon dan teks di AppBar berwarna gelap
      iconTheme: IconThemeData(color: Color(0xFF212529)),
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF212529))
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[100], // Latar search bar
      hintStyle: TextStyle(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    
    // Tema tambahan untuk memastikan kejelasan komponen
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16A34A), // Warna primer
        // Warna teks tombol diubah sesuai permintaan
        foregroundColor: const Color(0xFFFFFFFF), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    tabBarTheme: TabBarThemeData(
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Color(0xFF16A34A), width: 2),
      ),
      labelColor: const Color(0xFF16A34A), // Tab yang aktif berwarna hijau
      unselectedLabelColor: Colors.grey[600], // Tab yang tidak aktif berwarna abu-abu
    ),
  );
  
  // Tema gelap yang lama tetap ada jika Anda ingin menggunakannya lagi
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
      labelLarge: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold),
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

