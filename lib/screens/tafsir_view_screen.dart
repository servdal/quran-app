// lib/screens/tafsir_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/utils/tajweed_parser.dart';
import 'package:quran_app/widgets/analysis_popup.dart';

class TafsirViewScreen extends ConsumerWidget {
  final int surahId;
  const TafsirViewScreen({super.key, required this.surahId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahDetailProvider(surahId));
    // Memuat kamus analisis
    final analysisDictAsync = ref.watch(analysisDictionaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          data: (surah) => Text("Tafsir ${surah.englishName}"),
          loading: () => const Text("Memuat..."),
          error: (e, s) => const Text("Error"),
        ),
      ),
      body: surahAsync.when(
        data: (surah) => analysisDictAsync.when(
          // Menunggu kamus dan surah selesai dimuat
          data: (dictionary) => ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: surah.ayahs.length,
            itemBuilder: (context, index) {
              final ayah = surah.ayahs[index];
              final baseTextStyle = TextStyle(
                  fontFamily: 'LPMQ', fontSize: 24, height: 2.2,
                  color: Theme.of(context).colorScheme.onSurface);
              final textSpans = TajweedParser.parse(ayah.tajweedText, baseTextStyle);

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      textAlign: TextAlign.right, textDirection: TextDirection.rtl,
                      text: TextSpan(style: baseTextStyle, children: textSpans),
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyWordByWord(context, ayah, dictionary),
                    const SizedBox(height: 16),
                    Text(
                      "Tafsir: ${ayah.tafsirJalalayn}", textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(height: 32),
                  ],
                ),
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text("Gagal memuat kamus: $e")),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Gagal memuat surah: $e")),
      ),
    );
  }

  Widget _buildReadOnlyWordByWord(BuildContext context, Ayah ayah, Map<String, AnalysisDetail> dictionary) {
    final significantWords = ayah.words.where((word) => word.arabic.trim().isNotEmpty).toList();
    if (significantWords.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.end,
      textDirection: TextDirection.rtl,
      spacing: 8.0,
      runSpacing: 4.0,
      children: significantWords.map((word) {
        return InkWell(
          onTap: () {
            // Logika baru untuk mencari di kamus
            if (word.analysisId != null) {
              final analysisDetail = dictionary[word.analysisId.toString()];
              if (analysisDetail != null) {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AnalysisPopup(word: word, analysis: analysisDetail),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Column(
              children: [
                Text(word.arabic, style: const TextStyle(fontFamily: 'LPMQ', fontSize: 20)),
                if (word.translation.isNotEmpty)
                  Text(word.translation, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}