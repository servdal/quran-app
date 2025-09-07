// page_list_screen.dart

import 'package:flutter/material.dart';
import 'package:quran_app/screens/page_view_screen.dart';

class PageListScreen extends StatelessWidget {
  const PageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Halaman'),
      ),
      // Menggunakan GridView untuk menampilkan nomor halaman dalam bentuk kotak
      body: GridView.builder(
        padding: const EdgeInsets.all(12.0),
        // Menentukan berapa banyak item per baris dan jaraknya
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, // 4 kotak per baris
          crossAxisSpacing: 12.0, // Jarak horizontal
          mainAxisSpacing: 12.0, // Jarak vertikal
        ),
        itemCount: 604, // Total halaman dalam Al-Qur'an
        itemBuilder: (context, index) {
          final pageNumber = index + 1;
          return InkWell(
            onTap: () {
              // Navigasi ke PageViewScreen dengan membawa nomor halaman yang dipilih
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PageViewScreen(initialPage: pageNumber),
                ),
              );
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