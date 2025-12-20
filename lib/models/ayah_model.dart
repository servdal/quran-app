class Ayah {
  final int id;
  final int number;

  final int surahId;
  final String surahName;
  final int juz;
  final int page;

  /// Teks utama Arab (ID: kemenag, EN: uthmani)
  final String arabicText;

  /// Tajweed markup (untuk EN / advanced mode)
  final String tajweedText;

  /// Terjemahan (ID / EN)
  final String translation;

  /// Tafsir Jalalayn
  final String tafsir;

  /// Transliterasi (opsional)
  final String transliteration;

  /// Ayat sajdah
  final bool isSajda;

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
  });

  /// Factory utama dari SQLite row
  factory Ayah.fromDb(Map<String, dynamic> row) {
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
      tafsir: (row['tafsir_jalalayn'] ?? '') as String,

      transliteration: (row['transliteration'] ?? '') as String,

      isSajda: row['sajda'] == 1 || row['sajda'] == true,
    );
  }

  /// Key audio berbasis surah + ayat
  String get audioKey =>
      '${surahId.toString().padLeft(3, '0')}_${number.toString().padLeft(3, '0')}';

  /// Label QS
  String get label => 'QS $surahId:$number';
}
