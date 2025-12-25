import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/settings_provider.dart';
import '../services/quran_data_service.dart';
import '../screens/page_view_screen.dart';
import '../screens/deresan_view_screen.dart';

enum PageListViewMode { page, classic }

class PageListScreen extends ConsumerWidget {
  final PageListViewMode mode;
  const PageListScreen({super.key, this.mode = PageListViewMode.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allPagesAsync = ref.watch(allPagesProvider);
    final lang = ref.watch(settingsProvider).language;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang == 'en' ? "Mushaf Page List" : "Daftar Halaman Mushaf",
        ),
        centerTitle: true,
      ),
      body: allPagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Gagal memuat: $e")),
        data: (pages) {
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),

            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),

            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];

              return _PageCard(
                theme: theme,
                pageNumber: page.pageNumber,
                juzId: page.juzId,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              mode == PageListViewMode.page
                                  ? PageViewScreen(initialPage: page.pageNumber)
                                  : DeresanViewScreen(
                                    initialPage: page.pageNumber,
                                  ),
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

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width > 1100) return 6;
    if (width > 900) return 5;
    if (width > 700) return 4;
    return 3;
  }
}

class _PageCard extends StatelessWidget {
  final ThemeData theme;
  final int pageNumber;
  final int juzId;
  final VoidCallback onTap;

  const _PageCard({
    required this.theme,
    required this.pageNumber,
    required this.juzId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors:
                isDark
                    ? [Colors.blueGrey.shade900, Colors.blueGrey.shade700]
                    : [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hal. $pageNumber",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Juz $juzId",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey.withOpacity(0.25),
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
          ],
        ),
      ),
    );
  }
}
