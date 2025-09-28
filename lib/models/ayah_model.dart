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
  final List<Word> words;

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
    required this.words
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    var wordList = <Word>[];
    if (json['words'] != null) {
      wordList = List<Word>.from(
        (json['words'] as List).map((wordJson) => Word.fromJson(wordJson)),
      );
    }
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
      words: wordList,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'aya_id': ayaId,
      'juz_id': juzId,
      'aya_number': ayaNumber,
      'aya_text': ayaText,
      'sura_id': suraId,
      'translation_aya_text': translationAyaText,
      'tafsir_jalalayn': tafsirJalalayn,
      'sajda': sajda,
      'transliteration': transliteration,
      'page_number': pageNumber,
      'tajweed_text': tajweedText,
      'words': words.map((word) => word.toJson()).toList(),
    };
  }
}

class Word {
  final int position;
  final String arabic;
  final String transliteration;
  final String translation;

  Word({
    required this.position,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      position: json['position'] ?? 0,
      arabic: json['arabic'] ?? '',
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'arabic': arabic,
      'transliteration': transliteration,
      'translation': translation,
    };
  }
}