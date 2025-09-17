// page_list_screen.dart

import 'package:flutter/material.dart';
import 'package:quran_app/screens/page_view_screen.dart';
import 'package:quran_app/screens/deresan_view_screen.dart';

enum PageListViewMode { page, deresan }

class PageListScreen extends StatelessWidget {
  final PageListViewMode mode;
  const PageListScreen({super.key, this.mode = PageListViewMode.page});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Halaman'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12.0, 
          mainAxisSpacing: 12.0,
        ),
        itemCount: 604,
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          return InkWell(
            onTap: () {
              if (mode == PageListViewMode.page) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PageViewScreen(initialPage: pageNumber),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeresanViewScreen(initialPage: pageNumber),
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
              child: Center(
                child: Text(
                  '$pageNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}