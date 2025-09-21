// lib/screens/download_manager_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/services/download_service.dart';
import 'package:quran_app/services/quran_data_service.dart';

class DownloadManagerScreen extends ConsumerWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadService = ref.watch(downloadServiceProvider);
    final audioPathsAsync = ref.watch(audioPathsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manajer Unduhan Audio"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_download_outlined, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                "Unduh Semua File Audio Tafsir",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "File audio akan disimpan di perangkat Anda untuk bisa diputar secara offline. Total ukuran sekitar 500-600 MB. Pastikan Anda terhubung ke Wi-Fi.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              if (downloadService.isDownloading)
                Column(
                  children: [
                    LinearProgressIndicator(value: downloadService.progress),
                    const SizedBox(height: 10),
                    Text(
                      '${(downloadService.progress * 100).toStringAsFixed(1)}% - ${downloadService.statusMessage}',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              else
                audioPathsAsync.when(
                  data: (audioMap) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.download_for_offline),
                      label: const Text("Mulai Unduh Semua Audio"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      onPressed: () {
                        final filenames = audioMap.values.toList();
                        ref.read(downloadServiceProvider).downloadAllAudio(filenames);
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text("Gagal memuat daftar audio: $e"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}