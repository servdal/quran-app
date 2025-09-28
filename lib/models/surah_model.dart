import 'package:quran_app/models/ayah_model.dart'; // Import Ayah model Anda

class Surah {
  final int id;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final List<Ayah> ayahs;
  Surah({
    required this.id,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    var ayahsListFromJson = json['ayahs'] as List? ?? json['data'] as List? ?? [];
    List<Ayah> parsedAyahs = ayahsListFromJson.map((i) => Ayah.fromJson(i)).toList();

    return Surah(
      id: json['sura_id'] ?? json['id'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      revelationType: json['revelationType'],
      numberOfAyahs: json['numberOfAyahs'] ?? parsedAyahs.length,
      ayahs: parsedAyahs,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'sura_id': id,
      'name': name,
      'englishName': englishName,
      'englishNameTranslation': englishNameTranslation,
      'revelationType': revelationType,
      'numberOfAyahs': numberOfAyahs,
      'ayahs': ayahs.map((ayah) => ayah.toJson()).toList(),
    };
  }
}