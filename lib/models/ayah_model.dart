import 'dart:convert';

class Ayah {
  final int id;
  final int number;
  final int surahId;
  final String surahName;
  final int juz;
  final int page;
  final String arabicText;
  final String tajweedText;
  final String translation;
  final String tafsir;
  final String transliteration;
  final bool isSajda;
  final List<String> arabicWords;

  const Ayah({
    required this.id,
    required this.number,
    required this.surahId,
    required this.surahName,
    required this.juz,
    required this.page,
    required this.arabicText,
    required this.tajweedText,
    required this.translation,
    required this.tafsir,
    required this.transliteration,
    required this.isSajda,
    required this.arabicWords,
  });

  factory Ayah.fromDb(Map<String, dynamic> row) {
    List<String> wordsList = [];
    try {
      final String wordsJson = row['arabic_words'] ?? '[]';
      wordsList = List<String>.from(jsonDecode(wordsJson));
    } catch (e) {
      // Jika JSON error, fallback kosong
      print("Error parsing words: $e");
      wordsList = [];
    }
    return Ayah(
      id: row['aya_id'] as int,
      number: row['aya_number'] as int,
      surahId: row['sura_id'] as int,
      surahName: (row['sura_name'] ?? '') as String,
      juz: (row['juz_id'] ?? 0) as int,
      page: (row['page_number'] ?? 0) as int,
      arabicText: (row['aya_text'] ?? '') as String,
      tajweedText: (row['tajweed_text'] ?? '') as String,
      translation: (row['translation'] ?? '') as String,
      tafsir: (row['tafsir'] ?? '') as String,
      transliteration: (row['transliteration'] ?? '') as String,
      isSajda: row['sajda'] == 1 || row['sajda'] == true,
      arabicWords: wordsList,
    );
  }

  String get audioKey =>
      '${surahId.toString().padLeft(3, '0')}_${number.toString().padLeft(3, '0')}';

  String get label => 'QS $surahId:$number';
}
