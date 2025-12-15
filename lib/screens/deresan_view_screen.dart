import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/quran_data_service.dart';
import '../../utils/tajweed_parser.dart';
import '../../utils/auto_tajweed_parser.dart';


// ===============================
// DERESAN VIEW SCREEN
// ===============================
class DeresanViewScreen extends StatefulWidget {
  final int initialPage;

  const DeresanViewScreen({
    super.key,
    required this.initialPage,
  });

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
      showDragHandle: true,
      builder: (_) => SettingsModalContent(currentPage: _currentPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halaman $_currentPage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showSettingsModal(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 604,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index + 1;
              });
            },
            itemBuilder: (_, index) {
              return DeresanPage(pageNumber: index + 1);
            },
          ),
          _NavigationControls(controller: _pageController),
        ],
      ),
    );
  }
}


// ===============================
// PAGE CONTENT
// ===============================
class DeresanPage extends ConsumerWidget {
  final int pageNumber;

  const DeresanPage({
    super.key,
    required this.pageNumber,
  });

  String _toArabicNumber(int number) {
    const digits = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return number
        .toString()
        .split('')
        .map((d) => digits[int.parse(d)])
        .join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final ayahsAsync = ref.watch(pageAyahsProvider(pageNumber));

    return ayahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Gagal memuat halaman $pageNumber')),
      data: (ayahs) {
        if (ayahs.isEmpty) {
          return Center(child: Text('Tidak ada data.'));
        }

        final List<Widget> pageWidgets = [];
        List<InlineSpan> currentSpans = [];

        final baseTextStyle = TextStyle(
          fontFamily: 'LPMQ',
          fontSize: settings.arabicFontSize,
          height: 1.9,
          color: theme.colorScheme.onSurface,
        );

        for (int i = 0; i < ayahs.length; i++) {
          final ayah = ayahs[i];

          // ===== Surah baru =====
          if (i == 0 || ayah.surahId != ayahs[i - 1].surahId) {
            if (currentSpans.isNotEmpty) {
              pageWidgets.add(
                RichText(
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  text: TextSpan(children: currentSpans),
                ),
              );
              currentSpans = [];
            }

            pageWidgets.add(
              _SurahHeaderWidget(surahName: ayah.surahName),
            );

            if (ayah.surahId != 9 && ayah.number == 1) {
              pageWidgets.add(
                _BismillahWidget(fontSize: settings.arabicFontSize),
              );
            }
          }

          // ===== Teks Ayat =====
          final spans = settings.language == 'id'
              ? AutoTajweedParser.parse(ayah.arabicText, baseTextStyle)
              : TajweedParser.parse(ayah.tajweedText, baseTextStyle);

          currentSpans.addAll(spans);

          // ===== Nomor Ayat Ornamental =====
          currentSpans.add(const TextSpan(text: '\u00A0'));

          currentSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AyahOrnamentalNumber(
                number: _toArabicNumber(ayah.number),
                fontSize: settings.arabicFontSize,
                hasSajda: false,
              ),
            ),
          );

          currentSpans.add(const TextSpan(text: '\u00A0'));
        }

        if (currentSpans.isNotEmpty) {
          pageWidgets.add(
            RichText(
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              text: TextSpan(children: currentSpans),
            ),
          );
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: pageWidgets,
            ),
          ),
        );
      },
    );
  }
}


// ===============================
// ORNAMENTAL AYAH NUMBER (FINAL)
// ===============================
class AyahOrnamentalNumber extends StatelessWidget {
  final String number;
  final double fontSize;
  final bool hasSajda;

  const AyahOrnamentalNumber({
    super.key,
    required this.number,
    required this.fontSize,
    this.hasSajda = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '${hasSajda ? '۩ ' : ''}۞ $number',
      style: TextStyle(
        fontFamily: 'Uthmani',
        fontSize: fontSize * 0.8,
        fontWeight: FontWeight.bold,
        height: 1.2,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}


// ===============================
// SURAH HEADER
// ===============================
class _SurahHeaderWidget extends StatelessWidget {
  final String surahName;

  const _SurahHeaderWidget({
    required this.surahName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor),
      ),
      child: Center(
        child: Text(
          surahName,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}


// ===============================
// BISMILLAH
// ===============================
class _BismillahWidget extends StatelessWidget {
  final double fontSize;

  const _BismillahWidget({
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Center(
        child: Text(
          'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'LPMQ',
            fontSize: fontSize * 1.1,
          ),
        ),
      ),
    );
  }
}


// ===============================
// NAVIGATION CONTROLS
// ===============================
class _NavigationControls extends StatelessWidget {
  final PageController controller;

  const _NavigationControls({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                controller.previousPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                controller.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// ===============================
// SETTINGS MODAL
// ===============================
class SettingsModalContent extends ConsumerWidget {
  final int currentPage;

  const SettingsModalContent({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ukuran Font Arab',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: settings.arabicFontSize,
            min: 18,
            max: 40,
            divisions: 22,
            label: settings.arabicFontSize.round().toString(),
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setFontSize(value);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.bookmark_add),
            label: const Text('Tandai Halaman Ini'),
            onPressed: () {
              _showBookmarkDialog(context, ref, currentPage);
            },
          ),
        ],
      ),
    );
  }
  
  void _showBookmarkDialog(
    BuildContext context,
    WidgetRef ref,
    int currentPage,
  ) async {
    final textController = TextEditingController();
    final bookmarks = ref.read(bookmarkProvider);
    final existingNames = bookmarks.keys.toList();

    final ayahs = await ref.read(pageAyahsProvider(currentPage).future);
    if (ayahs.isEmpty) return;

    final firstAyah = ayahs.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tandai Halaman Deresan'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Input bookmark baru =====
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bookmark Baru',
                    hintText: 'Contoh: Deresan Malam',
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Bookmark lama =====
                if (existingNames.isNotEmpty) ...[
                  const Text(
                    'Atau timpa bookmark yang sudah ada:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Divider(),

                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: existingNames.length,
                      itemBuilder: (context, index) {
                        final name = existingNames[index];
                        final bookmark = bookmarks[name]!;

                        return ListTile(
                          title: Text(name),
                          subtitle: bookmark.pageNumber != null
                              ? Text('Halaman ${bookmark.pageNumber}')
                              : null,
                          onTap: () async {
                            final newBookmark = Bookmark(
                              type: BookmarkViewType.deresan,
                              surahId: firstAyah.id,
                              surahName: firstAyah.surahName,
                              ayahNumber: firstAyah.number,
                              pageNumber: currentPage,
                            );

                            await ref
                                .read(bookmarkProvider.notifier)
                                .addOrUpdateBookmark(name, newBookmark);

                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).pop();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Bookmark "$name" berhasil diperbarui'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
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
              onPressed: () async {
                final name = textController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nama bookmark tidak boleh kosong'),
                    ),
                  );
                  return;
                }

                final newBookmark = Bookmark(
                  type: BookmarkViewType.deresan,
                  surahId: firstAyah.id,
                  surahName: firstAyah.surahName,
                  ayahNumber: firstAyah.number,
                  pageNumber: currentPage,
                );

                await ref
                    .read(bookmarkProvider.notifier)
                    .addOrUpdateBookmark(name, newBookmark);

                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bookmark "$name" berhasil disimpan'),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

}

