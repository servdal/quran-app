import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/quran_data_service.dart';
import '../../utils/tajweed_parser.dart';
import '../../utils/auto_tajweed_parser.dart';

class DeresanViewScreen extends ConsumerStatefulWidget {
  final int initialPage;

  const DeresanViewScreen({super.key, required this.initialPage});

  @override
  ConsumerState<DeresanViewScreen> createState() => _DeresanViewScreenState();
}

class _DeresanViewScreenState extends ConsumerState<DeresanViewScreen> {
  late final PageController _pageController;
  late int _currentPage;
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
    final juzAsync = ref.watch(juzFromPageProvider(_currentPage));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _DeresanHeader(
              currentPage: _currentPage,
              juzAsync: juzAsync,
              onBack: () => Navigator.pop(context),
              onMore: () => _showSettingsModal(context),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (velocity > 300 && _currentPage < 604) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  } else if (velocity < -300 && _currentPage > 1) {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                  }
                },
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
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        elevation: 4,
        backgroundColor: Colors.grey.shade300,
        onPressed: () => setState(() => _showTafsir = !_showTafsir),
        child: Icon(
          _showTafsir ? Icons.menu_book : Icons.import_contacts,
          color: Colors.black,
          size: 28,
        ),
      ),

      bottomNavigationBar: _DeresanBottomBar(controller: _pageController),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;
    final theme = Theme.of(context);

    final ayahsAsync = ref.watch(pageAyahsProvider(pageNumber));

    return ayahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (e, _) => Center(
            child: Text(
              lang == 'en' ? 'Failed to load page' : 'Gagal memuat halaman',
            ),
          ),
      data: (ayahs) {
        if (ayahs.isEmpty) {
          return Center(
            child: Text(lang == 'en' ? 'No data found' : 'Tidak ada data.'),
          );
        }

        if (showTafsir) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  ayahs.map((ayah) {
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
                            style: const TextStyle(height: 1.6, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          );
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

          final spans =
              lang == 'id'
                  ? AutoTajweedParser.parse(
                    ayah.arabicText,
                    baseTextStyle,
                    lang: lang,
                    context: context,
                    learningMode: true,
                  )
                  : TajweedParser.parse(ayah.tajweedText, baseTextStyle);

          currentSpans.addAll(spans);
          currentSpans.add(const TextSpan(text: ' '));
          currentSpans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AyahOrnamentalNumber(
                number: ayah.number,
                fontSize: settings.arabicFontSize,
                hasSajda: ayah.isSajda,
              ),
            ),
          );
          currentSpans.add(const TextSpan(text: ' '));
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

class _DeresanHeader extends ConsumerWidget {
  final int currentPage;
  final AsyncValue<int> juzAsync;
  final VoidCallback onBack;
  final VoidCallback onMore;

  const _DeresanHeader({
    required this.currentPage,
    required this.juzAsync,
    required this.onBack,
    required this.onMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
              juzAsync.when(
                loading:
                    () => const SizedBox(
                      width: 60,
                      child: Text('—', style: TextStyle(color: Colors.grey)),
                    ),
                error: (_, __) => const SizedBox.shrink(),
                data:
                    (juz) => Text(
                      lang == 'en' ? 'Juz $juz' : 'Juz $juz',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
              ),
              const Spacer(),
              Text(
                lang == 'en' ? 'Page $currentPage' : 'Halaman $currentPage',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),
              IconButton(icon: const Icon(Icons.more_vert), onPressed: onMore),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsModalContent extends ConsumerWidget {
  final int currentPage;
  const SettingsModalContent({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang == 'en' ? 'Arabic Font Size' : 'Ukuran Font Arab',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: settings.arabicFontSize,
            min: 18,
            max: 40,
            divisions: 22,
            label: settings.arabicFontSize.round().toString(),
            onChanged:
                (value) =>
                    ref.read(settingsProvider.notifier).setFontSize(value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bookmark_add),
              label: Text(
                lang == 'en' ? 'Bookmark This Page' : 'Tandai Halaman Ini',
              ),
              onPressed:
                  () => _showBookmarkDialog(context, ref, currentPage, lang),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookmarkDialog(
    BuildContext context,
    WidgetRef ref,
    int currentPage,
    String lang,
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
          title: Text(
            lang == 'en' ? 'Bookmark Classic Page' : 'Tandai Halaman Klasik',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText:
                        lang == 'en'
                            ? 'New Bookmark Name'
                            : 'Nama Bookmark Baru',
                    hintText:
                        lang == 'en'
                            ? 'e.g., Night Tahsin'
                            : 'Contoh: Tahsin Malam',
                  ),
                ),
                if (existingNames.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    lang == 'en'
                        ? 'Or overwrite existing:'
                        : 'Atau timpa yang sudah ada:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                          subtitle:
                              bookmark.pageNumber != null
                                  ? Text(
                                    lang == 'en'
                                        ? 'Page ${bookmark.pageNumber}'
                                        : 'Halaman ${bookmark.pageNumber}',
                                  )
                                  : null,
                          onTap: () async {
                            final newBookmark = Bookmark(
                              type: BookmarkViewType.classic,
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
                                  lang == 'en'
                                      ? 'Bookmark "$name" updated'
                                      : 'Bookmark "$name" diperbarui',
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
              child: Text(lang == 'en' ? 'Cancel' : 'Batal'),
            ),
            ElevatedButton(
              child: Text(lang == 'en' ? 'Save New' : 'Simpan Baru'),
              onPressed: () async {
                final name = textController.text.trim();
                if (name.isEmpty) return;
                final newBookmark = Bookmark(
                  type: BookmarkViewType.classic,
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
                      lang == 'en'
                          ? 'Bookmark "$name" saved'
                          : 'Bookmark "$name" disimpan',
                    ),
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
  final int number;
  final double fontSize;
  final bool hasSajda;

  const AyahOrnamentalNumber({
    super.key,
    required this.number,
    required this.fontSize,
    this.hasSajda = false,
  });

  String _toArabicNumber(int input) {
    const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.toString().split('').map((d) {
      final parsed = int.tryParse(d);
      return parsed != null ? digits[parsed] : d;
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final arabicNumber = _toArabicNumber(number);

    return Text(
      hasSajda
          ? '\u202B ۩ ۞ $arabicNumber \u202C'
          : '\u202B ۞ $arabicNumber \u202C',
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Uthmani',
        fontSize: fontSize,
        color: color,
      ),
    );
  }
}

class _BismillahWidget extends StatelessWidget {
  final double fontSize;

  const _BismillahWidget({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: Icon(
              Icons.star_outline,
              size: 12,
              color: primaryColor.withOpacity(0.3),
            ),
          ),
          Positioned(
            right: 0,
            child: Icon(
              Icons.star_outline,
              size: 12,
              color: primaryColor.withOpacity(0.3),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
            child: Text(
              '\uFD3F بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ \uFD3E',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'LPMQ',
                fontSize: fontSize * 0.8,
                color: theme.colorScheme.onSurface,
                height: 1.5,
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 2.0,
                    color: Colors.black.withOpacity(0.1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahHeaderWidget extends StatelessWidget {
  final String surahName;

  const _SurahHeaderWidget({required this.surahName});

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
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}

class _DeresanBottomBar extends StatelessWidget {
  final PageController controller;

  const _DeresanBottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      color: Colors.grey.shade300,
      elevation: 8,
      child: SizedBox(
        height: 64, // ⬅️ cukup tinggi untuk FAB 56
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: IconButton(
                iconSize: 28,
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
              padding: const EdgeInsets.only(right: 48),
              child: IconButton(
                iconSize: 28,
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
