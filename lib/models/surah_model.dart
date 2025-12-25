import 'package:quran_app/models/ayah_model.dart';

class Surah {
  final int id;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final List<Ayah> ayahs;

  Surah({
    required this.id,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.ayahs,
  });

  /// 🔥 NEW: from SQLite rows
  factory Surah.fromDb(int surahId, List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return Surah(
        id: surahId,
        name: '',
        englishName: '',
        englishNameTranslation: '',
        revelationType: '',
        ayahs: [],
      );
    }

    final first = rows.first;

    return Surah(
      id: surahId,
      name: first['sura_name_arabic'] ?? '',
      englishName: first['sura_name'] ?? '',
      englishNameTranslation: first['sura_name_translation'] ?? '',
      revelationType: first['location'] ?? '',
      ayahs: rows.map((r) => Ayah.fromDb(r)).toList(),
    );
  }
}
