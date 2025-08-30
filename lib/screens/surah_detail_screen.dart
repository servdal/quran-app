import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/widgets/ayah_widget.dart';

// Provider untuk mengambil data detail satu surah
final surahDetailProvider = FutureProvider.family<Surah?, int>((ref, surahId) async {
  final service = ref.read(quranDataServiceProvider);
  // Pastikan semua data sudah dimuat sebelum mencari
  await service.loadAllSurahData();
  try {
    // Cari surah yang sesuai berdasarkan ID
    return service.getAllSurahs().firstWhere((s) => s.suraId == surahId);
  } catch (e) {
    // Jika tidak ditemukan, kembalikan null
    return null;
  }
});

class SurahDetailScreen extends ConsumerWidget {
  final int surahId;
  const SurahDetailScreen({super.key, required this.surahId});

  // Fungsi untuk navigasi ke surah lain (sebelumnya atau berikutnya)
  void _navigateToSurah(BuildContext context, int newSurahId) {
    // Pastikan ID surah valid (antara 1 dan 114)
    if (newSurahId >= 1 && newSurahId <= 114) {
      // Gunakan pushReplacement agar tidak menumpuk halaman di stack navigasi
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SurahDetailScreen(surahId: newSurahId)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahDetailAsync = ref.watch(surahDetailProvider(surahId));
    // Membaca state dan notifier dari provider pengaturan font
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: surahDetailAsync.when(
          data: (surah) => Text(surah?.englishName ?? 'Memuat...'),
          loading: () => const Text('Memuat...'),
          error: (e, s) => const Text('Error'),
        ),
        actions: [
          // Tombol untuk membuka menu slider font
          PopupMenuButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Ubah Ukuran Font',
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false, // Agar item tidak bisa diklik
                child: SizedBox(
                  width: 250, // Lebar menu popup
                  child: Column(
                    children: [
                      const Text('Ukuran Font Arab'),
                      Slider(
                        value: settings.arabicFontSize,
                        min: 20.0,
                        max: 48.0,
                        divisions: 14, // Jumlah step
                        label: settings.arabicFontSize.round().toString(),
                        onChanged: (value) {
                          // Panggil fungsi untuk update font size di provider
                          settingsNotifier.setFontSize(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: surahDetailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Gagal memuat surah: $error')),
        data: (surah) {
          if (surah == null) {
            return const Center(child: Text('Surah tidak ditemukan'));
          }
          // Tampilan utama
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: surah.ayahs.length,
                  itemBuilder: (context, index) {
                    return AyahWidget(
                      ayah: surah.ayahs[index],
                      viewType: BookmarkViewType.surah, // Tandai bookmark dari surah view
                    );
                  },
                ),
              ),
              // Tombol navigasi di bagian bawah
              _buildSurahControls(context),
            ],
          );
        },
      ),
    );
  }

  // Widget untuk tombol navigasi surah
  Widget _buildSurahControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Sebelumnya'),
            // Tombol nonaktif jika ini surah pertama (Al-Fatihah)
            onPressed: surahId > 1 ? () => _navigateToSurah(context, surahId - 1) : null,
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Berikutnya'),
            // Tombol nonaktif jika ini surah terakhir (An-Nas)
            onPressed: surahId < 114 ? () => _navigateToSurah(context, surahId + 1) : null,
          ),
        ],
      ),
    );
  }
}

