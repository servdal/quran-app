// lib/screens/sync_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/services/sync_service.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncService = ref.watch(syncServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sinkronisasi Data Tafsir"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sync_rounded, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Sinkronisasi Data Lokal ke Server",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                "Proses ini akan memindahkan data tafsir dari aplikasi ke akun Firebase Anda. Proses ini mungkin memakan waktu beberapa menit dan memerlukan koneksi internet.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              if (syncService.isSyncing)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: syncService.progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${(syncService.progress * 100).toStringAsFixed(0)}% - ${syncService.statusMessage}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // --- TAMPILAN BARU UNTUK TOTAL DATA ---
                    Text(
                      'Total data terkirim: ${syncService.totalDataSentKB.toStringAsFixed(2)} Bytes',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                )
              else 
                Text(
                  syncService.statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text("Mulai Sinkronisasi"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: syncService.isSyncing 
                  ? null 
                  : () => ref.read(syncServiceProvider).startSync(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}