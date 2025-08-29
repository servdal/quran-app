// lib/models/ayah_model.dart
class SurahInfo {
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;

  SurahInfo({
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
  });

  factory SurahInfo.fromJson(Map<String, dynamic> json) {
    return SurahInfo(
      name: json['name'] ?? '',
      englishName: json['englishName'] ?? '',
      englishNameTranslation: json['englishNameTranslation'] ?? '',
      revelationType: json['revelationType'] ?? '',
    );
  }
}

class Ayah {
  final int ayaNumber;
  final String ayaText;
  final int suraId;
  final String translationAyaText;
  final String tafsirJalalayn;
  final bool sajda;
  final SurahInfo? surah; // Informasi surah untuk setiap ayat

  Ayah({
    required this.ayaNumber,
    required this.ayaText,
    required this.suraId,
    required this.translationAyaText,
    required this.tafsirJalalayn,
    required this.sajda,
    this.surah,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      ayaNumber: json['aya_number'],
      ayaText: json['aya_text'],
      suraId: json['sura_id'],
      translationAyaText: json['translation_aya_text'],
      // Pastikan key tafsir sesuai dengan file JSON Anda
      tafsirJalalayn: json['tafsir_jalalayn'] ?? 'Tafsir tidak tersedia.',
      sajda: json['sajda'] ?? false,
      surah: json['surah'] != null ? SurahInfo.fromJson(json['surah']) : null,
    );
  }
}