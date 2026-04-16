import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmark_provider.dart';
import '../providers/settings_provider.dart';
import '../services/quran_data_service.dart';
import '../widgets/ayah_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class SurahDetailScreen extends ConsumerStatefulWidget {
  final int surahId;
  final int? initialScrollIndex;

  const SurahDetailScreen({
    super.key,
    required this.surahId,
    this.initialScrollIndex,
  });

  @override
  ConsumerState<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends ConsumerState<SurahDetailScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  bool _didInitialScroll = false;

  @override
  void initState() {
    super.initState();
  }

  void _jumpToInitialIndexIfNeeded(int ayahCount) {
    if (_didInitialScroll || widget.initialScrollIndex == null) {
      return;
    }

    final rawIndex = widget.initialScrollIndex!;
    if (rawIndex < 0 || ayahCount == 0) {
      return;
    }

    final safeIndex = rawIndex.clamp(0, ayahCount - 1).toInt();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !itemScrollController.isAttached || _didInitialScroll) {
        return;
      }

      itemScrollController.jumpTo(index: safeIndex, alignment: 0.1);
      _didInitialScroll = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final surahDetailAsync = ref.watch(surahDetailProvider(widget.surahId));

    return Scaffold(
      appBar: AppBar(
        title: surahDetailAsync.when(
          data:
              (surah) => Text(
                surah.surahName,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                ),
              ),
          loading: () => const Text('Memuat...'),
          error: (e, s) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            onPressed: () => _showPanelFontSizeSlider(context, ref),
          ),
          PopupMenuButton<ArabicSource>(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip:
                settings.language == 'id'
                    ? 'Sumber teks Arab'
                    : 'Arabic text source',
            onSelected:
                (value) =>
                    ref.read(settingsProvider.notifier).setArabicSource(value),
            itemBuilder:
                (context) => [
                  CheckedPopupMenuItem(
                    value: ArabicSource.quranCloudTajweed,
                    checked:
                        settings.arabicSource ==
                        ArabicSource.quranCloudTajweed,
                    child: const Text('Quran Cloud Tajweed'),
                  ),
                  CheckedPopupMenuItem(
                    value: ArabicSource.kemenagTajweed,
                    checked:
                        settings.arabicSource == ArabicSource.kemenagTajweed,
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
                ],
          ),
          PopupMenuButton<AppThemeType>(
            icon: const Icon(Icons.palette_outlined),
            tooltip:
                settings.language == 'id'
                    ? 'Tema tampilan'
                    : 'App theme',
            onSelected:
                (value) => ref.read(settingsProvider.notifier).setTheme(value),
            itemBuilder:
                (context) => [
                  CheckedPopupMenuItem(
                    value: AppThemeType.light,
                    checked: settings.theme == AppThemeType.light,
                    child: const Text('Light'),
                  ),
                  CheckedPopupMenuItem(
                    value: AppThemeType.dark,
                    checked: settings.theme == AppThemeType.dark,
                    child: const Text('Dark'),
                  ),
                  CheckedPopupMenuItem(
                    value: AppThemeType.pink,
                    checked: settings.theme == AppThemeType.pink,
                    child: const Text('Pink'),
                  ),
                ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: surahDetailAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stack) =>
                        Center(child: Text('Gagal memuat surah: $error')),
                data: (surah) {
                  _jumpToInitialIndexIfNeeded(surah.ayahs.length);

                  return ScrollablePositionedList.builder(
                    itemCount: surah.ayahs.length,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: AyahWidget(
                          ayah: surah.ayahs[index],
                          viewType: BookmarkViewType.surah,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            _buildSurahNavigation(context, widget.surahId),
          ],
        ),
      ),
    );
  }

  void _showPanelFontSizeSlider(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final settings = ref.watch(settingsProvider);
            final currentFontSize = settings.ayahPanelFontSize;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    settings.language == 'id'
                        ? 'Ukuran Font Teks Panel'
                        : 'Panel Text Font Size',
                  ),
                  Slider(
                    value: currentFontSize,
                    min: 12,
                    max: 56,
                    divisions: 44,
                    label: currentFontSize.round().toString(),
                    onChanged: (double value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setAyahPanelFontSize(value);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSurahNavigation(BuildContext context, int currentSurahId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (currentSurahId < 114)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text(' '),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SurahDetailScreen(surahId: currentSurahId + 1),
                  ),
                );
              },
            ),
          const Spacer(),
          if (currentSurahId > 1)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text(' '),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            SurahDetailScreen(surahId: currentSurahId - 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
