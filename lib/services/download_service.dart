import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService extends ChangeNotifier {
  final Dio _dio = Dio();

  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusMessage = 'Siap mengunduh audio.';
  String _currentFile = '';

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  String get statusMessage => _statusMessage;
  String get currentFile => _currentFile;

  final String _baseUrl = 'https://175.45.187.198/audio/';

  DownloadService() {
    (_dio.httpClientAdapter as dynamic).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  Future<Directory> _audioDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// 🔍 cek file sudah ada / belum
  Future<bool> fileExists(String filename) async {
    final dir = await _audioDir();
    return File('${dir.path}/$filename').exists();
  }

  /// ⬇️ download semua file dari audio_index.json
  Future<void> downloadAll(List<String> filenames) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _progress = 0;
    _statusMessage = 'Mempersiapkan unduhan...';
    notifyListeners();

    final dir = await _audioDir();
    int done = 0;

    for (final file in filenames) {
      _currentFile = file;
      notifyListeners();

      final savePath = '${dir.path}/$file';

      if (await File(savePath).exists()) {
        done++;
        _progress = done / filenames.length;
        _statusMessage = 'Lewati (sudah ada)';
        notifyListeners();
        continue;
      }

      try {
        await _dio.download(
          '$_baseUrl$file',
          savePath,
          onReceiveProgress: (r, t) {
            if (t > 0) {
              _progress = (done + r / t) / filenames.length;
              _statusMessage = 'Mengunduh...';
              notifyListeners();
            }
          },
        );
        done++;
      } catch (e) {
        _statusMessage = 'Gagal: $file';
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    _isDownloading = false;
    _currentFile = '';
    _progress = 1;
    _statusMessage = 'Semua audio siap digunakan.';
    notifyListeners();
  }
}
