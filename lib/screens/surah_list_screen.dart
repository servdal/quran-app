// lib/screens/surah_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/settings_provider.dart';
import '../models/surah_index_model.dart';
import '../screens/surah_detail_screen.dart';
import '../services/quran_data_service.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahsAsync = ref.watch(allSurahsProvider);
    final lang = ref.watch(settingsProvider).language;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'en' ? "Mushaf Surah List" : "Daftar Surah Mushaf",
        ),
        centerTitle: true,
      ),
      body: surahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
        data: (surahs) => ListView.builder(
          itemCount: surahs.length,
          itemBuilder: (context, index) {
            return _SurahListItem(surah: surahs[index]);
          },
        ),
      ),
    );
  }
}

class _SurahListItem extends StatelessWidget {
  final SurahIndexInfo surah;
  const _SurahListItem({required this.surah});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurahDetailScreen(surahId: surah.suraId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Text(
                  surah.suraId.toString(),
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              /// Nama Latin + Meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.nameLatin,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.revelationType} • ${surah.numberOfAyahs} Ayat',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              /// Nama Arab
              Text(
                surah.nameArabic,
                style: TextStyle(
                  fontFamily: 'Uthmani',
                  fontSize: 22,
                  color: theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
