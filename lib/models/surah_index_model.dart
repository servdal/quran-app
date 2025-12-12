class SurahIndexInfo {
  final int suraId;
  final String name;          // Nama Latin sesuai bahasa
  final String arabicName;    // Arabic fixed
  final String translation;   // Terjemahan Latin sesuai bahasa
  final String revelationType;
  final int numberOfAyahs;

  SurahIndexInfo({
    required this.suraId,
    required this.name,
    required this.arabicName,
    required this.translation,
    required this.revelationType,
    required this.numberOfAyahs,
  });
}