// lib/services/quran_data_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/models/ayah_model.dart';

class QuranDataService {
  List<Surah> _allSurahs = [];
  bool _isLoaded = false;

  // Memuat semua data surah dari aset
  Future<void> loadAllSurahData() async {
    if (_isLoaded) return; // Muat hanya sekali

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
    print('All surah data loaded successfully for splash screen.');
  }

  // Mendapatkan ayat acak
  Ayah? getRandomAyah() {
    if (!_isLoaded || _allSurahs.isEmpty) {
      print('Quran data not loaded yet.');
      return null;
    }

    final random = Random();
    // Pilih surah acak
    final randomSurah = _allSurahs[random.nextInt(_allSurahs.length)];
    // Pilih ayat acak dari surah tersebut
    final randomAyah = randomSurah.ayahs[random.nextInt(randomSurah.ayahs.length)];

    return randomAyah;
  }
  
  // Fungsi untuk mendapatkan semua surah (misalnya untuk list surah)
  List<Surah> getAllSurahs() {
    return _allSurahs;
  }

  // Fungsi untuk mendapatkan detail surah berdasarkan ID
  Future<Surah?> getSurahById(int surahId) async {
    if (!_isLoaded) {
      await loadAllSurahData();
    }
    try {
      return _allSurahs.firstWhere((s) => s.suraId == surahId);
    } catch (e) {
      print('Surah with ID $surahId not found.');
      return null;
    }
  }

    // Fungsi untuk mendapatkan ayat berdasarkan halaman (dari folder 'halaman')
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

  // Fungsi pencarian (akan diimplementasikan lebih lanjut di provider)
  Future<List<Map<String, dynamic>>> searchAyahs(String query) async {
    if (!_isLoaded) {
      await loadAllSurahData();
    }
    List<Map<String, dynamic>> results = [];
    String lowerCaseQuery = query.toLowerCase();

    for (var surah in _allSurahs) {
      for (var ayah in surah.ayahs) {
        if (ayah.translationAyaText.toLowerCase().contains(lowerCaseQuery) ||
            (ayah.surah?.englishName.toLowerCase().contains(lowerCaseQuery) ?? false) ||
            (ayah.surah?.name.toLowerCase().contains(lowerCaseQuery) ?? false)) {
          results.add({
            'surahId': ayah.suraId,
            'ayahNumber': ayah.ayaNumber,
            'surahName': ayah.surah?.englishName ?? surah.englishName,
            'ayahTextPreview': ayah.translationAyaText, // Tampilkan preview terjemahan
          });
          // Batasi jumlah hasil untuk performa jika query terlalu umum
          if (results.length > 100) break; 
        }
      }
      if (results.length > 100) break;
    }
    return results;
  }
}

// Riverpod provider untuk QuranDataService
final quranDataServiceProvider = Provider((ref) => QuranDataService());
final pageAyahsProvider = FutureProvider.family<List<Ayah>, int>((ref, pageNumber) async {
  final service = ref.read(quranDataServiceProvider);
  // Memanggil fungsi yang sudah kita buat sebelumnya di dalam service
  return service.getAyahsByPage(pageNumber);
});
// Provider untuk data surah yang sudah dimuat (untuk splash screen atau global access)
final allSurahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = ref.read(quranDataServiceProvider);
  await service.loadAllSurahData();
  return service.getAllSurahs();
});