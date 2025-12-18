import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/quran_data_service.dart';
import '../../utils/tajweed_parser.dart';
import '../../utils/auto_tajweed_parser.dart';

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

  /// MODE VIEW
  bool _showTafsir = false;

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
      body: SafeArea(
        child: Column(
          children: [
            _DeresanHeader(
              currentPage: _currentPage,
              onBack: () => Navigator.pop(context),
              onMore: () => _showSettingsModal(context),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 604,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index + 1;
                  });
                },
                itemBuilder: (_, index) {
                  return DeresanPage(
                    pageNumber: index + 1,
                    showTafsir: _showTafsir,
                  );
                },
              ),
            ),
          ],
        ),
      ),

      /// ===== FAB TOGGLE TAFSIR =====
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      extendBody: true,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey.shade300,
        elevation: 0,
        onPressed: () {
          setState(() {
            _showTafsir = !_showTafsir;
          });
        },
        child: Icon(
          _showTafsir ? Icons.menu_book : Icons.import_contacts,
          color: Colors.black,
          size: 28,
        ),
      ),

      bottomNavigationBar: _DeresanBottomBar(
        controller: _pageController,
      ),
    );
  }
}
class DeresanPage extends ConsumerWidget {
  final int pageNumber;
  final bool showTafsir;

  const DeresanPage({
    super.key,
    required this.pageNumber,
    required this.showTafsir,
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
      error: (e, _) => Center(child: Text('Gagal memuat halaman')),
      data: (ayahs) {
        if (ayahs.isEmpty) {
          return const Center(child: Text('Tidak ada data.'));
        }

        /// =========================
        /// MODE TAFSIR (1 HALAMAN)
        /// =========================
        if (showTafsir) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ayahs.map((ayah) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QS ${ayah.surahId}:${ayah.number}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ayah.tafsir,
                        textAlign: TextAlign.justify,
                        style: const TextStyle(
                          height: 1.6,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        }

        /// =========================
        /// MODE TEKS ARAB (DEFAULT)
        /// =========================
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

            pageWidgets.add(_SurahHeaderWidget(surahName: ayah.surahName));

            if (ayah.surahId != 9 && ayah.number == 1) {
              pageWidgets.add(
                _BismillahWidget(fontSize: settings.arabicFontSize),
              );
            }
          }

          final spans = settings.language == 'id'
              ? AutoTajweedParser.parse(ayah.arabicText, baseTextStyle)
              : TajweedParser.parse(ayah.tajweedText, baseTextStyle);

          currentSpans.addAll(spans);
          currentSpans.add(const TextSpan(text: '\u00A0'));

          currentSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AyahOrnamentalNumber(
                number: _toArabicNumber(ayah.number),
                fontSize: settings.arabicFontSize,
                hasSajda: ayah.isSajda,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(children: pageWidgets),
          ),
        );
      },
    );
  }
}

class _DeresanHeader extends StatelessWidget {
  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _DeresanHeader({
    required this.currentPage,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onBack,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: onMore,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Halaman $currentPage',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeresanBottomBar extends StatelessWidget {
  final PageController controller;

  const _DeresanBottomBar({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      color: Colors.grey.shade300,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 64),
              child: IconButton(
                icon: const Icon(Icons.fast_rewind),
                onPressed: () {
                  controller.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 64),
              child: IconButton(
                icon: const Icon(Icons.fast_forward),
                onPressed: () {
                  controller.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _BismillahWidget extends StatelessWidget {
  final double fontSize;

  const _BismillahWidget({
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
          const SizedBox(height: 12),
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
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bookmark Baru',
                    hintText: 'Contoh: Deresan Malam',
                  ),
                ),
                const SizedBox(height: 16),
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
                              surahId: firstAyah.surahId,
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
                                content: Text(
                                  'Bookmark "$name" berhasil diperbarui',
                                ),
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
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
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
                  surahId: firstAyah.surahId,
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

class AyahOrnamentalNumber extends StatelessWidget {
  /// Nomor ayat dalam format Arab (contoh: ١٢)
  final String number;

  /// Ukuran font mengikuti ukuran teks Arab
  final double fontSize;

  /// Apakah ayat sajdah
  final bool hasSajda;

  const AyahOrnamentalNumber({
    super.key,
    required this.number,
    required this.fontSize,
    this.hasSajda = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;

    return Text(
      _buildText(),
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Uthmani',
        fontSize: fontSize * 0.9,
        fontWeight: FontWeight.bold,
        height: 1.0,
        color: color,
      ),
    );
  }

  String _buildText() {
    // ۞ = Ornamental separator mushaf
    // ۩ = Sajdah marker
    if (hasSajda) {
      return ' ۩ ۞ $number ';
    }
    return ' ۞ $number ';
  }
}
