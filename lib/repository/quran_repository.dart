import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../database/db_helper.dart';
import '../../models/page_index_model.dart';
import '../../models/ayah_model.dart';

class QuranRepository {
  Future<String> _getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_language') ?? 'id';
  }

  Future<Database> get _db async => DBHelper.database;

  /// Daftar surah (untuk index)
  Future<List<Map<String, dynamic>>> getSurahListRaw({required String lang}) async {
    final db = await _db;

    final latinNameCol = lang == 'id'
        ? 'sura_name'
        : 'sura_name_en';

    final translationCol = lang == 'id'
        ? 'sura_name_translation'
        : 'sura_name_translation_en';

    final revelationCol = lang == 'id'
        ? 'location'
        : 'revelation_type_en';

    return await db.rawQuery('''
      SELECT DISTINCT
        sura_id,
        $latinNameCol AS name,
        sura_name_arabic AS arabic_name,
        $translationCol AS translation,
        $revelationCol AS revelation_type
      FROM merged_aya
      ORDER BY sura_id
    ''');
  }


  /// Daftar halaman (page index)
  Future<List<PageIndexInfo>> getAllPages() async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT DISTINCT page_number, MIN(sura_id) AS first_sura_id
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
        $translationCol AS translation,
        $translitCol AS transliteration,
        tajweed_text,
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
        $translationCol AS translation,
        $translitCol AS transliteration,
        tajweed_text,
        sura_name
      FROM merged_aya
      WHERE page_number = ?
      ORDER BY sura_id, aya_number
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
      ORDER BY sura_id, aya_number
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
      ORDER BY WordNo
    ''', [surahId, ayahNumber]);
  }

  Future<Map<String, dynamic>> getSurahMeta(int surahId, {required String lang}) async {
    final db = await _db;

    final latinCol = lang == 'id' ? 'sura_name' : 'sura_name_en';
    final translationCol = lang == 'id' ? 'sura_name_translation' : 'sura_name_translation_en';
    final revealCol = lang == 'id' ? 'location' : 'revelation_type_en';

    final rows = await db.rawQuery('''
      SELECT 
        $latinCol AS name,
        $translationCol AS translation,
        $revealCol AS revelation_type
      FROM merged_aya 
      WHERE sura_id = ?
      LIMIT 1
    ''', [surahId]);

    return rows.isNotEmpty ? rows.first : {};
  }
  // Ambil arabic_words (JSON) dari merged_aya
  Future<List<String>> getArabicWords(
    int surahId,
    int ayahNumber,
  ) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT arabic_words
      FROM merged_aya
      WHERE sura_id = ? AND aya_number = ?
      LIMIT 1
    ''', [surahId, ayahNumber]);

    if (result.isEmpty || result.first['arabic_words'] == null) {
      return [];
    }

    final raw = result.first['arabic_words'] as String;
    final List<dynamic> parsed = jsonDecode(raw);

    return parsed
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  Future<List<Grammar>> getGrammarByAyah({
    required int surahId,
    required int ayahNumber,
  }) async {
    final db = await _db;

    final result = await db.rawQuery('''
      SELECT *
      FROM master_edited
      WHERE ChapterNo = ?
        AND VerseNo = ?
      ORDER BY WordNo
    ''', [surahId, ayahNumber]);

    return result.map((e) => Grammar.fromDb(e)).toList();
  }
  Future<Map<String, dynamic>?> getAudioForAyah(
    int surahId,
    int ayahNumber,
  ) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT *
      FROM audio_index
      WHERE sura_id = ?
        AND ayah_start <= ?
        AND ayah_end >= ?
      LIMIT 1
    ''', [surahId, ayahNumber, ayahNumber]);

    if (result.isEmpty) return null;
    return result.first;
  }

  
}
