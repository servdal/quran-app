import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';

final searchResultsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.length < 3) return [];
  final service = ref.read(quranDataServiceProvider);
  return service.searchAyahs(query);
});

class SearchResultScreen extends ConsumerWidget {
  final String query;
  const SearchResultScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(searchResultsProvider(query));

    return Scaffold(
      appBar: AppBar(title: Text('Hasil untuk "$query"')),
      body: searchResultsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (results) {
          if (results.isEmpty) {
            return const Center(child: Text('Tidak ada hasil ditemukan.'));
          }
          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return ListTile(
                title: Text('QS. ${result['surahName']} : ${result['ayahNumber']}'),
                subtitle: Text(result['ayahTextPreview'], maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahDetailScreen(surahId: result['surahId']),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
