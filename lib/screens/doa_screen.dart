// lib/screens/doa_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/data/doa_data.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/utils/tajweed_parser.dart';
import '../../utils/auto_tajweed_parser.dart';

class DoaUIData {
  final List<Ayah> ayahs;
  final DoaItem doaInfo;
  DoaUIData({required this.ayahs, required this.doaInfo});
}

final doaProvider = FutureProvider<List<DoaUIData>>((ref) async {
  final dataService = ref.watch(quranDataServiceProvider);
  // Re-fetch saat bahasa berubah agar translasi ayat dari DB ikut berubah
  ref.watch(settingsProvider); 

  List<DoaUIData> uiDataList = [];
  for (final doaItem in daftarDoaAlQuran) {
    final allAyahsInSurah = await dataService.getAyahsBySurahId(doaItem.surahId);
    
    List<Ayah> fetchedAyahs = [];
    for (final ayahNum in doaItem.ayahs) {
      try {
        final foundAyah = allAyahsInSurah.firstWhere((a) => a.number == ayahNum);
        fetchedAyahs.add(foundAyah);
      } catch (e) {
        continue; // Skip jika tidak ketemu
      }
    }
    if (fetchedAyahs.isNotEmpty) {
      uiDataList.add(DoaUIData(ayahs: fetchedAyahs, doaInfo: doaItem));
    }
  }
  return uiDataList;
});

class DoaScreen extends ConsumerWidget {
  const DoaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 100.0,
              floating: true,
              pinned: true,
              title: Text(lang == 'en' ? 'Qur\'anic Prayers' : 'Doa Al-Qur\'an'),
              centerTitle: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: [
                    Tab(text: lang == 'en' ? 'Prayers' : 'Daftar Doa'),
                    Tab(text: lang == 'en' ? 'Etiquettes' : 'Adab'),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              _DoaList(),
              _AdabList(),
            ],
          ),
        ),
      ),
    );
  }
}
class _DoaList extends ConsumerWidget {
  const _DoaList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final doaAsync = ref.watch(doaProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;

    return doaAsync.when(
      data: (uiDataList) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: uiDataList.length,
          itemBuilder: (context, index) {
            final doaData = uiDataList[index];
            final combinedArabicText = doaData.ayahs.map((a) => a.arabicText).join(' ');
            final combinedTranslation = doaData.ayahs.map((a) => a.translation).join(' ');

            final baseTextStyle = TextStyle(
                fontFamily: 'LPMQ',
                fontSize: settings.arabicFontSize,
                height: 2.0,
                color: theme.colorScheme.onSurface);

            // Gunakan AutoTajweed jika Indonesia, TajweedParser jika Inggris
            final textSpans = lang == 'id'
                ? AutoTajweedParser.parse(
                    combinedArabicText, 
                    baseTextStyle, 
                    lang: lang, 
                    context: context, 
                    learningMode: true
                  )
                : TajweedParser.parse(
                    doaData.ayahs.map((a) => a.tajweedText).join(' '), 
                    baseTextStyle
                  );

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      doaData.doaInfo.getTitle(lang),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: theme.primaryColor.withOpacity(0.03),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(children: textSpans),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          combinedTranslation,
                          textAlign: TextAlign.justify,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Badge(
                              label: Text(doaData.doaInfo.source),
                              backgroundColor: theme.primaryColor.withOpacity(0.1),
                              textColor: theme.primaryColor,
                              largeSize: 24,
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_outward, size: 16),
                              label: Text(lang == 'en' ? 'Context' : 'Konteks'),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => SurahDetailScreen(
                                    surahId: doaData.doaInfo.surahId,
                                    initialScrollIndex: doaData.doaInfo.ayahs.first - 1,
                                  ),
                                ));
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _AdabList extends ConsumerWidget {
  const _AdabList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;
    final theme = Theme.of(context);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: daftarAdabBerdoa.length,
      itemBuilder: (context, index) {
        final adab = daftarAdabBerdoa[index];
        return IntrinsicHeight(
          child: Row(
            children: [
              // Garis Timeline
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                    child: Center(child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                  if (index != daftarAdabBerdoa.length - 1)
                    Expanded(child: VerticalDivider(thickness: 2, color: theme.primaryColor.withOpacity(0.2))),
                ],
              ),
              const SizedBox(width: 16),
              // Konten Adab
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(adab.getTitle(lang), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(adab.getDescription(lang), textAlign: TextAlign.justify, style: TextStyle(color: Colors.grey.shade600, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}