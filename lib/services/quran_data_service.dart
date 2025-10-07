import 'dart:convert';
import 'dart:math' show Random;
import 'package:flutter/services.dart' show rootBundle;
import 'database_native.dart' if (dart.library.html) 'database_web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/page_index_model.dart';
import 'package:quran_app/models/surah_index_model.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/services/database.dart';


class QuranDataService {
  // Cache untuk data pencarian agar tidak dimuat berulang kali
  List<Surah>? _searchableSurahs;
  List<SurahIndexInfo>? _surahIndexCache;
  List<PageIndexInfo>? _halamanIndexCache;

  Future<List<SurahIndexInfo>> getAllSurahIndex() async {
    if (_surahIndexCache != null) return _surahIndexCache!;
    final String response = await rootBundle.loadString('assets/index_surah.json');
    final data = json.decode(response) as List;
    _surahIndexCache = data.map((json) => SurahIndexInfo.fromJson(json)).toList();
    return _surahIndexCache!;
  }

  Future<List<PageIndexInfo>> getAllPageIndex() async {
    if (_halamanIndexCache != null) return _halamanIndexCache!;
    final String response = await rootBundle.loadString('assets/index_halaman.json');
    final data = json.decode(response) as List;
    _halamanIndexCache = data.map((json) => PageIndexInfo.fromJson(json)).toList();
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

  Future<void> loadAllDataForSearch() async {
    if (_searchableSurahs != null) return; // Hanya muat sekali
    List<Surah> allSurahs = [];
    for (int i = 1; i <= 114; i++) {
      final surah = await getSurahDetailById(i);
      allSurahs.add(surah);
    }
    _searchableSurahs = allSurahs;
    print("All surah data loaded for search.");
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
      throw Exception("Error loading page $pageNumber: $e");
    }
  }
  Future<List<Map<String, dynamic>>> getRawAyahsByPage(int pageNumber) async {
    try {
      String jsonString = await rootBundle.loadString('assets/halaman/$pageNumber.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      return (jsonMap['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Error loading page $pageNumber: $e");
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
      throw Exception("Error loading random ayah: $e");
    }
  }
  Future<List<Map<String, dynamic>>> getSurahNameById(int pageNumber) async {
    try {
      String jsonString = await rootBundle.loadString('assets/halaman/$pageNumber.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      return (jsonMap['data'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Error loading page $pageNumber: $e");
    }
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
  final quranService = ref.watch(quranDataServiceProvider);
  
  // 1. Ambil data mentah ayat per halaman
  final rawAyahsData = await quranService.getRawAyahsByPage(pageNumber);
  
  // 2. Ambil indeks semua surah (ini akan di-cache oleh provider)
  final allSurahIndex = await ref.watch(allSurahsProvider.future);
  
  // 3. Buat peta (Map) untuk pencarian nama surah yang efisien
  final surahNameMap = {for (var surah in allSurahIndex) surah.suraId: surah.englishName};

  // 4. Proses setiap ayat, "suntikkan" nama surah, lalu buat objek Ayah
  return rawAyahsData.map((ayahJson) {
    final int surahId = ayahJson['sura_id'] ?? 0;
    final String surahName = surahNameMap[surahId] ?? 'Unknown';

    // Buat salinan data JSON dan tambahkan objek 'surah' yang berisi nama
    final enrichedJson = Map<String, dynamic>.from(ayahJson);
    enrichedJson['surah'] = {'englishName': surahName};

    return Ayah.fromJson(enrichedJson);
  }).toList();
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
    throw Exception("Gagal memuat audio_paths.json: $e");
  }
});
final databaseProvider = FutureProvider<AppDatabase>((ref) async { 
  final executor = await constructDb();  
  return AppDatabase(executor);
});

final ayahWordsProvider = FutureProvider.family<List<Grammar>, ({int surahId, int ayahNumber})>(
  (ref, ids) async { 
    final db = await ref.watch(databaseProvider.future); 
    return db.getWordsForAyah(ids.surahId, ids.ayahNumber);
  }
);