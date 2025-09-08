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
  final int ayaId;
  final int juzId;
  final int ayaNumber;
  final String ayaText;
  final int suraId;
  final String translationAyaText;
  final String tafsirJalalayn;
  final bool sajda;
  final SurahInfo? surah;
  final String transliteration;
  final int pageNumber;
  final String tajweedText;

  Ayah({
    required this.ayaId,
    required this.juzId,
    required this.ayaNumber,
    required this.ayaText,
    required this.suraId,
    required this.translationAyaText,
    required this.tafsirJalalayn,
    required this.sajda,
    this.surah,
    required this.transliteration,
    required this.pageNumber,
    required this.tajweedText,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      ayaId: json['aya_id'],
      juzId: json['juz_id'],
      ayaNumber: json['aya_number'],
      ayaText: json['aya_text'],
      suraId: json['sura_id'],
      translationAyaText: json['translation_aya_text'],
      tafsirJalalayn: json['tafsir_jalalayn'] ?? 'Tafsir tidak tersedia.',
      sajda: json['sajda'] ?? false,
      surah: json['surah'] != null ? SurahInfo.fromJson(json['surah']) : null,
      transliteration: json['transliteration'] ?? '',
      pageNumber: json['page_number'],
      tajweedText: json['tajweed_text'],
    );
  }
}

