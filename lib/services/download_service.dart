import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService extends ChangeNotifier {
  late final Dio _dio;
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = "Belum ada file audio yang diunduh.";

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  String get statusMessage => _statusMessage;

  // URL dasar tempat Anda menyimpan file audio
  final String _baseUrl = "https://175.45.187.198/audio/"; 
  DownloadService() {
    _dio = Dio();
    (_dio.httpClientAdapter as dynamic).onHttpClientCreate = (HttpClient client) {
      client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir.path;
  }

  Future<void> downloadAllAudio(List<String> filenames) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _progress = 0.0;
    _statusMessage = "Mempersiapkan unduhan...";
    notifyListeners();

    final path = await _localPath;
    int totalFiles = filenames.length;
    int downloadedCount = 0;

    for (int i = 0; i < totalFiles; i++) {
      String filename = filenames[i];
      String fileUrl = '$_baseUrl$filename';
      String savePath = '$path/$filename';

      if (await File(savePath).exists()) {
        downloadedCount++;
        _progress = downloadedCount / totalFiles;
        _statusMessage = "($downloadedCount/$totalFiles) File $filename sudah ada.";
        notifyListeners();
        continue;
      }
      
      try {
        await _dio.download(
          fileUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              double fileProgress = received / total;
              _progress = (downloadedCount + fileProgress) / totalFiles;
              _statusMessage = "Mengunduh ($downloadedCount/$totalFiles): $filename";
              notifyListeners();
            }
          },
        );
        downloadedCount++;
      } catch (e) {
        _statusMessage = "Gagal mengunduh $filename. Memeriksa file selanjutnya...";
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        SnackBar(content: Text("Gagal mengunduh $filename: $e"));
      }
    }

    _isDownloading = false;
    _statusMessage = "Semua file audio telah berhasil diperiksa dan diunduh.";
    notifyListeners();
  }
}

// Provider untuk DownloadService
final downloadServiceProvider = ChangeNotifierProvider((ref) => DownloadService());