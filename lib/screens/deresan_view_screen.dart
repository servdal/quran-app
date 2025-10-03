// lib/screens/deresan_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

class DeresanViewScreen extends StatefulWidget {
  final int initialPage;

  const DeresanViewScreen({super.key, required this.initialPage});

  @override
  State<DeresanViewScreen> createState() => _DeresanViewScreenState();
}

class _DeresanViewScreenState extends State<DeresanViewScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SettingsModalContent(currentPage: _currentPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hal. $_currentPage dari 604'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showSettingsModal(context),
          ),
        ],
      ),
      body: Column( // Bungkus dengan Column
        children: [
          Expanded( // PageView harus di dalam Expanded
            child: PageView.builder(
              controller: _pageController,
              itemCount: 604,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page + 1;
                });
              },
              itemBuilder: (context, index) {
                return DeresanPage(pageNumber: index + 1);
              },
            ),
          ),

          // --- TOMBOL NAVIGASI DITAMBAHKAN DI SINI ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(' '),
                  onPressed: _currentPage < 604
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      : null, // Tombol nonaktif di halaman terakhir
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text(' '),
                  onPressed: _currentPage > 1
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      : null, // Tombol nonaktif di halaman pertama
                ),
                
              ],
            ),
          )
        ],
      ),
    );
  }
}

class DeresanPage extends ConsumerWidget {
  final int pageNumber;
  const DeresanPage({super.key, required this.pageNumber});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAyahsAsync = ref.watch(pageAyahsProvider(pageNumber));
    final fontSize = ref.watch(settingsProvider).arabicFontSize;

    return pageAyahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Gagal memuat halaman: $error')),
      data: (ayahs) {
        if (ayahs.isEmpty) {
          return const Center(child: Text("Tidak ada data untuk halaman ini."));
        }
        
        final baseTextStyle = TextStyle(
          fontFamily: 'LPMQ',
          fontSize: fontSize,
          height: 2.2,
          color: Theme.of(context).colorScheme.onSurface,
        );

        List<TextSpan> textSpans = [];
        for (var ayah in ayahs) {
          textSpans.addAll(TajweedParser.parse(ayah.tajweedText, baseTextStyle));
          textSpans.add(
            TextSpan(
              text: ' (${ayah.ayaNumber}) ',
              style: baseTextStyle.copyWith(
                color: Theme.of(context).primaryColor,
                fontSize: fontSize * 0.7,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: baseTextStyle,
              children: textSpans,
            ),
          ),
        );
      },
    );
  }
}


class SettingsModalContent extends ConsumerWidget {
  final int currentPage;
  const SettingsModalContent({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ukuran Font', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(
            value: settings.arabicFontSize,
            min: 18,
            max: 48,
            divisions: 15,
            label: settings.arabicFontSize.round().toString(),
            onChanged: (double value) {
              ref.read(settingsProvider.notifier).setFontSize(value);
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Tandai Halaman Ini'),
              onPressed: () async {
                final ayahs = await ref.read(pageAyahsProvider(currentPage).future);
                if (ayahs.isNotEmpty) {
                  final firstAyah = ayahs.first;
                  // --- PERBAIKAN ERROR: Tambahkan pengecekan null ---
                  final surahInfo = firstAyah.surah;
                  if (surahInfo != null) {
                    ref.read(bookmarkProvider.notifier).setBookmark(
                          surahId: firstAyah.suraId,
                          surahName: surahInfo.englishName, // Gunakan surahInfo
                          ayahNumber: firstAyah.ayaId,
                          pageNumber: currentPage,
                          viewType: BookmarkViewType.deresan,
                        );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Halaman $currentPage telah ditandai.')),
                    );
                  } else {
                     Navigator.of(context).pop();
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal menandai: Info surah tidak ditemukan.')),
                    );
                  }
                } else {
                   Navigator.of(context).pop();
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menandai halaman: data tidak ditemukan.')),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}