// lib/screens/tafsir_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

class TafsirViewScreen extends ConsumerWidget {
  final int surahId;
  const TafsirViewScreen({super.key, required this.surahId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahDetailProvider(surahId));

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          data: (surah) => Text("Tafsir ${surah.englishName}"),
          loading: () => const Text("Memuat..."),
          error: (e, s) => const Text("Error"),
        ),
      ),
      body: surahAsync.when(
        data: (surah) {
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: surah.ayahs.length,
            itemBuilder: (context, index) {
              final ayah = surah.ayahs[index];
              
              // --- PERUBAHAN 1: Ganti font di sini ---
              final baseTextStyle = TextStyle(
                  fontFamily: 'LPMQ', // Menggunakan font LPMQ
                  fontSize: 24,
                  height: 2.2,
                  color: Theme.of(context).colorScheme.onSurface);
              final textSpans = TajweedParser.parse(ayah.tajweedText, baseTextStyle);

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(style: baseTextStyle, children: textSpans),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildReadOnlyWordByWord(ayah),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      "Tafsir: ${ayah.tafsirJalalayn}",
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(height: 32),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
            child: Text(
                "Gagal memuat data surah: $e. Pastikan file JSON ada dan formatnya benar.")),
      ),
    );
  }

  Widget _buildReadOnlyWordByWord(Ayah ayah) {
    // Filter kata-kata yang tidak memiliki terjemahan atau hanya simbol
    final significantWords = ayah.words.where((word) => word.translation.trim().isNotEmpty).toList();
    
    // Jika tidak ada kata yang signifikan, jangan tampilkan apa-apa
    if(significantWords.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.end,
      textDirection: TextDirection.rtl,
      spacing: 8.0,
      runSpacing: 4.0,
      children: significantWords.map((word) {
        return Column(
          children: [
            // --- PERUBAHAN 2: Ganti font di sini ---
            Text(word.arabic,
                style:
                    const TextStyle(fontFamily: 'LPMQ', fontSize: 20)), // Menggunakan font LPMQ
            Text(word.translation,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        );
      }).toList(),
    );
  }
}