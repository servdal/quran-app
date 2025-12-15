import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/surah_detail_data.dart';
import '../providers/bookmark_provider.dart';
import '../providers/settings_provider.dart';
import '../services/quran_data_service.dart';
import '../widgets/ayah_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

final surahDetailProvider =
    FutureProvider.family<SurahDetailData, int>((ref, surahId) {
  return ref.watch(quranDataServiceProvider).getSurahDetail(surahId);
});

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
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    
    if (widget.initialScrollIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (itemScrollController.isAttached) {
          final index = widget.initialScrollIndex!;
          if (index >= 0) {
            itemScrollController.jumpTo(
              index: index,
              alignment: 0.1,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahDetailAsync = ref.watch(surahDetailProvider(widget.surahId));

    return Scaffold(
      appBar: AppBar(
        title: surahDetailAsync.when(
          data: (surah) => Text(
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
            onPressed: () => _showFontSizeSlider(context, ref),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: surahDetailAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Gagal memuat surah: $error')),
                data: (surah) {
                  
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
        )
      ),
    );
  }

  void _showFontSizeSlider(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            final settings = ref.watch(settingsProvider);
            final currentFontSize = settings.arabicFontSize;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ukuran Font Teks Arab'),
                  Slider(
                    value: currentFontSize,
                    min: 20,
                    max: 48,
                    divisions: 14,
                    label: currentFontSize.round().toString(),
                    onChanged: (double value) {
                      ref.read(settingsProvider.notifier).setFontSize(value);
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
                    builder: (context) => SurahDetailScreen(surahId: currentSurahId + 1),
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
                    builder: (context) => SurahDetailScreen(surahId: currentSurahId - 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

