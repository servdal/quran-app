import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:quran_app/providers/download_provider.dart' show DownloadState;
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService extends StateNotifier<DownloadState> {
  DownloadService() : super(DownloadState());
  void toggleDownloaderMode(bool show) {
    state = state.copyWith(showDownloaderList: show);
    if (show && state.zipLinks.isEmpty) {
      scrapeZipLinks();
    }
  }
  bool isDownloading = false;
  double progress = 0.0;
  String statusMessage = "Siap mendownload";
  String currentFile = "";
  List<String> zipLinks = [];
  List<String> extractedFiles = [];


  Future<List<String>> scrapeZipLinks() async {
    statusMessage = "Mencari link unduhan...";
    try {
      final response = await http.get(Uri.parse('https://www.versebyversequran.com/recitations_ayat.html'));
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        // Mencari semua tag <a> yang memiliki href berakhiran .zip
        var links = document.querySelectorAll('a[href\$=".zip"]');
        
        zipLinks = links
            .map((element) => element.attributes['href'] ?? '')
            .where((href) => href.isNotEmpty)
            // Pastikan menjadi absolute URL jika web menggunakan relative path
            .map((href) => href.startsWith('http') ? href : 'https://www.versebyversequran.com/$href')
            .toList();
            
        statusMessage = "Ditemukan ${zipLinks.length} paket unduhan.";
        return zipLinks;
      } else {
        statusMessage = "Gagal memuat halaman web.";
      }
    } catch (e) {
      statusMessage = "Error: $e";
    }
    return [];
  }

  Future<void> downloadAndExtractZip(String url, String reciterName) async {
    final folderName = reciterName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .replaceAll(' ', '_');
    final zipFileName = url.split('/').last; 

    state = state.copyWith(
      isDownloading: true,
      progress: 0.0,
      currentFile: zipFileName,
      statusMessage: "Mengunduh paket Syaikh $reciterName...",
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
            statusMessage: "Sukses mengunduh Syaikh $reciterName!",
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
}