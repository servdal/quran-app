import 'package:flutter/material.dart';

class TajweedRule {
  final String key;
  final String nameId; // Nama Bahasa Indonesia
  final String nameEn; // Nama Bahasa Inggris
  final Color color;
  final String descriptionId; // Deskripsi Bahasa Indonesia
  final String descriptionEn; // Deskripsi Bahasa Inggris

  const TajweedRule({
    required this.key,
    required this.nameId,
    required this.nameEn,
    required this.color,
    required this.descriptionId,
    required this.descriptionEn,
  });

  // Fungsi pembantu untuk UI
  String getName(String langCode) => langCode == 'en' ? nameEn : nameId;
  String getDescription(String langCode) =>
      langCode == 'en' ? descriptionEn : descriptionId;
}

class AppTheme {
  static final List<TajweedRule> tajweedRules = [
    const TajweedRule(
      key: 'h',
      nameId: 'Hamzah Washal',
      nameEn: 'Hamzah Wasl',
      color: Color(0xFFAAAAAA),
      descriptionId:
          'Hamzah yang diucapkan saat memulai bacaan, namun tidak diucapkan saat berada di tengah kalimat.',
      descriptionEn:
          'Hamzah pronounced at the beginning of a word but skipped when connected with the previous word.',
    ),
    const TajweedRule(
      key: 'h_auto',
      nameId: 'Hamzah Washal (Otomatis)',
      nameEn: 'Hamzah Wasl (Auto)',
      color: Color(0xFF9E9E9E),
      descriptionId:
          'Hamzah yang hanya dibaca saat memulai bacaan dan gugur ketika disambung.',
      descriptionEn:
          'Hamzah that is only read when starting a recitation and dropped when connected.',
    ),
    const TajweedRule(
      key: 's',
      nameId: 'Silent',
      nameEn: 'Silent',
      color: Color(0xFFAAAAAA),
      descriptionId:
          'Menandakan huruf yang tidak dilafalkan (dibaca) meskipun tertulis.',
      descriptionEn: 'Indicates letters that are written but not pronounced.',
    ),
    const TajweedRule(
      key: 'l',
      nameId: 'Laam Shamsiyah',
      nameEn: 'Solar Laam',
      color: Color(0xFFAAAAAA),
      descriptionId:
          'Huruf Lam tidak dibaca, melainkan dilebur ke huruf berikutnya (huruf Syamsiyah).',
      descriptionEn:
          'The letter Laam is not pronounced and is merged into the following solar letter.',
    ),
    const TajweedRule(
      key: 'n',
      nameId: 'Mad Thabi\'i',
      nameEn: 'Natural Madda',
      color: Color(0xFF537FFF),
      descriptionId:
          'Pemanjangan suara sebanyak 2 harakat pada huruf Alif, Ya, atau Wau.',
      descriptionEn:
          'Natural prolongation of sound for 2 beats on Alif, Ya, or Waw.',
    ),
    const TajweedRule(
      key: 'p',
      nameId: 'Mad Jaiz Munfasil',
      nameEn: 'Permissible Madda',
      color: Color(0xFF4050FF),
      descriptionId:
          'Mad Thabi\'i bertemu Hamzah di lain kata. Dibaca panjang 2, 4, atau 5 harakat.',
      descriptionEn:
          'Natural Madda followed by a Hamzah in a different word. Prolonged for 2, 4, or 5 beats.',
    ),
    const TajweedRule(
      key: 'm',
      nameId: 'Mad Lazim',
      nameEn: 'Necessary Madda',
      color: Color(0xFF000EBC),
      descriptionId:
          'Mad Thabi\'i bertemu dengan Tasydid atau Sukun asli. Wajib dibaca panjang 6 harakat.',
      descriptionEn:
          'Natural Madda followed by a Shaddah or a permanent Sukun. Must be prolonged for 6 beats.',
    ),
    const TajweedRule(
      key: 'q',
      nameId: 'Qalqalah',
      nameEn: 'Qalqalah (Echoing)',
      color: Color(0xFFDD0008),
      descriptionId: 'Memantulkan suara pada huruf sukun: ق, ط, ب, ج, d.',
      descriptionEn:
          'Echoing or bouncing sound on a sukun letter from: Qaf, Tha, Ba, Jeem, Dal.',
    ),
    const TajweedRule(
      key: 'o',
      nameId: 'Mad Wajib Muttasil',
      nameEn: 'Obligatory Madda',
      color: Color(0xFF2144C1),
      descriptionId:
          'Mad Thabi\'i bertemu dengan Hamzah dalam satu kata. Wajib dibaca panjang 4 atau 5 harakat.',
      descriptionEn:
          'Natural Madda followed by a Hamzah in the same word. Prolonged for 4 or 5 beats.',
    ),
    const TajweedRule(
      key: 'c',
      nameId: 'Ikhfa Shafawi',
      nameEn: 'Labial Ikhfa',
      color: Color(0xFFD500B7),
      descriptionId:
          'Mim Sukun bertemu dengan huruf Ba (ب). Dibaca samar dengan dengungan.',
      descriptionEn:
          'Meem Sakinah followed by the letter Ba. Pronounced with a light nasal sound.',
    ),
    const TajweedRule(
      key: 'f',
      nameId: 'Ikhfa Haqiqi',
      nameEn: 'Ikhfa (Hiding)',
      color: Color(0xFF9400A8),
      descriptionId:
          'Nun Sukun atau Tanwin bertemu salah satu dari 15 huruf ikhfa. Dibaca samar.',
      descriptionEn:
          'Nun Sakinah or Tanween followed by one of the 15 ikhfa letters. Pronounced with a nasal hiding sound.',
    ),
    const TajweedRule(
      key: 'w',
      nameId: 'Idgham Shafawi',
      nameEn: 'Labial Idgham',
      color: Color(0xFF58B800),
      descriptionId:
          'Mim Sukun bertemu dengan huruf Mim. Dibaca melebur disertai dengungan.',
      descriptionEn:
          'Meem Sakinah followed by another Meem. Merged with a nasal sound (Ghunnah).',
    ),
    const TajweedRule(
      key: 'i',
      nameId: 'Iqlab',
      nameEn: 'Iqlab (Conversion)',
      color: Color(0xFF26BFFD),
      descriptionId:
          'Nun Sukun atau Tanwin bertemu huruf Ba. Suara berubah menjadi Mim disertai dengungan.',
      descriptionEn:
          'Nun Sakinah or Tanween followed by Ba. Converted to a Meem sound with Ghunnah.',
    ),
    const TajweedRule(
      key: 'a',
      nameId: 'Idgham Bighunnah',
      nameEn: 'Idgham with Ghunnah',
      color: Color(0xFF169777),
      descriptionId:
          'Nun Sukun atau Tanwin bertemu huruf ي, ن, م, و. Dibaca melebur dengan dengungan.',
      descriptionEn:
          'Nun Sakinah or Tanween followed by Yaa, Noon, Meem, or Waw. Merged with a nasal sound.',
    ),
    const TajweedRule(
      key: 'u',
      nameId: 'Idgham Bilaghunnah',
      nameEn: 'Idgham without Ghunnah',
      color: Color(0xFF169200),
      descriptionId:
          'Nun Sukun atau Tanwin bertemu huruf ل atau ر. Dibaca melebur tanpa dengungan.',
      descriptionEn:
          'Nun Sakinah or Tanween followed by Laam or Raa. Merged without a nasal sound.',
    ),
    const TajweedRule(
      key: 'd',
      nameId: 'Idgham Mutajanisayn',
      nameEn: 'Homogeneous Idgham',
      color: Color(0xFFA1A1A1),
      descriptionId:
          'Meleburkan dua huruf yang sama makhrajnya tetapi berbeda sifatnya.',
      descriptionEn:
          'Merging two letters with the same point of articulation but different characteristics.',
    ),
    const TajweedRule(
      key: 'b',
      nameId: 'Idgham Mutaqaribayn',
      nameEn: 'Convergent Idgham',
      color: Color(0xFFA1A1A1),
      descriptionId:
          'Meleburkan dua huruf yang makhraj dan sifatnya berdekatan.',
      descriptionEn:
          'Merging two letters whose points of articulation and characteristics are close.',
    ),
    const TajweedRule(
      key: 'jalalah',
      nameId: 'Lafadz Jalalah',
      nameEn: 'Word Allah (Jalalah)',
      color: Color(0xFF2E7D32),
      descriptionId:
          'Kaidah khusus untuk pengucapan kata "Allah" (tebal atau tipis).',
      descriptionEn:
          'Special rules for the pronunciation of the word "Allah" (Heavy or Light).',
    ),
    const TajweedRule(
      key: 'g',
      nameId: 'Ghunnah',
      nameEn: 'Ghunnah (Nasalization)',
      color: Color(0xFFFF7E1E),
      descriptionId:
          'Dengungan pada huruf Nun atau Mim yang bertasydid (2 harakat).',
      descriptionEn:
          'A nasal sound produced by doubling the Noon or Meem for 2 beats.',
    ),
    const TajweedRule(
      key: 'maddah_fix',
      nameId: 'Alif Maddah Khusus',
      nameEn: 'Special Alif Maddah',
      color: Color(0xFF5C6BC0),
      descriptionId:
          'Penanda khusus Alif Maddah sesuai kaidah Mushaf Indonesia.',
      descriptionEn:
          'Special Alif Maddah marker according to Indonesian Mushaf standards.',
    ),
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
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        color: Color(0xFF212529),
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFF212529),
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF212529)),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212529),
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      onPrimary: Colors.white,
      onBackground: Colors.white,
      onSurface: Colors.white,
    ),
    fontFamily: 'Poppins',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white70,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F2937),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
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
  // Tambahkan di AppTheme
  static final ThemeData pinkTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFE91E63),
    scaffoldBackgroundColor: const Color(0xFFFFF1F5),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFFE91E63),
      secondary: Color(0xFFF06292),
      background: Color(0xFFFFF1F5),
      surface: Colors.white,
      onPrimary: Colors.white,
      onBackground: Color(0xFF4A044E),
      onSurface: Color(0xFF4A044E),
    ),

    fontFamily: 'Poppins',

    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A044E),
      ),
      bodyMedium: TextStyle(color: Color(0xFF4A044E), height: 1.5),
      labelLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFE4EC),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4A044E),
      ),
      iconTheme: IconThemeData(color: Color(0xFF4A044E)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE91E63),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
