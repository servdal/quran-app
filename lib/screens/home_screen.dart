// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/screens/page_view_screen.dart'; // Pastikan path import ini benar
import 'package:quran_app/screens/surah_list_screen.dart'; // Pastikan path import ini benar

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assalamualaikum',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Selamat Datang',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: const InputDecoration(
        hintText: 'Cari surah atau terjemahan...',
        prefixIcon: Icon(Icons.search, color: Colors.grey),
      ),
      onSubmitted: (query) {
        // TODO: Implementasi logika navigasi ke halaman hasil pencarian
        print('Mencari: $query');
      },
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).primaryColor, width: 0.5),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).primaryColor, size: 30),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBookmarkButton() {
    // TODO: Ganti dengan logika provider untuk mengecek bookmark
    bool hasBookmark = false; // Set ke false agar tidak tampil dulu

    if (!hasBookmark) return const SizedBox.shrink();

    return ElevatedButton.icon(
      icon: const Icon(Icons.bookmark, color: Colors.white),
      label: const Text('Lanjutkan Membaca (QS. Yasin: 12)'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        // TODO: Logika navigasi ke surah & ayat yang di-bookmark
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Al-Quran Digital'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSearchBar(),
              const SizedBox(height: 24),
              // #### INI BAGIAN YANG DIPERBAIKI ####
              _buildNavigationCard(
                icon: Icons.list_alt_rounded,
                title: 'Lihat per Surah',
                onTap: () {
                   Navigator.push( // Gunakan Navigator.push
                     context,
                     MaterialPageRoute(builder: (context) => const SurahListScreen()),
                   );
                },
              ),
              // ###################################
              const SizedBox(height: 12),
              _buildNavigationCard(
                icon: Icons.auto_stories_rounded,
                title: 'Lihat per Halaman',
                onTap: () {
                   Navigator.push( // Gunakan Navigator.push
                     context,
                     MaterialPageRoute(builder: (context) => const PageViewScreen()),
                   );
                },
              ),
              const SizedBox(height: 32),
              Center(child: _buildBookmarkButton()),
            ],
          ),
        ),
      ),
    );
  }
}