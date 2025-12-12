class OccurrenceLocation {
  final int surahId;
  final int ayahNumber;

  OccurrenceLocation({required this.surahId, required this.ayahNumber});

  factory OccurrenceLocation.fromJson(Map<String, dynamic> json) {
    return OccurrenceLocation(
      surahId: json['surah_id'],
      ayahNumber: json['ayah_number'],
    );
  }
}

class GrammarPart {
  final int partNumber;
  final String grammar;
  final String lemma;
  final String verbForm;

  GrammarPart({
    required this.partNumber,
    required this.grammar,
    required this.lemma,
    required this.verbForm,
  });

  factory GrammarPart.fromJson(Map<String, dynamic> json) {
    return GrammarPart(
      partNumber: json['part_number'],
      grammar: json['grammar'],
      lemma: json['lemma'],
      verbForm: json['verb_form'],
    );
  }
}

class AnalysisDetail {
  final List<GrammarPart> parts;
  final int occurrences;
  final List<OccurrenceLocation> occurrenceLocations;

  AnalysisDetail({
    required this.parts,
    required this.occurrences,
    required this.occurrenceLocations,
  });

  factory AnalysisDetail.fromJson(Map<String, dynamic> json) {
    return AnalysisDetail(
      parts: List<GrammarPart>.from(
        (json['parts'] as List).map((p) => GrammarPart.fromJson(p)),
      ),
      occurrences: json['occurrences'],
      occurrenceLocations: List<OccurrenceLocation>.from(
        (json['occurrence_locations'] as List)
            .map((l) => OccurrenceLocation.fromJson(l)),
      ),
    );
  }
}

// ------------------- MODEL LAMA YANG DIPERBARUI -------------------

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

class Word {
  final int position;
  final String arabic;
  final String transliteration;
  final String translation;
  final int? analysisId;

  Word({
    required this.position,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    this.analysisId,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      position: json['position'],
      arabic: json['arabic'],
      transliteration: json['transliteration'] ?? '',
      translation: json['translation'] ?? '',
      analysisId: json['analysis_id'],
    );
  }
}

class Ayah {
  final int ayaId;
  final int ayaNumber;
  final String ayaText;
  final int suraId;
  final String suraName;
  final int pageNumber;
  final String translationAyaText;
  final String tafsirJalalayn;
  final SurahInfo? surah;
  final List<Word> words;
  final String transliteration;
  final String tajweedText;
  final int juzId;
  final bool sajda;

  String get audioKey =>
      '${suraId.toString().padLeft(3, '0')}${ayaNumber.toString().padLeft(3, '0')}';

  Ayah({
    required this.ayaId,
    required this.ayaNumber,
    required this.ayaText,
    required this.suraId,
    required this.suraName,
    required this.pageNumber,
    required this.translationAyaText,
    required this.tafsirJalalayn,
    this.surah,
    required this.words,
    required this.transliteration,
    required this.tajweedText,
    required this.juzId,
    required this.sajda,
  });

  // Masih dipakai kalau baca dari JSON assets lama
  factory Ayah.fromJson(Map<String, dynamic> json) {
    String suraNameValue = '';
    if (json['surah'] is Map<String, dynamic>) {
      suraNameValue = json['surah']['englishName'] ?? '';
    }
    return Ayah(
      ayaId: json['aya_id'],
      ayaNumber: json['aya_number'],
      ayaText: json['aya_text'],
      suraId: json['sura_id'],
      suraName: suraNameValue,
      pageNumber: json['page_number'],
      translationAyaText: json['translation_aya_text'] ?? '',
      tafsirJalalayn: json['tafsir_jalalayn'] ?? '',
      surah: json.containsKey('surah')
          ? SurahInfo.fromJson(json['surah'])
          : null,
      words: List<Word>.from(
        (json['words'] as List).map((w) => Word.fromJson(w)),
      ),
      transliteration: json['transliteration'] ?? '',
      tajweedText: json['tajweed_text'] ?? '',
      juzId: json['juz_id'],
      sajda: json['sajda'] ?? false,
    );
  }

  /// 🔥 Baru: construct dari baris SQLite (tabel merged_aya)
  ///
  /// Repository akan meng-*alias* kolom seperti ini:
  /// - aya_text         -> teks sesuai bahasa (ID/EN)
  /// - translation      -> terjemah sesuai bahasa (ID/EN)
  /// - sura_name        -> nama surah (latin)
  /// - transliteration  -> transliterasi (ID/EN)
  ///
  factory Ayah.fromDb(Map<String, dynamic> row) {
    return Ayah(
      ayaId: row['aya_id'] as int,
      ayaNumber: row['aya_number'] as int,
      ayaText: (row['aya_text'] ?? '') as String,
      suraId: row['sura_id'] as int,
      suraName: (row['sura_name'] ?? '') as String,
      pageNumber: (row['page_number'] ?? 0) as int,
      translationAyaText: (row['translation'] ?? '') as String,
      tafsirJalalayn: (row['tafsir_jalalayn'] ?? '') as String,
      // SurahInfo tidak diisi di sini; kalau perlu bisa dibuatkan dari meta surah.
      surah: null,
      // words dikosongkan, karena word-by-word diambil dari tabel master_edited
      words: const [],
      transliteration: (row['transliteration'] ?? '') as String,
      tajweedText: (row['tajweed_text'] ?? '') as String,
      juzId: (row['juz_id'] ?? 0) as int,
      sajda: (row['sajda'] == 1 || row['sajda'] == true),
    );
  }
}
