// lib/screens/doa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/data/doa_data.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/settings_provider.dart'; // Import settings provider
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/utils/tajweed_parser.dart'; // Import Tajweed Parser

class DoaUIData {
  final List<Ayah> ayahs;
  final DoaItem doaInfo;
  DoaUIData({required this.ayahs, required this.doaInfo});
}

final doaProvider = FutureProvider<List<DoaUIData>>((ref) async {
  final dataService = ref.watch(quranDataServiceProvider);
  // HAPUS: await dataService.loadAllSurahData();
  
  List<DoaUIData> uiDataList = [];
  for (final doaItem in daftarDoaAlQuran) {
    // getAyahsBySurahId sekarang sudah cukup
    final allAyahsInSurah = await dataService.getAyahsBySurahId(doaItem.surahId);
    
    List<Ayah> fetchedAyahs = [];
    for (final ayahNum in doaItem.ayahs) {
      try {
        final foundAyah = allAyahsInSurah.firstWhere((a) => a.ayaNumber == ayahNum);
        fetchedAyahs.add(foundAyah);
      } catch (e) {
        print("Ayat tidak ditemukan: Surah ${doaItem.surahId} Ayat $ayahNum");
      }
    }
    if (fetchedAyahs.isNotEmpty) {
      uiDataList.add(DoaUIData(ayahs: fetchedAyahs, doaInfo: doaItem));
    }
  }
  return uiDataList;
});

class DoaScreen extends StatelessWidget {
  const DoaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kumpulan Doa'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daftar Doa'),
              Tab(text: 'Adab Berdoa'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DoaList(),
            _AdabList(),
          ],
        ),
      ),
    );
  }
}

// Widget untuk menampilkan daftar doa
class _DoaList extends ConsumerWidget {
  const _DoaList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final doaAsync = ref.watch(doaProvider);
    // Ambil ukuran font dari settings provider
    final arabicFontSize = ref.watch(settingsProvider).arabicFontSize;

    return doaAsync.when(
      data: (uiDataList) {
        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: uiDataList.length,
          itemBuilder: (context, index) {
            final doaData = uiDataList[index];

            // --- PERUBAHAN 1: Gunakan teks bertajwid ---
            final combinedTajweedText = doaData.ayahs.map((a) => a.tajweedText).join(' ');
            final combinedTranslation = doaData.ayahs.map((a) => a.translationAyaText).join(' ');

            // Parsing teks tajwid menjadi RichText
            final baseTextStyle = TextStyle(
                fontFamily: 'LPMQ',
                fontSize: arabicFontSize, // Gunakan font size dari settings
                height: 2.2,
                color: Theme.of(context).colorScheme.onSurface);
            final textSpans = TajweedParser.parse(combinedTajweedText, baseTextStyle);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(doaData.doaInfo.title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const Divider(height: 24),
                    
                    // --- PERUBAHAN 2: Gunakan RichText untuk menampilkan tajwid ---
                    RichText(
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        style: baseTextStyle,
                        children: textSpans,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Text(
                      '"$combinedTranslation"',
                      textAlign: TextAlign.justify,
                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(doaData.doaInfo.source, style: theme.textTheme.bodySmall),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => SurahDetailScreen(
                                surahId: doaData.doaInfo.surahId,
                                initialScrollIndex: doaData.doaInfo.ayahs.first - 1,
                              ),
                            ));
                          },
                          child: const Text('Lihat Konteks Ayat'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Gagal memuat data doa: $error')),
    );
  }
}

// Widget untuk menampilkan daftar adab (tidak ada perubahan)
class _AdabList extends StatelessWidget {
  const _AdabList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: daftarAdabBerdoa.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final adab = daftarAdabBerdoa[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(adab.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(adab.description, textAlign: TextAlign.justify),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
        );
      },
    );
  }
}