// lib/models/surah_index_model.dart

class SurahIndexInfo {
  final int suraId;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs; // Kita tambahkan ini agar tidak error di UI

  SurahIndexInfo({
    required this.suraId,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
  });

  factory SurahIndexInfo.fromJson(Map<String, dynamic> json) {
    return SurahIndexInfo(
      suraId: json['sura_id'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      revelationType: json['revelationType'],
      numberOfAyahs: json['number_of_ayahs'] ?? 0, // Ambil dari JSON jika ada
    );
  }
}