// lib/screens/tafsir_surah_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_index_model.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/tafsir_view_screen.dart';

class TafsirSurahListScreen extends ConsumerWidget {
  const TafsirSurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(allSurahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Surah untuk Tafsir"),
      ),
      body: surahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Gagal memuat daftar surah: $e'),
        ),
        data: (List<SurahIndexInfo> surahs) {
          return ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              final theme = Theme.of(context);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TafsirViewScreen(surahId: surah.suraId),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        /// Nomor Surah
                        CircleAvatar(
                          backgroundColor:
                              theme.primaryColor.withOpacity(0.1),
                          child: Text(
                            surah.suraId.toString(),
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        /// Nama Latin + info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surah.nameLatin,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto'
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${surah.revelationType} • ${surah.numberOfAyahs} Ayat',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),

                        /// Nama Arab
                        Text(
                          surah.nameArabic,
                          style: TextStyle(
                            fontFamily: 'LPMQ',
                            fontSize: 22,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
