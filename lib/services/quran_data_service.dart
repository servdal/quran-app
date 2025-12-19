import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_index_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/quran_repository.dart';
import '../models/ayah_model.dart';
import '../models/page_index_model.dart';
import '../models/surah_detail_data.dart';
import '../models/grammar_model.dart';
import 'package:quran_app/providers/settings_provider.dart';

class QuranDataService {
  final QuranRepository _repo = QuranRepository();

  List<PageIndexInfo>? _pageIndexCache;

  /// ===============================
  ///  SURAH INDEX (FINAL & STABIL)
  /// ===============================
  Future<List<SurahIndexInfo>> getAllSurahIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('selected_language') ?? 'id';
    final rows = await _repo.getSurahIndexRows();
    return rows.map((r) => SurahIndexInfo.fromDb(r, lang: lang)).toList();
  }


  /// ===============================
  ///  PAGE INDEX
  /// ===============================
  Future<List<PageIndexInfo>> getAllPageIndex() async {
    _pageIndexCache ??= await _repo.getAllPages();
    return _pageIndexCache!;
  }

  /// ===============================
  ///  AYAT per SURAH
  /// ===============================
  Future<List<Ayah>> getAyahsBySurahId(int surahId) async {
    final rows = await _repo.getAyahRowsBySurah(surahId);
    return rows.map(Ayah.fromDb).toList();
  }

  /// ===============================
  ///  AYAT per HALAMAN
  /// ===============================
  Future<List<Ayah>> getAyahsByPage(int page) async {
    final rows = await _repo.getAyahRowsByPage(page);
    return rows.map(Ayah.fromDb).toList();
  }

  /// ===============================
  ///  SEARCH
  /// ===============================
  Future<List<Map<String, dynamic>>> searchAyahs(String query) {
    return _repo.searchAyah(query);
  }

  /// ===============================
  ///  SURAH DETAIL
  /// ===============================
  Future<SurahDetailData> getSurahDetail(int surahId) async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('selected_language') ?? 'id';
    final meta = await _repo.getSurahMeta(surahId, lang: lang);

    if (meta.isEmpty) {
      throw Exception('Metadata surah ID $surahId tidak ditemukan');
    }

    final rows = await _repo.getAyahRowsBySurah(surahId);

    return SurahDetailData(
      surahName: meta['name'] ?? '',
      surahTranslation: meta['translation'] ?? '',
      revelationType: meta['revelation_type'] ?? '',
      ayahs: rows.map(Ayah.fromDb).toList(),
    );
  }

  /// ===============================
  ///  GRAMMAR
  /// ===============================
  Future<List<Grammar>> getAyahGrammar(int surahId, int ayahNumber) {
    return _repo.getGrammarByAyah(
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
  }
  
  
  /// ===============================
  ///  RANDOM AYAH (untuk Splash)
  /// ===============================
  Future<Ayah?> loadRandomAyahForSplash() async {
    final randomSurah = Random().nextInt(114) + 1;

    final rows = await _repo.getAyahRowsBySurah(randomSurah);
    if (rows.isEmpty) return null;

    final randomRow = rows[Random().nextInt(rows.length)];
    return Ayah.fromDb(randomRow);
  }
  Future<List<Grammar>> getAyahWords(
    int surahId,
    int ayahNumber,
  ) {
    return _repo.getGrammarByAyah(
      surahId: surahId,
      ayahNumber: ayahNumber,
    );
  }
}
final quranDataServiceProvider = Provider((ref) => QuranDataService());

final allSurahsProvider = FutureProvider<List<SurahIndexInfo>>((ref) {
  ref.watch(settingsProvider);   
  return ref.read(quranDataServiceProvider).getAllSurahIndex();
});

final allPagesProvider = FutureProvider<List<PageIndexInfo>>((ref) {
  ref.watch(settingsProvider); 
  return ref.read(quranDataServiceProvider).getAllPageIndex();
});

final surahAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, surahId) {
  ref.watch(settingsProvider);  
  return ref.read(quranDataServiceProvider).getAyahsBySurahId(surahId);
});

final surahDetailProvider = FutureProvider.family<SurahDetailData, int>((ref, surahId) {
  ref.watch(settingsProvider);
  return ref.read(quranDataServiceProvider).getSurahDetail(surahId);
});

final ayahWordsProvider = FutureProvider.family<List<Grammar>, ({int surahId, int ayahNumber})>((ref, p) {
  ref.watch(settingsProvider);
  return ref.read(quranDataServiceProvider).getAyahGrammar(p.surahId, p.ayahNumber);
});
final pageAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, page) {
  ref.watch(settingsProvider);
  return ref.read(quranDataServiceProvider).getAyahsByPage(page);
});

final randomAyahProvider = FutureProvider<Ayah?>((ref) {
  ref.watch(settingsProvider);  
  return ref.read(quranDataServiceProvider).loadRandomAyahForSplash();
});
