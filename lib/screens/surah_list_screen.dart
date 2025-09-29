// lib/screens/surah_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/surah_index_model.dart'; // Ganti model
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/services/quran_data_service.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSurahsAsyncValue = ref.watch(allSurahsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Surah'),
      ),
      body: allSurahsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Gagal memuat data: $error')),
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

class _SurahListItem extends StatelessWidget {
  const _SurahListItem({required this.surah});

  final SurahIndexInfo surah; // Ganti model

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(surahId: surah.suraId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.1),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.englishName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${surah.revelationType} • ${surah.numberOfAyahs} Ayat',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                surah.name,
                style: TextStyle(
                  fontFamily: 'LPMQ',
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