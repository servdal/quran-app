// dzikir_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/data/dzikr_data.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

enum DzikrType { pagi, petang }

// Parameter untuk provider
class DzikrProviderParams {
  final DzikrType type;
  final bool isLengkap;

  DzikrProviderParams({required this.type, required this.isLengkap});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DzikrProviderParams &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          isLengkap == other.isLengkap;

  @override
  int get hashCode => type.hashCode ^ isLengkap.hashCode;
}


class DzikrUIData {
  final List<Ayah> ayahs;
  final DzikrItem dzikrInfo;
  final String surahName;
  final String arabicText; // Teks Arab terpadu (dari Qur'an atau Hadits)

  DzikrUIData({
    required this.ayahs,
    required this.dzikrInfo,
    required this.surahName,
    required this.arabicText,
  });
}

// Provider diubah untuk menerima parameter object
final dzikrProvider =
    FutureProvider.family<List<DzikrUIData>, DzikrProviderParams>((ref, params) async {
  final dataService = ref.watch(quranDataServiceProvider);
  
  // Pilih list berdasarkan parameter
  List<DzikrItem> dzikrItems;
  if (params.type == DzikrType.pagi) {
    dzikrItems = params.isLengkap ? dzikirPagiLengkapList : dzikirPagiList;
  } else {
    dzikrItems = params.isLengkap ? dzikirPetangLengkapList : dzikirPetangList;
  }
  
  final allSurahIndex = await ref.watch(allSurahsProvider.future);
  final surahNameMap = {for (var surah in allSurahIndex) surah.suraId: surah.englishName};

  List<DzikrUIData> uiDataList = [];
  for (final item in dzikrItems) {
    List<Ayah> fetchedAyahs = [];
    String arabicText = '';
    String surahName = '';

    // Jika dzikir dari Al-Qur'an (punya surahId)
    if (item.surahId != null) {
      final allAyahsInSurah = await dataService.getAyahsBySurahId(item.surahId!);
      
      if (item.isFullSurah) {
        fetchedAyahs = allAyahsInSurah;
      } else if (item.ayahNumber != null) {
        fetchedAyahs = allAyahsInSurah.where((ayah) => ayah.ayaNumber == item.ayahNumber).toList();
      }
      
      arabicText = fetchedAyahs.map((a) => a.tajweedText).join(' ');
      surahName = surahNameMap[item.surahId] ?? "QS. ${item.surahId}";
    } 
    // Jika dzikir dari Hadits (punya arabicText)
    else if (item.arabicText != null) {
      arabicText = item.arabicText!;
      surahName = "Hadits"; // Atau sumber lain
    }

    uiDataList.add(DzikrUIData(
      ayahs: fetchedAyahs,
      dzikrInfo: item,
      surahName: surahName,
      arabicText: arabicText,
    ));
  }
  return uiDataList;
});

class DzikirScreen extends ConsumerStatefulWidget {
  final DzikrType type;
  const DzikirScreen({super.key, required this.type});

  @override
  ConsumerState<DzikirScreen> createState() => _DzikirScreenState();
}

class _DzikirScreenState extends ConsumerState<DzikirScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final title = (widget.type == DzikrType.pagi) ? "Dzikir Pagi" : "Dzikir Petang";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Berdasarkan Al-Qur'an"),
            Tab(text: "Al-Qur'an & Hadits"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Hanya Al-Qur'an
          DzikirListView(
            params: DzikrProviderParams(type: widget.type, isLengkap: false),
          ),
          // Tab 2: Al-Qur'an dan Hadits
          DzikirListView(
            params: DzikrProviderParams(type: widget.type, isLengkap: true),
          ),
        ],
      ),
    );
  }
}


// Widget terpisah untuk menampilkan list agar tidak duplikasi kode
class DzikirListView extends ConsumerWidget {
  final DzikrProviderParams params;

  const DzikirListView({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dzikrAsync = ref.watch(dzikrProvider(params));
    final arabicFontSize = ref.watch(settingsProvider).arabicFontSize;

    return dzikrAsync.when(
      data: (uiDataList) {
        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: uiDataList.length,
          itemBuilder: (context, index) {
            final uiData = uiDataList[index];
            if (uiData.dzikrInfo.title.isEmpty) return const SizedBox.shrink();

            final baseTextStyle = TextStyle(
                fontFamily: 'LPMQ',
                fontSize: arabicFontSize,
                height: 2.2,
                color: Theme.of(context).colorScheme.onSurface);
            
            // Menggunakan arabicText yang sudah diproses di provider
            final textSpans = TajweedParser.parse(uiData.arabicText, baseTextStyle);

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      uiData.dzikrInfo.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Dibaca ${uiData.dzikrInfo.repetitions}x",
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const Divider(height: 24),
                    if (textSpans.isNotEmpty)
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
                    
                    // Tombol hanya muncul jika dzikir berasal dari Al-Qur'an
                    if (uiData.ayahs.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SurahDetailScreen(
                                    surahId: uiData.ayahs.first.suraId,
                                    initialScrollIndex:
                                        uiData.ayahs.first.ayaNumber - 1,
                                  ),
                                ));
                          },
                          child: Text('Lihat di ${uiData.surahName}'),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Gagal memuat data dzikir:\n$error', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}