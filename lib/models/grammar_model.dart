// lib/models/grammar_model.dart

/// Jenis kata Nahwu
enum GrammarType {
  fiil,
  isim,
  harf,
  unknown,
}

class Grammar {
  final int id;

  /// Root
  final String rootAr;
  final String rootCode;
  final String rootEn;
  final int rootWordId;

  /// Lokasi ayat
  final int surahId; // ChapterNo
  final int ayahNumber; // VerseNo

  /// Kata
  final String wordAr;
  final int wordNumber;

  /// Arti
  final String meaningEn;
  final String meaningId;

  /// Deskripsi Nahwu
  final String grammarDescEn;
  final String grammarDescId;

  const Grammar({
    required this.id,
    required this.rootAr,
    required this.rootCode,
    required this.rootEn,
    required this.rootWordId,
    required this.surahId,
    required this.ayahNumber,
    required this.wordAr,
    required this.wordNumber,
    required this.meaningEn,
    required this.meaningId,
    required this.grammarDescEn,
    required this.grammarDescId,
  });

  /// =========================
  /// Factory dari SQLite
  /// =========================
  factory Grammar.fromDb(Map<String, dynamic> row) {
    return Grammar(
      id: row['id'] as int,
      rootAr: (row['RootAr'] ?? '') as String,
      rootCode: (row['RootCode'] ?? '') as String,
      rootEn: (row['RootEn'] ?? '') as String,
      rootWordId: (row['RootWordId'] ?? 0) as int,
      surahId: row['ChapterNo'] as int,
      ayahNumber: row['VerseNo'] as int,
      wordAr: (row['WordAr'] ?? '') as String,
      wordNumber: (row['WordNo'] ?? 0) as int,
      meaningEn: (row['MeaningEn'] ?? '') as String,
      meaningId: (row['MeaningId'] ?? '') as String,
      grammarDescEn: (row['GrammarFormDesc'] ?? '') as String,
      grammarDescId: (row['GrammarFormDescID'] ?? '') as String,
    );
  }

  /// =========================
  /// Helper untuk UI
  /// =========================

  GrammarType get type {
    final t = grammarDescEn.toLowerCase();
    if (t.contains('verb')) return GrammarType.fiil;
    if (t.contains('noun')) return GrammarType.isim;
    if (t.contains('particle') || t.contains('preposition')) {
      return GrammarType.harf;
    }
    return GrammarType.unknown;
  }

  String get typeLabel {
    switch (type) {
      case GrammarType.fiil:
        return 'Fi‘il';
      case GrammarType.isim:
        return 'Isim';
      case GrammarType.harf:
        return 'Harf';
      default:
        return '—';
    }
  }

  /// Warna badge
  int get typeColor {
    switch (type) {
      case GrammarType.fiil:
        return 0xFFE53935; // merah
      case GrammarType.isim:
        return 0xFF1E88E5; // biru
      case GrammarType.harf:
        return 0xFF43A047; // hijau
      default:
        return 0xFF757575; // abu
    }
  }

  /// Arti sesuai bahasa
  String meaningByLang(String lang) {
    return lang == 'id' ? meaningId : meaningEn;
  }

  /// Deskripsi nahwu sesuai bahasa
  String grammarDescByLang(String lang) {
    return lang == 'id' ? grammarDescId : grammarDescEn;
  }
}
