// lib/models/surah_meta.dart
class SurahMeta {
  final String name;
  final String translation;
  final String revelationType;

  SurahMeta({
    required this.name,
    required this.translation,
    required this.revelationType,
  });

  factory SurahMeta.fromDb(Map<String, dynamic> row) {
    return SurahMeta(
      name: row['name'] ?? '',
      translation: row['translation'] ?? '',
      revelationType: row['revelation_type'] ?? '',
    );
  }
}
