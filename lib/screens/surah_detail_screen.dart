import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/widgets/ayah_widget.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

final surahDetailProvider = FutureProvider.family<Surah?, int>((ref, surahId) async {
  final service = ref.read(quranDataServiceProvider);
  await service.loadAllSurahData();
  try {
    return service.getAllSurahs().firstWhere((s) => s.suraId == surahId);
  } catch (e) {
    return null;
  }
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
          itemScrollController.jumpTo(
            index: widget.initialScrollIndex!,
            alignment: 0.1,
          );
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
          data: (surah) => Text(surah?.englishName ?? 'Memuat...'),
          loading: () => const Text('Memuat...'),
          error: (e, s) => const Text('Error'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            // Panggil fungsi tanpa argumen 'currentSize'
            onPressed: () => _showFontSizeSlider(context, ref),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: surahDetailAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Gagal memuat surah: $error')),
              data: (surah) {
                if (surah == null) {
                  return const Center(child: Text('Surah tidak ditemukan'));
                }
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
    );
  }

  // #### FUNGSI SLIDER DIPERBAIKI DI SINI ####
  void _showFontSizeSlider(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        // Menggunakan Consumer agar UI di dalam bottom sheet
        // "mendengarkan" perubahan pada provider.
        return Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
            // Membaca (watch) state terbaru dari provider SETIAP KALI ada perubahan.
            final settings = ref.watch(settingsProvider);
            final currentFontSize = settings.arabicFontSize;

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ukuran Font Teks Arab'),
                  Slider(
                    // Nilai slider sekarang selalu mengambil dari state terbaru provider.
                    value: currentFontSize,
                    min: 20,
                    max: 48,
                    divisions: 14,
                    label: currentFontSize.round().toString(),
                    onChanged: (double value) {
                      // Saat digeser, panggil notifier untuk mengubah state.
                      // Perubahan ini akan dideteksi oleh ref.watch() di atas,
                      // sehingga UI slider akan diperbarui secara otomatis.
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
          if (currentSurahId > 1)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Sebelumnya'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahDetailScreen(surahId: currentSurahId - 1),
                  ),
                );
              },
            ),
          const Spacer(),
          if (currentSurahId < 114)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Berikutnya'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SurahDetailScreen(surahId: currentSurahId + 1),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

