// lib/screens/tafsir_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/utils/tajweed_parser.dart';
import 'package:quran_app/widgets/analysis_popup.dart';

class TafsirViewScreen extends ConsumerWidget {
  final int surahId;
  const TafsirViewScreen({super.key, required this.surahId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahDetailProvider(surahId));
    final analysisDictAsync = ref.watch(analysisDictionaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          data: (surah) => Text("Tafsir ${surah.englishName}"),
          loading: () => const Text("Memuat..."),
          error: (e, s) => const Text("Error"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            tooltip: "Berikutnya",
            onPressed: surahId < 114
                ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TafsirViewScreen(surahId: surahId + 1),
                      ),
                    );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            tooltip: "Sebelumnya",
            onPressed: surahId > 1
                ? () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TafsirViewScreen(surahId: surahId - 1),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: surahAsync.when(
        data: (surah) => analysisDictAsync.when(
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
                    _AyahToolbar(ayah: ayah, surahName: surah.englishName),
                    const SizedBox(height: 8),
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
class _AyahToolbar extends ConsumerWidget {
  final Ayah ayah;
  final String surahName;
  const _AyahToolbar({required this.ayah, required this.surahName});

  void _saveBookmark(WidgetRef ref, String name) {
    final newBookmark = Bookmark(
      type: BookmarkViewType.tafsir.name,
      surahId: ayah.suraId,
      surahName: surahName,
      ayahNumber: ayah.ayaNumber,
      pageNumber: ayah.pageNumber,
    );
    ref.read(bookmarkProvider.notifier).addOrUpdateBookmark(name, newBookmark);
  }

  void _showBookmarkDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    final bookmarks = ref.read(bookmarkProvider);
    final existingNames = bookmarks.keys.toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Simpan Bookmark Tafsir'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bookmark Baru',
                    hintText: 'Contoh: Kajian Tafsir',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Atau timpa yang sudah ada:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(),
                if (existingNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('Belum ada bookmark.')),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: existingNames.length,
                      itemBuilder: (context, index) {
                        final name = existingNames[index];
                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            _saveBookmark(ref, name);
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bookmark "$name" diperbarui.')),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Simpan Baru'),
              onPressed: () {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  _saveBookmark(ref, newName);
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tafsir ditandai di "$newName".')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'QS ${ayah.suraId}:${ayah.ayaNumber}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Tandai Ayat Ini',
            onPressed: () => _showBookmarkDialog(context, ref),
          ),
        ],
      ),
    );
  }
}
