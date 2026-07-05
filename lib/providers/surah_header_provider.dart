// lib/providers/surah_header_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/quran_repository.dart';
import 'settings_provider.dart';

// 1. Buat model data sederhana untuk menampung data Header
class SurahHeaderMetadata {
  final int number;
  final String nameArabic;
  final String revelation;
  final String nameLatin;

  SurahHeaderMetadata({
    required this.number,
    required this.nameArabic,
    required this.revelation,
    required this.nameLatin,
  });
}

final quranRepositoryProvider = Provider((ref) => QuranRepository());

final surahFromPageProvider = FutureProvider.family<SurahHeaderMetadata, int>((ref, pageNumber) async {
  final repository = ref.watch(quranRepositoryProvider);
  final settings = ref.watch(settingsProvider);
  final lang = settings.language;

  // Ambil semua baris ayat yang ada di halaman tersebut
  final List<Map<String, dynamic>> pageRows = await repository.getAyahRowsByPage(pageNumber);

  if (pageRows.isNotEmpty) {
    // Ambil sura_id dari baris pertama ayat di halaman tersebut
    final firstRow = pageRows.first;
    final int surahId = firstRow['sura_id'] as int;

    final Map<String, dynamic> meta = await repository.getSurahMeta(surahId, lang: lang);

    if (meta.isNotEmpty) {
      return SurahHeaderMetadata(
        number: surahId,
        nameArabic: meta['arabic_name'] ?? '',
        revelation: meta['revelation_type'] ?? '',
        nameLatin: meta['name'] ?? '',
      );
    }
  }

  return SurahHeaderMetadata(number: 1, nameArabic: 'الفاتحة', revelation: 'id' == lang ? 'Makkiyah' : 'Meccan', nameLatin: 'Al-Fatihah');
});