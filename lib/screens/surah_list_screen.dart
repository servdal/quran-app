import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/services/quran_data_service.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menggunakan provider untuk mendapatkan data semua surah secara asynchronous
    final allSurahsAsyncValue = ref.watch(allSurahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Surah'),
      ),
      body: allSurahsAsyncValue.when(
        // Tampilan saat data sedang dimuat
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        // Tampilan jika terjadi error
        error: (error, stackTrace) => Center(
          child: Text('Gagal memuat data: $error'),
        ),
        // Tampilan saat data berhasil dimuat
        data: (surahs) {
          return ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return _SurahListItem(surah: surah);
            },
          );
        },
      ),
    );
  }
}

// Widget kustom untuk setiap item dalam daftar surah
class _SurahListItem extends StatelessWidget {
  const _SurahListItem({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    // Mengambil data tema saat ini untuk pewarnaan dinamis
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(surahId: surah.suraId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Bagian Nomor Surah
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.primaryColor, width: 1),
                ),
                child: Center(
                  child: Text(
                    surah.suraId.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Bagian Info Surah (Nama Latin, Tipe, Jumlah Ayat)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.englishName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface, // Warna teks utama
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.revelationType} • ${surah.ayahs.length} Ayat',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color, // Warna teks sekunder
                      ),
                    ),
                  ],
                ),
              ),
              // Bagian Nama Arab
              Text(
                surah.name,
                style: TextStyle(
                  fontFamily: 'LPMQ',
                  fontSize: 22,
                  color: theme.primaryColor, // Warna aksen hijau
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

