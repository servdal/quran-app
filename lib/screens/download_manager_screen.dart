import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/audio_provider.dart';

class DownloadManagerScreen extends ConsumerWidget {
  const DownloadManagerScreen({super.key});

  /// DAFTAR FILE AUDIO (cukup nama file)
  static const List<String> audioFiles = [
    "001_Surat Al - fatihah dan Al - Haqqah ayat 1-8.mp3",
    "041_Surat Fusshilat.mp3",
    "042_Surat Asy Syura_1.mp3",
    "042_Surat Asy Syura_2.mp3",
    "043_Surat Az - Zukhruf Ayat 1 - 28.mp3",
    "043_Surat Az - Zukhruf Ayat 29-79.mp3",
    "050_Surat Qaf Ayat 1-6.mp3",
    "050_Surat Qaf Ayat 12-27.mp3",
    // ➕ lanjutkan sesuai koleksi kamu
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloader = ref.watch(downloadServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Unduh Audio Tafsir')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: downloader.isDownloading
                  ? downloader.progress
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              downloader.statusMessage,
              textAlign: TextAlign.center,
            ),
            if (downloader.currentFile.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  downloader.currentFile,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: audioFiles.length,
                itemBuilder: (context, index) {
                  final file = audioFiles[index];
                  return ListTile(
                    leading: const Icon(Icons.audiotrack),
                    title: Text(
                      file,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: FutureBuilder<bool>(
                      future: ref
                          .read(downloadServiceProvider)
                          .fileExists(file),
                      builder: (context, snap) {
                        if (snap.data == true) {
                          return const Icon(Icons.check_circle,
                              color: Colors.green);
                        }
                        return const Icon(Icons.cloud_download);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Unduh Semua Audio'),
              onPressed: downloader.isDownloading
                  ? null
                  : () {
                      ref
                          .read(downloadServiceProvider)
                          .downloadAll(audioFiles);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
