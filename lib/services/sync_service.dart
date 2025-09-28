// lib/services/sync_service.dart

import 'dart:convert'; // Import untuk jsonEncode dan utf8
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/services/surah_repository.dart';

class SyncService extends ChangeNotifier {
  final SurahRepository _surahRepository;
  SyncService(this._surahRepository);

  bool _isSyncing = false;
  double _progress = 0.0;
  String _statusMessage = "Siap untuk sinkronisasi data tafsir.";
  int _totalToSync = 0;
  int _syncedCount = 0;
  double _totalDataSentKB = 0.0; // Variabel baru untuk total data

  bool get isSyncing => _isSyncing;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  double get totalDataSentKB => _totalDataSentKB; // Getter baru

  Future<void> startSync() async {
    if (_isSyncing) return;

    _isSyncing = true;
    _progress = 0;
    _syncedCount = 0;
    _totalDataSentKB = 0.0; // Reset saat mulai
    notifyListeners();

    try {
      _statusMessage = "Memeriksa data di server...";
      notifyListeners();
      final syncedIds = await _surahRepository.getSyncedSurahIds();

      final allSurahIds = List.generate(114, (i) => i + 1);
      final neededIds = allSurahIds.where((id) => !syncedIds.contains(id)).toList();
      _totalToSync = neededIds.length;
      
      if (_totalToSync == 0) {
        _statusMessage = "Semua data surah sudah tersinkronisasi!";
        _isSyncing = false;
        notifyListeners();
        return;
      }

      for (final surahId in neededIds) {
        _statusMessage = "Mempersiapkan Surah ke-$surahId...";
        notifyListeners();
        
        String jsonString = await rootBundle.loadString('assets/surah/$surahId.json');
        Map<String, dynamic> jsonMap = json.decode(jsonString);
        final surah = Surah.fromJson(jsonMap);

        // --- HITUNG UKURAN DATA SEBELUM DIKIRIM ---
        final surahJsonString = json.encode(surah.toJson());
        final sizeInBytes = utf8.encode(surahJsonString).length;

        // Kirim ke Firestore
        await _surahRepository.updateSurah(surah);

        // --- TAMBAHKAN UKURAN KE TOTAL SETELAH BERHASIL ---
        _totalDataSentKB += sizeInBytes; // Konversi ke KB
        _syncedCount++;
        _progress = _syncedCount / _totalToSync;
        _statusMessage = "($_syncedCount/$_totalToSync) Berhasil menyimpan Surah ${surah.englishName}.";
        notifyListeners();
        await Future.delayed(Duration.zero);
      }

      _statusMessage = "Sinkronisasi selesai! $_syncedCount surah berhasil disimpan.";
    } catch (e) {
      _statusMessage = "Terjadi kesalahan: $e";
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}

// Provider untuk SyncService
final syncServiceProvider = ChangeNotifierProvider((ref) {
  final surahRepo = ref.watch(surahRepositoryProvider);
  return SyncService(surahRepo);
});