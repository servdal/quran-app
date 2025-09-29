import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/data/dzikr_data.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

enum DzikrType { pagi, petang }

class DzikrUIData {
  final List<Ayah> ayahs;
  final DzikrItem dzikrInfo;
  final String surahName;

  DzikrUIData({
    required this.ayahs,
    required this.dzikrInfo,
    required this.surahName,
  });
}

final dzikrProvider = FutureProvider.family<List<DzikrUIData>, DzikrType>((ref, type) async {
  final dataService = ref.watch(quranDataServiceProvider);
  final dzikrItems = (type == DzikrType.pagi) ? dzikirPagiList : dzikirPetangList;

  // HAPUS: await dataService.loadAllSurahData();

  List<DzikrUIData> uiDataList = [];
  for (final item in dzikrItems) {
    final allAyahsInSurah = await dataService.getAyahsBySurahId(item.surahId);
    
    List<Ayah> fetchedAyahs = [];
    // ... sisa logika loop tidak berubah ...

    // Untuk getSurahNameById, kita perlu pendekatan berbeda karena data lengkap tidak dimuat
    // Untuk sementara, kita akan gunakan ID Surah saja.
    uiDataList.add(DzikrUIData(
      ayahs: fetchedAyahs,
      dzikrInfo: item,
      surahName: "QS. ${item.surahId}", // Perubahan sementara
    ));
  }
  return uiDataList;
});


class DzikirScreen extends ConsumerWidget {
  final DzikrType type;

  const DzikirScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = (type == DzikrType.pagi) ? "Dzikir Pagi" : "Dzikir Petang";
    final dzikrAsync = ref.watch(dzikrProvider(type));
    final arabicFontSize = ref.watch(settingsProvider).arabicFontSize;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: dzikrAsync.when(
        data: (uiDataList) {
          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: uiDataList.length,
            itemBuilder: (context, index) {
              final uiData = uiDataList[index];
              final combinedTajweedText = uiData.ayahs.map((a) => a.tajweedText).join(' ');
              final baseTextStyle = TextStyle(
                  fontFamily: 'LPMQ', 
                  fontSize: arabicFontSize,
                  height: 2.2,
                  color: Theme.of(context).colorScheme.onSurface);
              final textSpans = TajweedParser.parse(combinedTajweedText, baseTextStyle);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uiData.dzikrInfo.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Dibaca ${uiData.dzikrInfo.repetitions}x",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                      ),
                      const Divider(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: RichText(
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            style: baseTextStyle,
                            children: textSpans,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => SurahDetailScreen(
                                surahId: uiData.ayahs.first.suraId,
                                initialScrollIndex: uiData.ayahs.first.ayaNumber - 1,
                              ),
                            ));
                          }, 
                          child: Text('Lihat di Surah ${uiData.surahName}'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Gagal memuat data dzikir: $error'),
        ),
      ),
    );
  }
}