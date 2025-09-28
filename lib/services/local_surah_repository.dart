// lib/services/local_surah_repository.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_model.dart';

class LocalSurahRepository {
  // Mendapatkan path ke direktori dokumen yang bisa ditulis
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Mendapatkan path lengkap untuk file surah tertentu
  Future<File> _getLocalFile(int surahId) async {
    final path = await _localPath;
    return File('$path/surah/$surahId.json');
  }

  // Fungsi utama untuk mendapatkan data surah
  Future<Surah> getSurahById(int surahId) async {
    try {
      final file = await _getLocalFile(surahId);
      String jsonString = await file.readAsString();
      return Surah.fromJson(json.decode(jsonString));
    } catch (e) {
      // Jika file tidak ada, ini mungkin pertama kali dibuka
      print("File lokal tidak ditemukan, memuat dari assets...");
      return _loadFromAssets(surahId);
    }
  }

  // Memuat dari assets jika file lokal belum ada
  Future<Surah> _loadFromAssets(int surahId) async {
    String jsonString = await rootBundle.loadString('assets/surah/$surahId.json');
    final surah = Surah.fromJson(json.decode(jsonString));
    // Simpan ke file lokal untuk penggunaan selanjutnya
    await updateSurah(surah);
    return surah;
  }

  // Fungsi untuk menyimpan perubahan ke file JSON lokal
  Future<void> updateSurah(Surah surah) async {
    final file = await _getLocalFile(surah.id);
    // Pastikan direktori 'surah' ada
    await file.parent.create(recursive: true);
    // Ubah objek Surah menjadi string JSON yang rapi (pretty print)
    final jsonString = JsonEncoder.withIndent('  ').convert(surah.toJson());
    await file.writeAsString(jsonString);
    print("Surah ${surah.id} berhasil disimpan ke penyimpanan lokal.");
  }
}

// Provider untuk repository lokal
final localSurahRepositoryProvider = Provider((ref) => LocalSurahRepository());

// Provider untuk mengambil data surah tunggal dari file lokal
final localSurahDataProvider = FutureProvider.family<Surah, int>((ref, surahId) {
  final repository = ref.watch(localSurahRepositoryProvider);
  return repository.getSurahById(surahId);
});