import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/screens/page_view_screen.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/screens/surah_list_screen.dart';
import 'package:quran_app/screens/search_result_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca data bookmark terakhir dari provider
    final bookmarkAsync = ref.watch(bookmarkProvider);
    
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
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildSearchBar(context),
              const SizedBox(height: 24),
              
              // Menampilkan kartu bookmark secara kondisional
              bookmarkAsync.when(
                data: (bookmark) {
                  // Jika tidak ada bookmark, tampilkan widget kosong
                  if (bookmark == null) return const SizedBox.shrink();
                  // Jika ada, tampilkan kartunya
                  return _buildBookmarkCard(context, ref, bookmark);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => const SizedBox.shrink(), // Sembunyikan jika ada error
              ),

              // Kartu navigasi utama
              _buildNavigationCard(context,
                icon: Icons.list_alt_rounded,
                title: 'Lihat per Surah',
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const SurahListScreen()));
                },
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(context,
                icon: Icons.auto_stories_rounded,
                title: 'Lihat per Halaman',
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const PageViewScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk header sambutan
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Assalamualaikum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white70)),
        const SizedBox(height: 4),
        Text('Selamat Datang', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 28)),
      ],
    );
  }

  // Widget untuk search bar
  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Cari surah atau terjemahan...',
        prefixIcon: Icon(Icons.search, color: Colors.grey),
      ),
      // Menggunakan onSubmitted untuk pengalaman yang lebih stabil
      onSubmitted: (query) {
        if (query.trim().length > 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchResultScreen(query: query.trim()),
            ),
          );
        }
      },
    );
  }

  // Widget untuk menampilkan kartu bookmark
  Widget _buildBookmarkCard(BuildContext context, WidgetRef ref, Bookmark bookmark) {
    return Column(
      children: [
        Card(
          color: Theme.of(context).primaryColor.withOpacity(0.9),
          child: ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.white, size: 30),
            title: const Text('Lanjutkan Membaca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            subtitle: Text('QS. ${bookmark.surahName}: ${bookmark.ayahNumber}', style: const TextStyle(color: Colors.white70)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Hapus Bookmark',
              onPressed: () async {
                await ref.read(bookmarkProvider.notifier).removeBookmark();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark telah dihapus.')),
                );
              },
            ),
            onTap: () {
              // Navigasi sesuai tipe bookmark
              if (bookmark.type == 'surah') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SurahDetailScreen(surahId: bookmark.surahId),
                ));
              } else if (bookmark.type == 'page' && bookmark.pageNumber != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PageViewScreen(initialPage: bookmark.pageNumber!),
                ));
              }
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // Widget untuk kartu navigasi
  Widget _buildNavigationCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
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
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

