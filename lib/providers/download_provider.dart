import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReciterModel {
  final String name;
  final String zipUrl;
  ReciterModel({required this.name, required this.zipUrl});
}

class PlaylistItem {
  final String reciterName;
  final int startSurah;
  final int startAyah;
  final int endSurah;
  final int endAyah;
  final bool isRepeat;

  PlaylistItem({
    required this.reciterName,
    required this.startSurah,
    required this.startAyah,
    required this.endSurah,
    required this.endAyah,
    required this.isRepeat,
  });

  Map<String, dynamic> toMap() => {
    'reciterName': reciterName,
    'startSurah': startSurah,
    'startAyah': startAyah,
    'endSurah': endSurah,
    'endAyah': endAyah,
    'isRepeat': isRepeat,
  };

  factory PlaylistItem.fromMap(Map<String, dynamic> map) => PlaylistItem(
    reciterName: map['reciterName'] ?? '',
    startSurah: map['startSurah'] ?? 1,
    startAyah: map['startAyah'] ?? 1,
    endSurah: map['endSurah'] ?? 1,
    endAyah: map['endAyah'] ?? 1,
    isRepeat: map['isRepeat'] ?? false,
  );
}

class DownloadState {
  final bool isDownloading;
  final double progress;
  final String statusMessage;
  final String currentFile;
  final List<ReciterModel> zipLinks; 
  final List<String> localAudioFiles;
  final bool showDownloaderList;
  final List<PlaylistItem> playlists;
  final String downloadSpeed;
  final String remainingTime;


  DownloadState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.statusMessage = "",
    this.currentFile = "",
    this.zipLinks = const [],
    this.localAudioFiles = const [],
    this.showDownloaderList = false,
    this.playlists = const [],
    this.downloadSpeed = "",
    this.remainingTime = "",
  });

  DownloadState copyWith({
    bool? isDownloading,
    double? progress,
    String? statusMessage,
    String? currentFile,
    List<ReciterModel>? zipLinks,
    List<String>? localAudioFiles,
    bool? showDownloaderList,
    List<PlaylistItem>? playlists,
    String? downloadSpeed,
    String? remainingTime,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      currentFile: currentFile ?? this.currentFile,
      zipLinks: zipLinks ?? this.zipLinks,
      localAudioFiles: localAudioFiles ?? this.localAudioFiles,
      showDownloaderList: showDownloaderList ?? this.showDownloaderList,
      playlists: playlists ?? this.playlists,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      remainingTime: remainingTime ?? this.remainingTime,
    );
  }
}

final downloadServiceProvider = StateNotifierProvider<DownloadService, DownloadState>((ref) {
  return DownloadService();
});

class DownloadService extends StateNotifier<DownloadState> {
  DownloadService() : super(DownloadState()); // Inisialisasi awal State

  void toggleDownloaderMode(bool show) {
    state = state.copyWith(showDownloaderList: show);
    if (show && state.zipLinks.isEmpty) {
      scrapeZipLinks();
    }
  }

  Future<void> loadDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final files = prefs.getStringList('downloaded_audio_files') ?? [];
    
    final playlistRaw = prefs.getStringList('user_playlists') ?? [];
    List<PlaylistItem> loadedPlaylists = playlistRaw.map((item) {
      return PlaylistItem.fromMap(json.decode(item));
    }).toList();

    state = state.copyWith(
      localAudioFiles: files,
      playlists: loadedPlaylists,
      statusMessage: files.isEmpty ? "Belum ada audio yang diunduh." : "Menampilkan ${files.length} file audio lokal.",
    );
  }

  Future<void> addPlaylistItem({
    required String reciterName,
    required int startSurah,
    required int startAyah,
    required int endSurah,
    required int endAyah,
    required bool isRepeat,
  }) async {
    final newItem = PlaylistItem(
      reciterName: reciterName,
      startSurah: startSurah,
      startAyah: startAyah,
      endSurah: endSurah,
      endAyah: endAyah,
      isRepeat: isRepeat,
    );

    final updatedPlaylists = [...state.playlists, newItem];
    
    final prefs = await SharedPreferences.getInstance();
    List<String> rawList = updatedPlaylists.map((item) => json.encode(item.toMap())).toList();
    await prefs.setStringList('user_playlists', rawList);

    state = state.copyWith(playlists: updatedPlaylists);
  }

  Future<void> deletePlaylistItem(int index) async {
    final updatedPlaylists = List<PlaylistItem>.from(state.playlists)..removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    List<String> rawList = updatedPlaylists.map((item) => json.encode(item.toMap())).toList();
    await prefs.setStringList('user_playlists', rawList);
    
    state = state.copyWith(playlists: updatedPlaylists);
  }

  Future<void> scrapeZipLinks() async {
    state = state.copyWith(statusMessage: "Mencari paket syaikh di website...");
    try {
      final response = await http.get(Uri.parse('https://www.versebyversequran.com/recitations_ayat.html'));
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var listItems = document.querySelectorAll('li');
        List<ReciterModel> parsedReciters = [];

        for (var li in listItems) {
          var strongTag = li.querySelector('strong');
          var zipTag = li.querySelector('a[href\$=".zip"]');

          if (strongTag != null && zipTag != null) {
            String name = strongTag.text.trim();
            String? href = zipTag.attributes['href'];
            if (href != null && href.isNotEmpty) {
              String absoluteUrl = href.startsWith('http') ? href : 'https://www.versebyversequran.com/$href';
              parsedReciters.add(ReciterModel(name: name, zipUrl: absoluteUrl));
            }
          }
        }
        state = state.copyWith(zipLinks: parsedReciters, statusMessage: "Ditemukan ${parsedReciters.length} paket Qari/Syaikh.");
      } else {
        state = state.copyWith(statusMessage: "Gagal memuat halaman web.");
      }
    } catch (e) {
      state = state.copyWith(statusMessage: "Error: $e");
    }
  }

  Future<void> downloadAndExtractZip(String url, String reciterName) async {
    final folderName = reciterName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(' ', '_');

    final zipFileName = url.split('/').last; 
    
    File? tempZipFile;
    Directory? targetDir;

    state = state.copyWith(
      isDownloading: true,
      progress: 0.0,
      currentFile: zipFileName,
      statusMessage: "Mengunduh paket Syaikh $reciterName...",
      downloadSpeed: "0 KB/s",
      remainingTime: "--:--",
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      
      targetDir = Directory('${directory.path}/quran_audio/$folderName');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      tempZipFile = File('${directory.path}/quran_audio/${folderName}_temp.zip');

      final response = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final totalLength = response.contentLength ?? 0;
      
      final IOSink sink = tempZipFile.openWrite();
      int downloadedBytes = 0;
      final Stopwatch stopwatch = Stopwatch()..start();

      await response.stream.listen(
        (value) {
          sink.add(value);
          downloadedBytes += value.length;
          if (totalLength > 0) {
            final double currentProgress = downloadedBytes / totalLength;
            final int millisecondsElapsed = stopwatch.elapsedMilliseconds;
            
            String speedText = "0 KB/s";
            String etaText = "--:--";
            if (millisecondsElapsed > 0) {
              final double bytesPerSecond = (downloadedBytes / millisecondsElapsed) * 1000;
              
              if (bytesPerSecond >= 1024 * 1024) {
                speedText = "${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s";
              } else {
                speedText = "${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s";
              }

              final int remainingBytes = totalLength - downloadedBytes;
              if (bytesPerSecond > 0) {
                final double secondsRemaining = remainingBytes / bytesPerSecond;
                
                final int minutes = (secondsRemaining / 60).floor();
                final int seconds = (secondsRemaining % 60).floor();
                etaText = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
              }
            }
            state = state.copyWith(progress: currentProgress, downloadSpeed: speedText, remainingTime: etaText, statusMessage: "Mengunduh paket Syaikh $reciterName...");
          }
        },
        onDone: () async {
          stopwatch.stop();
          await sink.close();

          state = state.copyWith(
            statusMessage: "Mengekstrak berkas audio Syaikh $reciterName...", 
            progress: 0.0,
            downloadSpeed: "0 KB/s",
            remainingTime: "--:--",
          );

          final bytes = await tempZipFile!.readAsBytes();
          final archive = ZipDecoder().decodeBytes(bytes);
          List<String> newLocalPaths = [];

          for (final file in archive) {
            final filename = file.name;
            if (file.isFile && (filename.endsWith('.mp3') || filename.endsWith('.wav'))) {
              final data = file.content as List<int>;
              
              final outFile = File('${targetDir!.path}/$filename');
              await outFile.create(recursive: true);
              await outFile.writeAsBytes(data);
              
              newLocalPaths.add('$folderName/$filename'); 
            }
          }

          final prefs = await SharedPreferences.getInstance();
          List<String> savedFiles = prefs.getStringList('downloaded_audio_files') ?? [];
          savedFiles.addAll(newLocalPaths);
          
          final updatedFiles = savedFiles.toSet().toList();
          await prefs.setStringList('downloaded_audio_files', updatedFiles);
          await prefs.setBool('zip_downloaded_$url', true);

          state = state.copyWith(
            localAudioFiles: updatedFiles,
            statusMessage: "Sukses mengunduh dan mengekstrak Syaikh $reciterName!",
            isDownloading: false,
            showDownloaderList: false,
            downloadSpeed: "0 KB/s",
            remainingTime: "--:--",
          );

          _cleanUpTempFile(tempZipFile);
        },
        onError: (e) async {
          stopwatch.stop();
          await sink.close();
          throw Exception("Koneksi terputus saat mengunduh: $e");
        },
        cancelOnError: true,
      );
    } catch (e) {
      state = state.copyWith(statusMessage: "Gagal memproses: $e", isDownloading: false, downloadSpeed: "0 KB/s", remainingTime: "--:--");
      
      _cleanUpTempFile(tempZipFile);
      _cleanUpCorruptedFolder(targetDir);
    }
  }

  void _cleanUpTempFile(File? file) {
    if (file != null && file.existsSync()) {
      try {
        file.deleteSync();
      } catch (e) {
        state = state.copyWith(statusMessage: "Gagal menghapus berkas sementara: $e");
      }
    }
  }

  void _cleanUpCorruptedFolder(Directory? dir) async {
    if (dir != null && await dir.exists()) {
      try {
        await dir.delete(recursive: true);
        state = state.copyWith(statusMessage: "🗑️ Folder korup/tidak lengkap berhasil dieliminasi otomatis.");
      } catch (e) {
        state = state.copyWith(statusMessage: "Gagal menghapus folder korup: $e");
      }
    }
  }

  Future<bool> isZipDownloaded(String url, String reciterName) async {
    final folderName = reciterName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(' ', '_');

    try {
      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/quran_audio/$folderName');
      if (await targetDir.exists()) {
        final List<FileSystemEntity> files = targetDir.listSync();        
        final hasAudioFiles = files.any((file) => 
            file is File && (file.path.endsWith('.mp3') || file.path.endsWith('.wav')));

        if (hasAudioFiles) {
          return true;
        }
      }
    } catch (e) {
      return false; 
    }

    return false;
  }

  Future<void> deleteReciterFolder(String folderName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/quran_audio/$folderName');
      
      // Hapus folder secara fisik dari storage (recursive: true akan menghapus semua mp3 di dalamnya)
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
      }

      final prefs = await SharedPreferences.getInstance();
      List<String> savedFiles = prefs.getStringList('downloaded_audio_files') ?? [];
      
      // Filter & buang semua path file yang mengandung nama folder syaikh ini
      List<String> updatedFiles = savedFiles.where((file) => !file.startsWith('$folderName/')).toList();
      await prefs.setStringList('downloaded_audio_files', updatedFiles);
      
      // Hapus juga status centang download di daftar online (opsional, sesuaikan baseUrl web Anda jika ada)
      // Di sini kita hapus key pref yang mengandung nama folder tersebut jika Anda menyimpannya menggunakan URL
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.contains(folderName)) {
          await prefs.remove(key);
        }
      }

      // Perbarui State UI
      state = state.copyWith(
        localAudioFiles: updatedFiles,
        statusMessage: "Folder Syaikh $folderName berhasil dihapus.",
      );
    } catch (e) {
      state = state.copyWith(statusMessage: "Gagal menghapus folder: $e");
    }
  }

  Future<void> resetAllData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final mainAudioDir = Directory('${directory.path}/quran_audio');
      
      // Hapus induk folder audio secara fisik beserta seluruh subfolder syaikh di dalamnya
      if (await mainAudioDir.exists()) {
        await mainAudioDir.delete(recursive: true);
      }

      // Bersihkan SharedPreferences terkait audio dan playlist
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('downloaded_audio_files');
      await prefs.remove('user_playlists');
      
      // Hapus juga status cache download online
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('zip_downloaded_')) {
          await prefs.remove(key);
        }
      }

      // Perbarui State UI menjadi kosong total
      state = state.copyWith(
        localAudioFiles: const [],
        playlists: const [],
        statusMessage: "Semua data audio lokal dan playlist berhasil di-reset!",
      );
    } catch (e) {
      state = state.copyWith(statusMessage: "Gagal melakukan reset data: $e");
    }
  }
}