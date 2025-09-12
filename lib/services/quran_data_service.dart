import 'dart:convert';
import 'dart:math' show Random;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/models/ayah_model.dart';

final audioPathsProvider = FutureProvider<Map<int, String>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/audio_paths.json');
  final jsonMap = json.decode(jsonString);
  final List<dynamic> audioList = jsonMap['audio_mapping'];
  
  // Mengubah daftar menjadi peta untuk akses instan: { 1: "path/1.mp3", 2: "path/2.mp3", ... }
  final Map<int, String> audioPaths = {
    for (var item in audioList)
      item['aya_id']: item['path_audio']
  };
  
  return audioPaths;
});

class QuranDataService {
  List<Surah> _allSurahs = [];
  bool _isLoaded = false;

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
      print('Error loading random ayah for splash: $e');
      return null;
    }
  }

  Future<void> loadAllSurahData() async {
    if (_isLoaded) return;

    List<Surah> tempSurahs = [];
    for (int i = 1; i <= 114; i++) {
      try {
        String jsonString = await rootBundle.loadString('assets/surah/$i.json');
        Map<String, dynamic> jsonMap = json.decode(jsonString);
        tempSurahs.add(Surah.fromJson(jsonMap));
      } catch (e) {
        print('Error loading surah $i: $e');
      }
    }
    _allSurahs = tempSurahs;
    _isLoaded = true;
    print('All surah data loaded successfully.');
  }

  // #### FUNGSI BARU YANG DITAMBAHKAN ####
  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    if (!_isLoaded) {
      await loadAllSurahData();
    }
    
    List<Map<String, dynamic>> results = [];
    if (query.isEmpty) return results;

    String lowerCaseQuery = query.toLowerCase();

    for (var surah in _allSurahs) {
      // Cek apakah nama surah cocok
      if (surah.englishName.toLowerCase().contains(lowerCaseQuery) || surah.name.contains(lowerCaseQuery)) {
          // Jika nama surah cocok, tambahkan hasil yang mengarah ke surah tersebut
          results.add({
            'surahId': surah.suraId,
            'ayahNumber': 1, // Arahkan ke ayat pertama
            'surahName': surah.englishName,
            'ayahTextPreview': 'Membuka Surah ${surah.englishName}', 
          });
      }

      // Cek setiap ayat di dalam surah
      for (var ayah in surah.ayahs) {
        if (ayah.translationAyaText.toLowerCase().contains(lowerCaseQuery)) {
          results.add({
            'surahId': ayah.suraId,
            'ayahNumber': ayah.ayaNumber,
            'surahName': surah.englishName,
            'ayahTextPreview': ayah.translationAyaText,
          });
        }
      }
    }
    return results;
  }
  // #########################################

  List<Surah> getAllSurahs() {
    return _allSurahs;
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
}

final quranDataServiceProvider = Provider((ref) => QuranDataService());

final allSurahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = ref.read(quranDataServiceProvider);
  await service.loadAllSurahData();
  return service.getAllSurahs();
});

final pageAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, pageNumber) async {
  final service = ref.read(quranDataServiceProvider);
  return service.getAyahsByPage(pageNumber);
});

