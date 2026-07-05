import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Model Data Qari/Syaikh dari Web
class ReciterModel {
  final String name;
  final String zipUrl;
  ReciterModel({required this.name, required this.zipUrl});
}

// 2. Model Data Konfigurasi Playlist
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

// 3. Objek Blueprint State Data
class DownloadState {
  final bool isDownloading;
  final double progress;
  final String statusMessage;
  final String currentFile;
  final List<ReciterModel> zipLinks; 
  final List<String> localAudioFiles;
  final bool showDownloaderList;
  final List<PlaylistItem> playlists;

  DownloadState({
    this.isDownloading = false,
    this.progress = 0.0,
    this.statusMessage = "",
    this.currentFile = "",
    this.zipLinks = const [],
    this.localAudioFiles = const [],
    this.showDownloaderList = false,
    this.playlists = const [],
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
    );
  }
}

// 4. Registrasi Global Provider ke Riverpod
final downloadServiceProvider = StateNotifierProvider<DownloadService, DownloadState>((ref) {
  return DownloadService();
});

// 5. Brain Business Logic (Wajib extends StateNotifier agar mengenali objek 'state')
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

  Future<void> downloadAndExtractZip(String url) async {
    final zipFileName = url.split('/').last; 
    final folderName = zipFileName.replaceAll('.zip', ''); 

    state = state.copyWith(
      isDownloading: true,
      progress: 0.0,
      currentFile: zipFileName,
      statusMessage: "Mengunduh paket...",
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/quran_audio/$folderName');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final response = await http.Client().send(http.Request('GET', Uri.parse(url)));
      final totalLength = response.contentLength ?? 0;
      List<int> bytes = [];

      await response.stream.listen(
        (value) {
          bytes.addAll(value);
          if (totalLength > 0) {
            state = state.copyWith(progress: bytes.length / totalLength);
          }
        },
        onDone: () async {
          state = state.copyWith(statusMessage: "Mengekstrak berkas audio...", progress: 0.0);

          final archive = ZipDecoder().decodeBytes(bytes);
          List<String> newLocalPaths = [];

          for (final file in archive) {
            final filename = file.name;
            if (file.isFile && (filename.endsWith('.mp3') || filename.endsWith('.wav'))) {
              final data = file.content as List<int>;
              final outFile = File('${targetDir.path}/$filename');
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
            statusMessage: "Sukses menambahkan Syaikh baru!",
            isDownloading: false,
            showDownloaderList: false,
          );
        },
        onError: (e) {
          throw e;
        },
        cancelOnError: true,
      );
    } catch (e) {
      state = state.copyWith(statusMessage: "Gagal memproses: $e", isDownloading: false);
    }
  }

  Future<bool> isZipDownloaded(String url) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('zip_downloaded_$url') ?? false;
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

  // 🌟 FUNGSI BARU 2: Reset Total (Hapus semua berkas audio dan playlist)
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