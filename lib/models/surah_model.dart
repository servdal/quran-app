// lib/models/surah_model.dart
import 'package:quran_app/models/ayah_model.dart'; // Import Ayah model Anda

class Surah {
  final int suraId;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final List<Ayah> ayahs; // Daftar ayat dalam surah ini

  Surah({
    required this.suraId,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    var ayahsList = json['data'] as List;
    List<Ayah> parsedAyahs = ayahsList.map((i) => Ayah.fromJson(i)).toList();

    return Surah(
      suraId: json['sura_id'],
      name: json['name'],
      englishName: json['englishName'],
      englishNameTranslation: json['englishNameTranslation'],
      revelationType: json['revelationType'],
      ayahs: parsedAyahs,
    );
  }
}