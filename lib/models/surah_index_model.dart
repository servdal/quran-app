class SurahIndexInfo {
  final int suraId;
  final String nameLatin;
  final String nameArabic;
  final String translation;
  final String revelationType;
  final int numberOfAyahs;

  SurahIndexInfo({
    required this.suraId,
    required this.nameLatin,
    required this.nameArabic,
    required this.translation,
    required this.revelationType,
    required this.numberOfAyahs,
  });

  factory SurahIndexInfo.fromDb(Map<String, dynamic> row) {
    return SurahIndexInfo(
      suraId: row['sura_id'],
      nameLatin: row['sura_name'] ?? row['sura_name_en'] ?? '',
      nameArabic: row['sura_name_arabic'] ?? '',
      translation: row['sura_name_translation'] ?? row['sura_name_translation_en'] ?? '',
      revelationType:
          row['location'] ?? row['revelation_type_en'] ?? '',
      numberOfAyahs: row['number_of_ayahs'] ?? 0,
    );
  }
}
