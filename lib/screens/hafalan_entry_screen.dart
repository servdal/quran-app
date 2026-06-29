import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/page_index_model.dart';
import 'package:quran_app/models/surah_index_model.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/screens/hafalan_screen.dart';
import 'package:quran_app/services/quran_data_service.dart';

class HafalanEntryScreen extends ConsumerWidget {
  const HafalanEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(settingsProvider).language;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang == 'en' ? 'Choose Memorization' : 'Pilih Hafalan'),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.auto_stories_rounded),
                text: lang == 'en' ? 'By Page' : 'Per Halaman',
              ),
              Tab(
                icon: const Icon(Icons.menu_book_rounded),
                text: lang == 'en' ? 'By Surah' : 'Per Surah',
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [_PagePicker(), _SurahPicker()]),
      ),
    );
  }
}

class _PagePicker extends ConsumerWidget {
  const _PagePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagesAsync = ref.watch(allPagesProvider);
    final lang = ref.watch(settingsProvider).language;

    return pagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              lang == 'en' ? 'Failed to load pages' : 'Gagal memuat halaman',
            ),
          ),
      data:
          (pages) => GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount(context),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return _PageChoiceCard(page: pages[index]);
            },
          ),
    );
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1100) return 6;
    if (width > 800) return 5;
    if (width > 600) return 4;
    return 3;
  }
}

class _PageChoiceCard extends StatelessWidget {
  final PageIndexInfo page;

  const _PageChoiceCard({required this.page});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HafalanViewScreen(initialPage: page.pageNumber),
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              page.pageNumber.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text('Juz ${page.juzId}', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SurahPicker extends ConsumerWidget {
  const _SurahPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(allSurahsProvider);
    final lang = ref.watch(settingsProvider).language;

    return surahsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, _) => Center(
            child: Text(
              lang == 'en' ? 'Failed to load surahs' : 'Gagal memuat surah',
            ),
          ),
      data:
          (surahs) => ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: surahs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              return _SurahChoiceTile(surah: surahs[index]);
            },
          ),
    );
  }
}

class _SurahChoiceTile extends StatelessWidget {
  final SurahIndexInfo surah;

  const _SurahChoiceTile({required this.surah});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Text(
          surah.suraId.toString(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        surah.nameLatin,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('${surah.translation} • ${surah.numberOfAyahs} ayat'),
      trailing: Text(
        surah.nameArabic,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Uthmani', fontSize: 22),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => HafalanViewScreen.bySurah(initialSurah: surah.suraId),
          ),
        );
      },
    );
  }
}
