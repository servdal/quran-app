import 'package:flutter/material.dart';

class TajweedRule {
  final String key;
  final String name;
  final Color color;
  final String description;

  const TajweedRule({
    required this.key,
    required this.name,
    required this.color,
    required this.description,
  });
}

class AppTheme {
  static final List<TajweedRule> tajweedRules = [
    const TajweedRule(
        key: 'h',
        name: 'Hamza Wasl',
        color: Color(0xFFAAAAAA),
        description: 'Hamzah yang diucapkan saat memulai bacaan, namun tidak diucapkan saat berada di tengah kalimat.'),
    const TajweedRule(
        key: 'h_auto',
        name: 'Hamzah Washal (Otomatis)',
        color: Color(0xFF9E9E9E),
        description: 'Hamzah yang hanya dibaca saat memulai bacaan dan gugur ketika disambung. Pada mode deteksi otomatis, huruf ini tidak diperlakukan sebagai huruf mad dan tidak mempengaruhi hukum tajwid di sekitarnya.'),
    const TajweedRule(
        key: 's',
        name: 'Silent',
        color: Color(0xFFAAAAAA),
        description: 'Menandakan huruf yang tidak dilafalkan (dibaca). Meskipun tertulis, huruf ini dilewati saat membaca.'),
    const TajweedRule(
        key: 'l',
        name: 'Laam Shamsiyah',
        color: Color(0xFFAAAAAA),
        description: 'Terjadi ketika "Alif Lam" (ال) bertemu dengan salah satu dari 14 huruf Syamsiyah. Huruf Lam tidak dibaca, melainkan dilebur ke huruf berikutnya.'),
    const TajweedRule(
        key: 'n',
        name: 'Madda Normal (2 harakat)',
        color: Color(0xFF537FFF),
        description: 'Juga dikenal sebagai Mad Thabi\'i. Terjadi ketika Fathah diikuti Alif, Kasrah diikuti Ya Sukun, atau Dhammah diikuti Wau Sukun. Dibaca panjang 2 harakat.'),
    const TajweedRule(
        key: 'p',
        name: 'Madda Permissible (2, 4, 6 harakat)',
        color: Color(0xFF4050FF),
        description: 'Juga dikenal sebagai Mad Jaiz Munfasil. Terjadi ketika Mad Thabi\'i bertemu dengan Hamzah di lain kata. Boleh dibaca panjang 2, 4, atau 6 harakat.'),
    const TajweedRule(
        key: 'm',
        name: 'Madda Necessary (6 harakat)',
        color: Color(0xFF000EBC),
        description: 'Juga dikenal sebagai Mad Lazim. Terjadi ketika Mad Thabi\'i bertemu dengan Tasydid atau Sukun asli dalam satu kata. Wajib dibaca panjang 6 harakat.'),
    const TajweedRule(
        key: 'q',
        name: 'Qalqalah',
        color: Color(0xFFDD0008),
        description: 'Memantulkan suara pada huruf sukun (mati) di antara lima huruf: Qaf (ق), Tha (ط), Ba (ب), Jim (ج), Dal (د).'),
    const TajweedRule(
        key: 'o',
        name: 'Madda Obligatory (4-5 harakat)',
        color: Color(0xFF2144C1),
        description: 'Juga dikenal sebagai Mad Wajib Muttasil. Terjadi ketika Mad Thabi\'i bertemu dengan Hamzah dalam satu kata yang sama. Wajib dibaca panjang 4 atau 5 harakat.'),
    const TajweedRule(
        key: 'c',
        name: 'Ikhfa Shafawi',
        color: Color(0xFFD500B7),
        description: 'Terjadi ketika Mim Sukun (مْ) bertemu dengan huruf Ba (ب). Dibaca dengan samar-samar dan didengungkan.'),
    const TajweedRule(
        key: 'f',
        name: 'Ikhfa\'',
        color: Color(0xFF9400A8),
        description: 'Juga dikenal sebagai Ikhfa Haqiqi. Terjadi ketika Nun Sukun (نْ) atau Tanwin bertemu dengan salah satu dari 15 huruf Ikhfa. Dibaca samar menuju makhraj huruf berikutnya.'),
    const TajweedRule(
        key: 'w',
        name: 'Idgham Shafawi',
        color: Color(0xFF58B800),
        description: 'Juga dikenal sebagai Idgham Mitslain. Terjadi ketika Mim Sukun (مْ) bertemu dengan huruf Mim (م). Dibaca dengan meleburkan kedua huruf Mim disertai dengungan.'),
    const TajweedRule(
        key: 'i',
        name: 'Iqlab',
        color: Color(0xFF26BFFD),
        description: 'Terjadi ketika Nun Sukun (نْ) atau Tanwin bertemu dengan huruf Ba (ب). Suara Nun atau Tanwin diubah menjadi suara Mim (م) disertai dengungan.'),
    const TajweedRule(
        key: 'a',
        name: 'Idgham dengan Ghunnah',
        color: Color(0xFF169777),
        description: 'Juga dikenal sebagai Idgham Bighunnah. Terjadi ketika Nun Sukun (نْ) atau Tanwin bertemu dengan huruf Ya (ي), Nun (ن), Mim (م), atau Wau (و). Dibaca melebur disertai dengungan.'),
    const TajweedRule(
        key: 'u',
        name: 'Idgham tanpa Ghunnah',
        color: Color(0xFF169200),
        description: 'Juga dikenal sebagai Idgham Bilaghunnah. Terjadi ketika Nun Sukun (نْ) atau Tanwin bertemu dengan huruf Lam (ل) atau Ra (ر). Dibaca melebur tanpa dengungan.'),
    const TajweedRule(
        key: 'd',
        name: 'Idgham Mutajanisayn',
        color: Color(0xFFA1A1A1),
        description: 'Meleburkan dua huruf yang sama makhrajnya (tempat keluar) tetapi berbeda sifatnya. Contoh: Ta (ت) bertemu Tha (ط).'),
    const TajweedRule(
        key: 'b',
        name: 'Idgham Mutaqaribayn',
        color: Color(0xFFA1A1A1),
        description: 'Meleburkan dua huruf yang makhraj dan sifatnya berdekatan. Contoh: Qaf (ق) bertemu Kaf (ك).'),
    const TajweedRule(
        key: 'jalalah',
        name: 'Lafẓ Jalālah',
        color: Color(0xFF2E7D32),
        description:'Kata khusus yang merujuk kepada Allah (اللّٰهُ dan turunannya seperti اللَّهُمَّ). Memiliki kaidah bacaan khusus dan tidak mengikuti hukum mad, idgham, atau ikhfa. Harakat akhirnya harus dijaga dan tidak boleh berubah.'),
    const TajweedRule(
        key: 'g',
        name: 'Ghunnah',
        color: Color(0xFFFF7E1E),
        description: 'Dengungan yang keluar dari rongga hidung. Terjadi pada setiap huruf Nun (ن) dan Mim (م) yang bertasydid. Dibaca dengan menahan suara selama 2 harakat.'),
    const TajweedRule(
        key: 'maddah_fix',
        name: 'Alif Maddah Khusus',
        color: Color(0xFF5C6BC0),
        description: 'Menandai Alif Maddah (آ) atau kombinasi Alif dengan Dagger Alef (ٰ) yang tidak boleh diperlakukan sebagai dua mad. Mad hanya dihitung satu kali sesuai kaidah Mushaf Indonesia.'),
  ];

  static final Map<String, Color> tajweedColors = {
    for (var rule in tajweedRules) rule.key: rule.color,
  };

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF16A34A), 
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF16A34A),
      secondary: Color(0xFF1B7942),
      background: Color(0xFFF8F9FA),
      surface: Colors.white,
      onPrimary: Colors.white,
      onBackground: Color(0xFF212529),
      onSurface: Color(0xFF212529),
    ),

    fontFamily: 'Poppins',
    
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF212529)),
      bodyMedium: TextStyle(fontFamily: 'Poppins', color: Color(0xFF212529), height: 1.5),
      labelLarge: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
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
      fillColor: Colors.grey[100],
      hintStyle: TextStyle(color: Colors.grey[500]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF16A34A),
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
      labelColor: const Color(0xFF16A34A),
      unselectedLabelColor: Colors.grey[600],
    ),
  );
  
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

