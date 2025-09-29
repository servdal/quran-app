// lib/screens/page_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/screens/page_view_screen.dart';
import 'package:quran_app/screens/deresan_view_screen.dart';

enum PageListViewMode { page, deresan }

class PageListScreen extends ConsumerWidget {
  final PageListViewMode mode;
  const PageListScreen({super.key, this.mode = PageListViewMode.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allPagesAsync = ref.watch(allPagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Halaman'),
      ),
      body: allPagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Gagal memuat: $e")),
        data: (pages) {
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
            ),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              return InkWell(
                onTap: () {
                  if (mode == PageListViewMode.page) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PageViewScreen(initialPage: page.pageNumber),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeresanViewScreen(initialPage: page.pageNumber),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${page.pageNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Juz ${page.juzId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}