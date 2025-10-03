// lib/providers/download_provider.dart

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_app/models/surah_index_model.dart';
import 'package:quran_app/services/quran_data_service.dart';

// --- PROVIDER DIO YANG SUDAH DIPERBAIKI ---
// Provider ini akan membuat instance Dio yang sesuai dengan platform (web atau mobile)
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  if (!kIsWeb) {
    (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
       client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
       return client;
     };
  }
  return dio;
});


enum DownloadStatus { none, downloading, completed, failed }

class DownloadTask {
  final SurahIndexInfo surah;
  DownloadStatus status;
  double progress;
  String? filePath;

  DownloadTask({
    required this.surah,
    this.status = DownloadStatus.none,
    this.progress = 0.0,
    this.filePath,
  });
}

// --- NOTIFIER UNTUK MENGELOLA SEMUA TUGAS UNDUHAN ---
class DownloadNotifier extends StateNotifier<List<DownloadTask>> {
  final Dio _dio;
  final Ref _ref;

  DownloadNotifier(this._dio, this._ref) : super([]) {
    _init();
  }

  Future<void> _init() async {
    // 1. Ambil daftar semua surah
    final allSurahs = await _ref.read(allSurahsProvider.future);
    
    // 2. Dapatkan path direktori penyimpanan
    final documentsDir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${documentsDir.path}/audio');
    
    List<DownloadTask> tasks = [];

    // 3. Loop untuk setiap surah dan periksa filenya
    for (final surah in allSurahs) {
      final filePath = '${audioDir.path}/${surah.suraId}.mp3';
      final file = File(filePath);
      
      DownloadTask task;
      if (await file.exists()) {
        // Jika file sudah ada, langsung set status menjadi completed
        task = DownloadTask(
          surah: surah,
          status: DownloadStatus.completed,
          filePath: filePath,
        );
      } else {
        // Jika file belum ada, set status menjadi none
        task = DownloadTask(surah: surah);
      }
      tasks.add(task);
    }
    
    // 4. Update state dengan daftar tugas yang sudah diperiksa
    state = tasks;
  }

  Future<void> startDownload(int surahId) async {
    final taskIndex = state.indexWhere((task) => task.surah.suraId == surahId);
    if (taskIndex == -1 || state[taskIndex].status == DownloadStatus.downloading) return;

    state[taskIndex].status = DownloadStatus.downloading;
    state[taskIndex].progress = 0.0;
    state = List.from(state);

    try {
      // Dapatkan path audio dari provider audio
      // Kita asumsikan URL audio per surah bisa didapatkan dari suatu sumber.
      // Di sini kita gunakan contoh URL statis. Ganti dengan sumber URL Anda.
      // Contoh: 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/001.mp3'
      final surahNumber = surahId.toString().padLeft(3, '0');
      final url = 'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/$surahNumber.mp3';

      final documentsDir = await getApplicationDocumentsDirectory();
      final savePath = '${documentsDir.path}/audio/$surahId.mp3';
      
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            // Pastikan taskIndex masih valid sebelum update state
            if (mounted && taskIndex < state.length) {
              state[taskIndex].progress = progress;
              state = List.from(state);
            }
          }
        },
      );

      if (mounted) {
        state[taskIndex].status = DownloadStatus.completed;
        state[taskIndex].filePath = savePath;
        state = List.from(state);
      }
    } catch (e) {
      print("Download Error for Surah $surahId: $e");
      if (mounted) {
        state[taskIndex].status = DownloadStatus.failed;
        state = List.from(state);
      }
    }
  }
}

final downloadProvider = StateNotifierProvider<DownloadNotifier, List<DownloadTask>>((ref) {
  final dio = ref.watch(dioProvider);
  return DownloadNotifier(dio, ref);
});