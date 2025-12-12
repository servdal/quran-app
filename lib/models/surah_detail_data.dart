import '../models/ayah_model.dart';

class SurahDetailData {
  final String surahName;
  final String surahTranslation;
  final String revelationType;
  final List<Ayah> ayahs;

  SurahDetailData({
    required this.surahName,
    required this.surahTranslation,
    required this.revelationType,
    required this.ayahs,
  });
}
