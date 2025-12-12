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

  factory Surah.fromJson(Map<String, dynamic> json) {
    var ayahsListFromJson = json['data'] as List? ?? [];
    List<Ayah> parsedAyahs =
        ayahsListFromJson.map((i) => Ayah.fromJson(i)).toList();

    return Surah(
      id: json['sura_id'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      revelationType: json['revelationType'],
      ayahs: parsedAyahs,
    );
  }

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
