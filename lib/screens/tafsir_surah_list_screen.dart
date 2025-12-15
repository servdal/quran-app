// lib/screens/tafsir_surah_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_index_model.dart'; // Ganti model
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/tafsir_view_screen.dart';

class TafsirSurahListScreen extends ConsumerWidget {
  const TafsirSurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSurahsAsync = ref.watch(allSurahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Surah untuk Ditafsirkan"),
      ),
      body: allSurahsAsync.when(
        data: (surahs) {
          return ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(surah.suraId.toString()),
                  ),
                  title: Text(surah.name),
                  subtitle: Text("${surah.translation} | ${surah.numberOfAyahs} Ayat"),
                  trailing: Text(
                    surah.name,
                    style: const TextStyle(fontFamily: 'LPMQ', fontSize: 18),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TafsirViewScreen(surahId: surah.suraId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Gagal memuat daftar surah: $error')),
      ),
    );
  }
}