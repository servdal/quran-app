import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah_model.dart';
import '../repository/quran_repository.dart';
import '../models/ayah_model.dart';
import '../models/surah_index_model.dart';
import '../models/page_index_model.dart';
import '../models/surah_detail_data.dart';

class QuranDataService {
  final QuranRepository _repo = QuranRepository();

  List<SurahIndexInfo>? _surahIndexCache;
  List<PageIndexInfo>? _pageIndexCache;
  String? _cachedLang;

  Future<String> _getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_language') ?? 'id';
  }

  /// ===============================
  ///  SURAH INDEX (Dinamins Bahasa)
  /// ===============================
  Future<List<SurahIndexInfo>> getAllSurahIndex() async {
    final lang = await _getLanguage();
    if (_cachedLang != lang) {
      _surahIndexCache = null;
      _cachedLang = lang;
    }
    if (_surahIndexCache != null) return _surahIndexCache!;

    final rows = await _repo.getSurahListRaw(lang: lang);

    _surahIndexCache = rows.map((row) {
      return SurahIndexInfo(
        suraId: row['sura_id'],
        name: row['latin_name'], // Dinamis
        arabicName: row['arabic_name'],
        translation: row['translation'],
        revelationType: row['revelation_type'],
        numberOfAyahs: row['ayah_count'],
      );
    }).toList();

    return _surahIndexCache!;
  }
  // Provider-friendly wrapper
  Future<List<SurahIndexInfo>> getAllSurahIndexProvider(WidgetRef ref) {
    return getAllSurahIndex();
  }
  
  /// ===============================
  ///  PAGE INDEX
  /// ===============================
  Future<List<PageIndexInfo>> getAllPageIndex() async {
    if (_pageIndexCache != null) return _pageIndexCache!;

    final rows = await _repo.getAllPages();
    _pageIndexCache = rows;

    return _pageIndexCache!;
  }

  /// ===============================
  ///  AYAT per SURAH (bahasa fleksibel)
  /// ===============================
  Future<List<Ayah>> getAyahsBySurahId(int surahId, WidgetRef ref) async {
    final lang = await _getLanguage();
    final rows = await _repo.getAyahBySurah(surahId, lang);
    return rows.map((r) => Ayah.fromDb(r)).toList();
  }


  /// ===============================
  ///  AYAT per HALAMAN
  /// ===============================
  Future<List<Ayah>> getAyahsByPage(int page) async {
    final rows = await _repo.getAyahByPage(page);
    return rows.map((r) => Ayah.fromDb(r)).toList();
  }

  /// ===============================
  ///  SEARCH (Dinamis Bahasa)
  /// ===============================
  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    return await _repo.searchAyah(query);
  }

  /// ===============================
  ///  RANDOM AYAH
  /// ===============================
  Future<Ayah?> loadRandomAyahForSplash() async {
    final randomSurah = Random().nextInt(114) + 1;

    final rows = await _repo.getAyahRowsBySurah(randomSurah);
    if (rows.isEmpty) return null;

    return Ayah.fromDb(rows[Random().nextInt(rows.length)]);
  }

  /// ===============================
  ///  WORD BY WORD
  /// ===============================
  Future<List<Map<String, dynamic>>> getWordByAyah(int surahId, int ayahNum) {
    return _repo.getWordByAyah(surahId, ayahNum);
  }

  /// ===============================
  ///  SURAH DETAIL (metadata + ayahs)
  /// ===============================
  Future<SurahDetailData> getSurahDetail(int surahId) async {
    final lang = await _getLanguage();

    // 1. Ambil metadata surah
    final surahMeta = await _repo.getSurahMeta(surahId, lang: lang);

    // 2. Ambil ayat-ayat
    final rows = await _repo.getAyahRowsBySurah(surahId);
    final ayahs = rows.map((r) => Ayah.fromDb(r)).toList();

    return SurahDetailData(
      surahName: surahMeta['name'] ?? '',
      surahTranslation: surahMeta['translation'] ?? '',
      revelationType: surahMeta['revelation_type'] ?? '',
      ayahs: ayahs,
    );
  }
  Future<Surah> getSurahDetailById(int surahId, WidgetRef ref) async {
    final lang = await _getLanguage();
    final rows = await _repo.getAyahBySurah(surahId, lang);

    if (rows.isEmpty) {
      throw Exception("Surah tidak ditemukan di database");
    }

    return Surah(
      id: rows.first['sura_id'],
      name: rows.first['latin_name'],
      englishName: rows.first['latin_name'], // fallback
      englishNameTranslation: rows.first['translation'],
      revelationType: rows.first['revelation_type'],
      ayahs: rows.map((r) => Ayah.fromDb(r)).toList(),
    );
  }
}

final quranDataServiceProvider = Provider((ref) => QuranDataService());

final allSurahsProvider = FutureProvider((ref) {
  return ref.read(quranDataServiceProvider).getAllSurahIndexProvider(ref);
});

final allPagesProvider = FutureProvider((ref) {
  return ref.read(quranDataServiceProvider).getAllPageIndex();
});

final pageAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, page) {
  return ref.read(quranDataServiceProvider).getAyahsByPage(page);
});

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, surahId) {
  return ref.read(quranDataServiceProvider).getAyahsBySurahId(surahId, ref);
});

final surahDetailProvider =
    FutureProvider.family<SurahDetailData, int>((ref, surahId) {
  return ref.watch(quranDataServiceProvider).getSurahDetail(surahId);
});

