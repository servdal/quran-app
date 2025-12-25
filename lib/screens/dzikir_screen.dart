// lib/screens/dzikir_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/data/dzikr_data.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/utils/auto_tajweed_parser.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

enum DzikrType { pagi, petang }

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
  final String arabicText;

  DzikrUIData({
    required this.ayahs,
    required this.dzikrInfo,
    required this.surahName,
    required this.arabicText,
  });
}

final dzikrProvider =
    FutureProvider.family<List<DzikrUIData>, DzikrProviderParams>((ref, params) async {
  final dataService = ref.watch(quranDataServiceProvider);
  // Re-watch settings agar data ter-refresh saat bahasa berubah
  final settings = ref.watch(settingsProvider);
  final lang = settings.language; 

  List<DzikrItem> dzikrItems;
  if (params.type == DzikrType.pagi) {
    dzikrItems = params.isLengkap ? dzikirPagiLengkapList : dzikirPagiList;
  } else {
    dzikrItems = params.isLengkap ? dzikirPetangLengkapList : dzikirPetangList;
  }
  
  final allSurahIndex = await ref.watch(allSurahsProvider.future);
  
  List<DzikrUIData> uiDataList = [];
  for (final item in dzikrItems) {
    List<Ayah> fetchedAyahs = [];
    String arabicText = '';
    String surahName = '';

    if (item.surahId != null) {
      final allAyahsInSurah = await dataService.getAyahsBySurahId(item.surahId!);
      
      if (item.isFullSurah) {
        fetchedAyahs = allAyahsInSurah;
      } else if (item.ayahNumber != null) {
        fetchedAyahs = allAyahsInSurah.where((ayah) => ayah.number == item.ayahNumber).toList();
      }
      
      arabicText = fetchedAyahs.map((a) => a.tajweedText).join(' ');
      
      // Mengambil nama surah berdasarkan bahasa
      final surahInfo = allSurahIndex.firstWhere((s) => s.suraId == item.surahId);
      surahName = lang == 'en' ? surahInfo.nameLatin : surahInfo.nameArabic;
    } 
    else if (item.arabicText != null) {
      arabicText = item.arabicText!;
      surahName = "Hadits"; 
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
  Widget build(BuildContext context) {
    final lang = ref.watch(settingsProvider).language;
    final isMorning = widget.type == DzikrType.pagi;
    
    final title = isMorning 
        ? (lang == 'en' ? "Morning Dzikr" : "Dzikir Pagi")
        : (lang == 'en' ? "Evening Dzikr" : "Dzikir Petang");

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMorning 
                        ? [Colors.orange.shade200, Colors.orange.shade50]
                        : [Colors.indigo.shade300, Colors.indigo.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
                tabs: [
                  Tab(text: lang == 'en' ? "Sunnah" : "Sesuai Sunnah"),
                  Tab(text: lang == 'en' ? "Full Version" : "Versi Lengkap"),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            DzikirListView(params: DzikrProviderParams(type: widget.type, isLengkap: false)),
            DzikirListView(params: DzikrProviderParams(type: widget.type, isLengkap: true)),
          ],
        ),
      ),
    );
  }
}
class DzikirListView extends ConsumerWidget {
  final DzikrProviderParams params;
  const DzikirListView({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dzikrAsync = ref.watch(dzikrProvider(params));
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;

    return dzikrAsync.when(
      data: (uiDataList) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: uiDataList.length,
          itemBuilder: (context, index) {
            final uiData = uiDataList[index];
            final title = uiData.dzikrInfo.getTitle(lang);
            if (title.isEmpty) return const SizedBox.shrink();

            // Animasi Fade In per Item
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 400 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: DzikrCard(uiData: uiData, settings: settings, lang: lang),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, stack) => Center(child: Text('Error: $e')),
    );
  }
}
class DzikrCard extends StatefulWidget {
  final DzikrUIData uiData;
  final dynamic settings;
  final String lang;

  const DzikrCard({super.key, required this.uiData, required this.settings, required this.lang});

  @override
  State<DzikrCard> createState() => _DzikrCardState();
}

class _DzikrCardState extends State<DzikrCard> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = _counter >= widget.uiData.dzikrInfo.repetitions;

    final baseTextStyle = TextStyle(
      fontFamily: 'LPMQ',
      fontSize: widget.settings.arabicFontSize,
      height: 2.2,
      color: theme.colorScheme.onSurface,
    );
    final rawText = widget.uiData.ayahs.isNotEmpty 
        ? widget.uiData.ayahs.first.arabicText 
        : (widget.uiData.dzikrInfo.arabicText ?? "");

    final spans = widget.lang == 'id'
        ? AutoTajweedParser.parse(
            rawText,
            baseTextStyle,
            lang: widget.lang,
            context: context,
            learningMode: true,
          )
        : TajweedParser.parse(
            widget.uiData.ayahs.isNotEmpty 
                ? widget.uiData.ayahs.first.tajweedText 
                : widget.uiData.dzikrInfo.arabicText ?? "", 
            baseTextStyle,
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withOpacity(0.05) : theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              widget.uiData.dzikrInfo.getTitle(widget.lang),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            trailing: _buildCounterCircle(isDone),
          ),
          
          // 3. Gunakan RichText untuk menampilkan hasil parse
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.centerRight,
                child: RichText(
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    children: spans,
                  ),
                ),
              ),
            ),
          ),
          
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildCounterCircle(bool isDone) {
    return GestureDetector(
      onTap: () {
        if (_counter < widget.uiData.dzikrInfo.repetitions) {
          setState(() => _counter++);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDone ? Colors.green : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Text(
          isDone ? "✓" : "$_counter",
          style: TextStyle(
            color: isDone ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.uiData.ayahs.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.menu_book, size: 16),
              label: Text(widget.lang == 'en' ? "Open Surah" : "Buka Surah"),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                      builder: (context) => SurahDetailScreen(
                        surahId: widget.uiData.ayahs.first.surahId,
                        initialScrollIndex: widget.uiData.ayahs.first.number - 1,
                      ),
                    ));
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => setState(() => _counter = 0),
          ),
        ],
      ),
    );
  }
}

// Helper untuk TabBar Pinned
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}