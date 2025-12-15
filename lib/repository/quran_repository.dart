import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../../models/page_index_model.dart';
import '../models/grammar_model.dart';
class QuranRepository {
  Future<String> _getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_language') ?? 'id';
  }

  Future<Database> get _db async => DBHelper.database;

  Future<List<Map<String, dynamic>>> getSurahIndexRows() async {
    final db = await _db;

    return db.rawQuery('''
      SELECT
        sura_id,

        MAX(sura_name) AS sura_name,
        MAX(sura_name_en) AS sura_name_en,
        MAX(sura_name_arabic) AS sura_name_arabic,

        MAX(sura_name_translation) AS sura_name_translation,
        MAX(sura_name_translation_en) AS sura_name_translation_en,

        MAX(location) AS location,
        MAX(revelation_type_en) AS revelation_type_en,

        COUNT(*) AS number_of_ayahs
      FROM merged_aya
      GROUP BY sura_id
      ORDER BY sura_id
    ''');
  }


  /// Daftar halaman (page index)
  Future<List<PageIndexInfo>> getAllPages() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT DISTINCT page_number,MIN(juz_id) AS juz_id, MIN(sura_id) AS first_sura_id
      FROM merged_aya
      GROUP BY page_number
      ORDER BY page_number
    ''');

    return rows.map((r) {
      return PageIndexInfo(
        juzId: r['juz_id'] as int,
        pageNumber: r['page_number'] as int,
        surahId: r['first_sura_id'] as int,
      );
    }).toList();
  }

  /// Ayat per surah
  Future<List<Map<String, dynamic>>> getAyahRowsBySurah(int surahId) async {
    final db = await _db;
    final lang = await _getLanguage();

    final textCol = lang == 'id'
        ? 'aya_text_kemenag'
        : 'aya_text';
    final translationCol = lang == 'id'
        ? 'translation_aya_text_kemenag'
        : 'translation_aya_text';
    final translitCol = 'COALESCE(transliteration_kemenag, transliteration)';

    return await db.rawQuery('''
      SELECT
        aya_id,
        aya_number,
        sura_id,
        page_number,
        juz_id,
        $textCol AS aya_text,
        $translationCol AS translation_aya_text,
        $translitCol AS transliteration,
        tajweed_text,
        tafsir_jalalayn,
        sura_name
      FROM merged_aya
      WHERE sura_id = ?
      ORDER BY aya_number
    ''', [surahId]);
  }

  /// Ayat per halaman
  Future<List<Map<String, dynamic>>> getAyahRowsByPage(int pageNumber) async {
    final db = await _db;
    final lang = await _getLanguage();

    final textCol = lang == 'id'
        ? 'aya_text_kemenag'
        : 'aya_text';
    final translationCol = lang == 'id'
        ? 'translation_aya_text_kemenag'
        : 'translation_aya_text';
    final translitCol = 'COALESCE(transliteration_kemenag, transliteration)';

    return await db.rawQuery('''
      SELECT
        aya_id,
        aya_number,
        sura_id,
        page_number,
        juz_id,
        $textCol AS aya_text,
        $translationCol AS translation_aya_text,
        $translitCol AS transliteration,
        tajweed_text,
        tafsir_jalalayn,
        sura_name
      FROM merged_aya
      WHERE page_number = ?
     ORDER BY sura_id ASC, aya_number ASC
    ''', [pageNumber]);
  }

  /// Search ayat (sederhana, bisa di-upgrade ke FTS)
  Future<List<Map<String, dynamic>>> searchAyah(String query) async {
    final db = await _db;
    final lang = await _getLanguage();
    final translationCol = lang == 'id'
        ? 'translation_aya_text_kemenag'
        : 'translation_aya_text';

    return await db.rawQuery('''
      SELECT
        aya_id,
        aya_number,
        sura_id,
        sura_name,
        $translationCol AS translation
      FROM merged_aya
      WHERE $translationCol LIKE ?
      ORDER BY sura_id ASC, aya_number ASC
      LIMIT 100
    ''', ['%$query%']);
  }

  /// Word-by-word dari master_edited
  Future<List<Map<String, dynamic>>> getWordByAyah(int surahId, int ayahNumber) async {
    final db = await _db;
    final lang = await _getLanguage();
    final meaningCol = lang == 'id' ? 'MeaningId' : 'MeaningEn';

    return await db.rawQuery('''
      SELECT
        WordNo,
        WordAr,
        $meaningCol AS meaning,
        GrammarFormDescID
      FROM master_edited
      WHERE ChapterNo = ? AND VerseNo = ?
      ORDER BY ChapterNo ASC, VerseNo ASC, WordNo ASC
    ''', [surahId, ayahNumber]);
  }

  Future<Map<String, dynamic>> getSurahMeta(
    int surahId, {
    required String lang,
  }) async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT 
        sura_name,
        sura_name_arabic,
        sura_name_translation,
        location,
        revelation_type_en
      FROM merged_aya
      WHERE sura_id = ?
      LIMIT 1
    ''', [surahId]);

    if (rows.isEmpty) return {};

    final r = rows.first;

    return {
      'name': r['sura_name'] ?? '',
      'arabic_name': r['sura_name_arabic'] ?? '',
      'translation': r['sura_name_translation'] ?? '',
      'revelation_type':
          lang == 'id' ? r['location'] : r['revelation_type_en'],
    };
  }


  /// 🔹 Grammar per ayat (master_edited)
  Future<List<Grammar>> getGrammarByAyah({
    required int surahId,
    required int ayahNumber,
  }) async {
    final db = await _db;

    final rows = await db.rawQuery('''
      SELECT
        id,
        RootAr,
        RootCode,
        RootEn,
        RootWordId,
        ChapterNo,
        VerseNo,
        MeaningEn,
        MeaningId,
        WordAr,
        WordNo,
        GrammarFormDesc,
        GrammarFormDescID
      FROM master_edited
      WHERE ChapterNo = ?
        AND VerseNo = ?
      ORDER BY WordNo
    ''', [surahId, ayahNumber]);

    return rows.map(Grammar.fromDb).toList();
  }  
}
