import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:quran_app/providers/surah_header_provider.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/quran_data_service.dart';
import '../../utils/tajweed_parser.dart';
import '../../utils/auto_tajweed_parser.dart';

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
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SettingsModalContent(currentPage: _currentPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final juzAsync = ref.watch(juzFromPageProvider(_currentPage));    
    final surahAsync = ref.watch(surahFromPageProvider(_currentPage));
    final bookmarksMap = ref.watch(bookmarkProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;
    final isPageBookmarked = bookmarksMap.values.any(
      (bookmark) => bookmark.pageNumber == _currentPage,
    );
    final String? existingBookmarkName = isPageBookmarked
      ? bookmarksMap.keys.firstWhere((key) => bookmarksMap[key]?.pageNumber == _currentPage)
      : null;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            surahAsync.when(
              loading: () => _buildHeaderSkeleton(juzAsync),
              error: (_, __) => _buildHeaderSkeleton(juzAsync),
              data: (surahMeta) => _DeresanHeader(
                currentPage: _currentPage,
                juzAsync: juzAsync,
                onBack: () => Navigator.pop(context),
                onTextSize: () => _showSettingsModal(context),                
                surahNumber: surahMeta.number,
                surahNameArabic: surahMeta.nameArabic,
                surahNameLatin: surahMeta.nameLatin,
                surahRevelation: surahMeta.revelation,
                isBookmarked: isPageBookmarked,
                onBookmark: () {
                if (isPageBookmarked && existingBookmarkName != null) {
                  ref.read(bookmarkProvider.notifier).removeBookmark(existingBookmarkName);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        lang == 'en'
                            ? 'Bookmark "$existingBookmarkName" removed'
                            : 'Bookmark "$existingBookmarkName" dihapus',
                      ),
                    ),
                  );
                } else {
                  _showBookmarkDialog(context, ref, _currentPage, lang);
                }
              },
              ),
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

  Widget _buildHeaderSkeleton(AsyncValue<int> juzAsync) {
    return _DeresanHeader(
      currentPage: _currentPage,
      juzAsync: juzAsync,
      onBack: () => Navigator.pop(context),
      onTextSize: () => _showSettingsModal(context),
      surahNumber: 0,
      surahNameArabic: '...',
      surahNameLatin: '...',
      surahRevelation: '...',
      isBookmarked: false,
      onBookmark: () {},
    );
  }
}

class DeresanPage extends ConsumerStatefulWidget {
  final int pageNumber;
  final bool showTafsir;

  const DeresanPage({
    super.key,
    required this.pageNumber,
    required this.showTafsir,
  });

  @override
  ConsumerState<DeresanPage> createState() => _DeresanPageState();
}

class _DeresanPageState extends ConsumerState<DeresanPage> {
  bool _viewPdfMode = false;

  String _formatPageNumber(int number) {
    return number.toString().padLeft(3, '0');
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;
    final source = settings.arabicSource;
    final theme = Theme.of(context);
    final panelFontSize = settings.ayahPanelFontSize;

    final ayahsAsync = ref.watch(pageAyahsProvider(widget.pageNumber));

    return ayahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
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

        if (widget.showTafsir) {
          return Column(
            children: [
              Container(
                color: theme.primaryColor.withOpacity(0.05),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: Text(lang == 'en' ? 'Text Tafsir' : 'Teks Tafsir'),
                      selected: !_viewPdfMode,
                      onSelected: (selected) {
                        if (selected) setState(() => _viewPdfMode = false);
                      },
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: Text(lang == 'en' ? 'View PDF' : 'Lihat PDF'),
                      selected: _viewPdfMode,
                      onSelected: (selected) {
                        if (selected) setState(() => _viewPdfMode = true);
                      },
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _viewPdfMode
                    ? PdfViewer.asset(
                        'assets/pdf/${_formatPageNumber(widget.pageNumber)}.pdf',
                        params: const PdfViewerParams(
                          panEnabled: true,
                          maxScale: 3.0,
                        ),
                      )
                    : SingleChildScrollView(
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
                                    style: TextStyle(
                                      height: 1.6,
                                      fontSize: panelFontSize,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              )
            ],
          );
        }

        final List<Widget> pageWidgets = [];
        List<InlineSpan> currentSpans = [];

        final baseTextStyle = TextStyle(
          fontFamily: 'LPMQ',
          fontSize: panelFontSize,
          height: 2.0,
          color: theme.colorScheme.onSurface,
        );

        // ignore: non_constant_identifier_names
        final UstmaniTextStyle = TextStyle(
          fontFamily: 'Uthmani',
          fontSize: panelFontSize,
          height: 2.0,
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
            if (ayah.surahId != 9 && ayah.number == 1) {
              pageWidgets.add(_BismillahWidget(fontSize: panelFontSize));
            }
          }

          final spans = switch (source) {
            ArabicSource.quranCloudTajweed => TajweedParser.parse(
              ayah.tajweedText,
              baseTextStyle,
              lang: lang,
              context: context,
              learningMode: true,
            ),
            ArabicSource.kemenagTajweed => AutoTajweedParser.parse(
              ayah.ayaTextKemenag,
              baseTextStyle,
              lang: lang,
              context: context,
              learningMode: true,
            ),
            ArabicSource.quranCloud => TajweedParser.parse(
              ayah.tajweedText,
              UstmaniTextStyle,
              lang: lang,
              context: context,
              learningMode: false,
            ),
            ArabicSource.kemenag => [
              TextSpan(text: ayah.ayaTextKemenag, style: baseTextStyle),
            ],
          };

          currentSpans.addAll(spans);
          currentSpans.add(const TextSpan(text: ' '));
          currentSpans.add(buildAyahNumberSpan(context, ayah, panelFontSize));
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
  final VoidCallback onTextSize;
  final int surahNumber;         
  final String surahNameArabic;
  final String surahNameLatin;
  final String surahRevelation;  
  final bool isBookmarked;       
  final VoidCallback onBookmark; 

  const _DeresanHeader({
    required this.currentPage,
    required this.juzAsync,
    required this.onBack,
    required this.onTextSize,
    required this.surahNumber,
    required this.surahNameArabic,
    required this.surahNameLatin,
    required this.surahRevelation,
    required this.isBookmarked,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;    
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: onBack,
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lang == 'en' ? 'Page $currentPage' : 'Halaman $currentPage',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.grey.shade900,
                    ),
                  ),
                  juzAsync.when(
                    loading: () => const Text('—', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (juz) => Text(
                      'Juz $juz'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryColor,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),              
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_size, size: 22),
                      onPressed: onTextSize,
                      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                      tooltip: lang == 'en' ? 'Text size' : 'Ukuran teks',
                    ),
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border, 
                        size: 22,
                        color: isBookmarked ? Colors.green.shade600 : null,
                      ),
                      onPressed: onBookmark,
                      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                      tooltip: lang == 'en' ? 'Bookmark' : 'Simpan penanda',
                    ),
                    Container(width: 1, height: 20, color: isDark ? Colors.white24 : Colors.grey.shade300),
                    PopupMenuButton<ArabicSource>(
                      icon: const Icon(Icons.menu_book_outlined, size: 22),
                      onSelected: (value) => ref.read(settingsProvider.notifier).setArabicSource(value),
                      itemBuilder: (context) => _buildSourceMenu(settings),
                    ),
                    PopupMenuButton<AppThemeType>(
                      icon: const Icon(Icons.palette_outlined, size: 22),
                      onSelected: (value) => ref.read(settingsProvider.notifier).setTheme(value),
                      itemBuilder: (context) => _buildThemeMenu(settings),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark 
                    ? [Colors.grey.shade900, Colors.grey.shade50] 
                    : [Colors.grey.shade50, Colors.white],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$surahNumber',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isMeccan(surahRevelation) 
                              ? Colors.orange.withOpacity(0.1) 
                              : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _getTranslatedRevelation(surahRevelation, lang),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _isMeccan(surahRevelation) 
                                ? Colors.orange.shade800 
                                : Colors.blue.shade800,
                        ),
                      ),
                    ),
                    ],
                  ),
                ),                
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        surahNameLatin, 
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green.shade300 : Colors.green.shade800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  flex: 2,
                  child: Text(
                    surahNameArabic,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'LPMQ',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi evaluasi tempat turun surah
  bool _isMeccan(String type) => type.toLowerCase().contains('mecca') || type.toLowerCase().contains('makki');

  String _getTranslatedRevelation(String type, String lang) {
    if (lang == 'en') {
      return _isMeccan(type) ? 'Meccan' : 'Medinan';
    } else {
      return _isMeccan(type) ? 'Makkiyah' : 'Madaniyah';
    }
  }

  List<PopupMenuEntry<ArabicSource>> _buildSourceMenu(dynamic settings) => [
    CheckedPopupMenuItem(
      value: ArabicSource.quranCloudTajweed,
      checked: settings.arabicSource == ArabicSource.quranCloudTajweed,
      child: const Text('Quran Cloud Tajweed'),
    ),
    CheckedPopupMenuItem(
      value: ArabicSource.kemenagTajweed,
      checked: settings.arabicSource == ArabicSource.kemenagTajweed,
      child: const Text('KEMENAG RI Tajweed'),
    ),
    CheckedPopupMenuItem(
      value: ArabicSource.quranCloud,
      checked: settings.arabicSource == ArabicSource.quranCloud,
      child: const Text('Quran Cloud'),
    ),
    CheckedPopupMenuItem(
      value: ArabicSource.kemenag,
      checked: settings.arabicSource == ArabicSource.kemenag,
      child: const Text('KEMENAG RI'),
    ),
  ];

  List<PopupMenuEntry<AppThemeType>> _buildThemeMenu(dynamic settings) => [
    CheckedPopupMenuItem(
      value: AppThemeType.light,
      checked: settings.theme == AppThemeType.light,
      child: const Text('Light Theme'),
    ),
    CheckedPopupMenuItem(
      value: AppThemeType.dark,
      checked: settings.theme == AppThemeType.dark,
      child: const Text('Dark Theme'),
    ),
    CheckedPopupMenuItem(
      value: AppThemeType.pink,
      checked: settings.theme == AppThemeType.pink,
      child: const Text('Pink Theme'),
    ),
  ];
}

class SettingsModalContent extends ConsumerWidget {
  final int currentPage;
  const SettingsModalContent({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang == 'en' ? 'Arabic Font Size' : 'Ukuran Font Arab',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: settings.ayahPanelFontSize,
              min: 12,
              max: 56,
              divisions: 44,
              label: settings.ayahPanelFontSize.round().toString(),
              onChanged:
                  (value) => ref
                      .read(settingsProvider.notifier)
                      .setAyahPanelFontSize(value),
            ),
          ],
        ),
      ),
    );
  }

}

TextSpan buildAyahNumberSpan(
  BuildContext context,
  dynamic ayah,
  double fontSize,
) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final arabicNumber =
      ayah.number.toString().split('').map((e) => digits[int.parse(e)]).join();

  final text = ayah.isSajda ? ' ۩ ﴿$arabicNumber﴾ ' : ' ﴿$arabicNumber﴾ ';

  return TextSpan(
    text: '\u202B$text\u202C',
    style: TextStyle(
      fontFamily: 'LPMQ',
      fontSize: fontSize * 0.85,
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
      letterSpacing: 1,
    ),
  );
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
        height: 64,
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