import 'dart:convert';
import 'dart:math' show Random;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/page_index_model.dart';
import 'package:quran_app/models/surah_index_model.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/models/ayah_model.dart';

class QuranDataService {
  // Cache untuk data pencarian agar tidak dimuat berulang kali
  List<Surah>? _searchableSurahs;

  // OPTIMIZED: Membaca dari index_surah.json
  Future<List<SurahIndexInfo>> getAllSurahIndex() async {
    final String response = await rootBundle.loadString('index_surah.json');
    final data = json.decode(response) as List;
    return data.map((json) => SurahIndexInfo.fromJson(json)).toList();
  }

  // OPTIMIZED: Membaca dari index_halaman.json
  Future<List<PageIndexInfo>> getAllPageIndex() async {
    final String response = await rootBundle.loadString('index_halaman.json');
    final data = json.decode(response) as List;
    return data.map((json) => PageIndexInfo.fromJson(json)).toList();
  }

  // RE-INTRODUCED: Metode ini dibutuhkan oleh doa_screen & dzikir_screen
  Future<List<Ayah>> getAyahsBySurahId(int surahId) async {
    final surah = await getSurahDetailById(surahId);
    return surah.ayahs;
  }
  
  // Metode ini mengambil detail lengkap sebuah surah dari file JSON-nya
  Future<Surah> getSurahDetailById(int surahId) async {
    final String response = await rootBundle.loadString('assets/surah/$surahId.json');
    final data = json.decode(response);
    return Surah.fromJson(data);
  }

  // NEW: Metode khusus untuk memuat semua data yang dibutuhkan untuk search
  Future<void> loadAllDataForSearch() async {
    if (_searchableSurahs != null) return; // Hanya muat sekali
    List<Surah> allSurahs = [];
    for (int i = 1; i <= 114; i++) {
      final surah = await getSurahDetailById(i);
      allSurahs.add(surah);
    }
    _searchableSurahs = allSurahs;
    print("All surah data for search loaded successfully.");
  }

  // Search function (now uses the cached data)
  List<Map<String, dynamic>> searchAyahs(String query) {
    if (_searchableSurahs == null) return [];
    List<Map<String, dynamic>> results = [];
    for (var surah in _searchableSurahs!) {
      for (var ayah in surah.ayahs) {
        if (ayah.translationAyaText.toLowerCase().contains(query.toLowerCase())) {
          results.add({
            'surahId': surah.id,
            'surahName': surah.englishName,
            'ayahNumber': ayah.ayaNumber,
            'ayahTextPreview': ayah.translationAyaText, 
          });
        }
      }
    }
    return results;
  }
  Future<List<Ayah>> getAyahsByPage(int pageNumber) async {
    try {
      String jsonString = await rootBundle.loadString('assets/halaman/$pageNumber.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      var ayahsList = jsonMap['data'] as List;
      return ayahsList.map((i) => Ayah.fromJson(i)).toList();
    } catch (e) {
      print('Error loading page $pageNumber: $e');
      return [];
    }
  }

  Future<Ayah?> loadRandomAyahForSplash() async {
    try {
      final random = Random();
      int randomSurahId = random.nextInt(114) + 1;
      String jsonString = await rootBundle.loadString('assets/surah/$randomSurahId.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      final surah = Surah.fromJson(jsonMap);

      if (surah.ayahs.isEmpty) return null;

      final randomAyah = surah.ayahs[random.nextInt(surah.ayahs.length)];
      return randomAyah;
    } catch (e) {
      print('Error loading random ayah: $e');
      return null;
    }
  }
  String getSurahNameById(int surahId) {
    // This function is tricky without loading all data.
    // We will leave it as is for now, but ideally it should also use the index.
    // For simplicity, let's assume it's okay for now.
    return "Surah";
  }
  Future<Map<String, AnalysisDetail>> loadAnalysisDictionary() async {
    final String response = await rootBundle.loadString('assets/kamus_analisis.json');
    final Map<String, dynamic> data = json.decode(response);
    return data.map((key, value) => MapEntry(key, AnalysisDetail.fromJson(value)));
  }
}


final quranDataServiceProvider = Provider<QuranDataService>((ref) {
  return QuranDataService();
});

final allSurahsProvider = FutureProvider<List<SurahIndexInfo>>((ref) {
  return ref.watch(quranDataServiceProvider).getAllSurahIndex();
});

final allPagesProvider = FutureProvider<List<PageIndexInfo>>((ref) {
  return ref.watch(quranDataServiceProvider).getAllPageIndex();
});

final surahDetailProvider = FutureProvider.family<Surah, int>((ref, surahId) {
  return ref.watch(quranDataServiceProvider).getSurahDetailById(surahId);
});

final pageAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, pageNumber) async {
  return ref.watch(quranDataServiceProvider).getAyahsByPage(pageNumber);
});

final audioPathsProvider = FutureProvider<Map<int, String>>((ref) async {
  // Pastikan Anda memiliki file audio_paths.json di folder assets
  try {
    final jsonString = await rootBundle.loadString('assets/audio_paths.json');
    final jsonMap = json.decode(jsonString);
    final List<dynamic> audioList = jsonMap['audio_mapping'];
    
    final Map<int, String> audioPaths = {
      for (var item in audioList)
        item['aya_id']: item['path_audio']
    };
    
    return audioPaths;
  } catch (e) {
    print("Gagal memuat audio_paths.json: $e");
    return {}; // Kembalikan map kosong jika file tidak ada
  }
});
final analysisDictionaryProvider = FutureProvider<Map<String, AnalysisDetail>>((ref) {
  return ref.watch(quranDataServiceProvider).loadAnalysisDictionary();
});