import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadService extends ChangeNotifier {
  bool isDownloading = false;
  double progress = 0.0;
  String statusMessage = "";
  String currentFile = "";
  
  List<String> zipLinks = []; 
  List<String> localAudioFiles = []; // Menampung file lokal yang sudah terunduh
  bool showDownloaderList = false;   // Mengontrol visibilitas daftar unduhan web

  // Mengubah mode tampilan ke menu download web
  void toggleDownloaderMode(bool show) {
    showDownloaderList = show;
    if (show && zipLinks.isEmpty) {
      scrapeZipLinks(); // Otomatis scrape jika list masih kosong
    }
    notifyListeners();
  }

  // Memuat daftar file lokal yang sudah tersimpan di SharedPreferences
  Future<void> loadDownloadedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    localAudioFiles = prefs.getStringList('downloaded_audio_files') ?? [];
    
    if (localAudioFiles.isEmpty) {
      statusMessage = "Belum ada audio yang diunduh.";
    } else {
      statusMessage = "Menampilkan ${localAudioFiles.length} file audio lokal.";
    }
    notifyListeners();
  }

  // Scraping link .zip dari website
  Future<List<String>> scrapeZipLinks() async {
    statusMessage = "Mencari paket syaikh di website...";
    notifyListeners();
    try {
      final response = await http.get(Uri.parse('https://www.versebyversequran.com/recitations_ayat.html'));
      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        var links = document.querySelectorAll('a[href\$=".zip"]');
        
        zipLinks = links
            .map((element) => element.attributes['href'] ?? '')
            .where((href) => href.isNotEmpty)
            .map((href) => href.startsWith('http') ? href : 'https://www.versebyversequran.com/$href')
            .toList();
            
        statusMessage = "Ditemukan ${zipLinks.length} paket Qari/Syaikh.";
      } else {
        statusMessage = "Gagal memuat halaman web.";
      }
    } catch (e) {
      statusMessage = "Error: $e";
    }
    notifyListeners();
    return [];
  }

  // Download, Ekstrak, dan Simpan
  Future<void> downloadAndExtractZip(String url) async {
    isDownloading = true;
    progress = 0.0;
    currentFile = url.split('/').last;
    statusMessage = "Mengunduh paket...";
    notifyListeners();

    try {
      final directory = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${directory.path}/quran_audio');
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
            progress = bytes.length / totalLength;
            notifyListeners();
          }
        },
        onDone: () async {
          statusMessage = "Mengekstrak berkas audio...";
          progress = 0.0;
          notifyListeners();

          final archive = ZipDecoder().decodeBytes(bytes);
          List<String> newLocalPaths = [];

          for (final file in archive) {
            final filename = file.name;
            if (file.isFile && (filename.endsWith('.mp3') || filename.endsWith('.wav'))) {
              final data = file.content as List<int>;
              final outFile = File('${targetDir.path}/$filename');
              await outFile.create(recursive: true);
              await outFile.writeAsBytes(data);
              
              // Menyimpan nama file saja atau full path. 
              // Di sini kita simpan nama file-nya untuk struktur tampilan yang rapi.
              newLocalPaths.add(filename); 
            }
          }

          // Update SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          List<String> savedFiles = prefs.getStringList('downloaded_audio_files') ?? [];
          savedFiles.addAll(newLocalPaths);
          
          // Hilangkan duplikasi jika ada file dengan nama sama
          localAudioFiles = savedFiles.toSet().toList();
          await prefs.setStringList('downloaded_audio_files', localAudioFiles);
          
          await prefs.setBool('zip_downloaded_$url', true);

          statusMessage = "Sukses menambahkan Syaikh baru!";
          isDownloading = false;
          showDownloaderList = false; // Kembalikan ke halaman list file lokal setelah sukses
          notifyListeners();
        },
        onError: (e) {
          throw e;
        },
        cancelOnError: true,
      );
    } catch (e) {
      statusMessage = "Gagal memproses: $e";
      isDownloading = false;
      notifyListeners();
    }
  }

  Future<bool> isZipDownloaded(String url) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('zip_downloaded_$url') ?? false;
  }
}