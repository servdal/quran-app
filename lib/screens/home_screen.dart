// home_screen.dart (SUDAH DIPERBAIKI)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/screens/page_view_screen.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/screens/surah_list_screen.dart';
import 'package:quran_app/screens/search_result_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'package:quran_app/screens/page_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel(); // Pastikan timer dibatalkan saat widget ditutup
    super.dispose();
  }

  // Fungsi untuk menangani pencarian dengan jeda (debouncing)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Aksi ini akan dijalankan 500ms setelah pengguna berhenti mengetik
      if (query.trim().length > 2) {
        // Menggunakan context dari widget
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultScreen(query: query.trim()),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkAsync = ref.watch(bookmarkProvider);
    final theme = Theme.of(context); // Mengambil data tema saat ini

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown, // mengecilkan teks kalau terlalu panjang
          child: Text("Tafsir Jalalayn Audio KH. Bahauddin Nursalim"),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: 24),
              _buildSearchBar(context, theme),
              const SizedBox(height: 24),
              
              bookmarkAsync.when(
                data: (bookmark) {
                  if (bookmark == null) return const SizedBox.shrink();
                  return _buildBookmarkCard(context, ref, theme, bookmark);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => const SizedBox.shrink(),
              ),

              _buildNavigationCard(context, theme,
                icon: Icons.list_alt_rounded,
                title: 'Lihat per Surah',
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const SurahListScreen()));
                },
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(context, theme,
                icon: Icons.auto_stories_rounded,
                title: 'Lihat per Halaman',
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const PageListScreen()));
                },
              ),
              const SizedBox(height: 24),
              _buildGlossary(context, theme),
              const SizedBox(height: 32),
              _buildDeveloperInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assalamualaikum Warohmatullahi Wabarokatuh.', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Cari surah atau terjemahan...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildBookmarkCard(BuildContext context, WidgetRef ref, ThemeData theme, Bookmark bookmark) {
    // Warna untuk kartu bookmark disesuaikan agar kontras
    final cardColor = theme.brightness == Brightness.light ? theme.primaryColor : theme.colorScheme.surface;
    final onCardColor = theme.brightness == Brightness.light ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Column(
      children: [
        Card(
          color: cardColor,
          child: ListTile(
            leading: Icon(Icons.bookmark, color: onCardColor, size: 30),
            title: Text('Lanjutkan Membaca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onCardColor)),
            subtitle: Text('Ayah ${bookmark.ayahNumber} | ${bookmark.surahName} ', style: TextStyle(color: onCardColor.withOpacity(0.8))),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: onCardColor),
              tooltip: 'Hapus Bookmark',
              onPressed: () async {
                await ref.read(bookmarkProvider.notifier).removeBookmark();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark telah dihapus.')),
                );
              },
            ),
            onTap: () {
              if (bookmark.type == 'surah') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SurahDetailScreen(
                    surahId: bookmark.surahId,
                    initialScrollIndex: bookmark.ayahNumber - 1,
                  ),
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

  Widget _buildNavigationCard(BuildContext context, ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 30),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.withOpacity(0.7), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlossary(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Glosarium Tajwid',
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias, // Agar konten di dalam card mengikuti corner radius
          margin: EdgeInsets.zero, // Hapus margin default dari Card
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppTheme.tajweedRules.length,
            itemBuilder: (context, index) {
              final rule = AppTheme.tajweedRules[index];
              return ExpansionTile(
                // **Leading:** Ikon lingkaran berwarna
                leading: CircleAvatar(backgroundColor: rule.color, radius: 12),
                
                // **Title:** Nama hukum tajwid yang selalu terlihat
                title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                
                // **Children:** Konten yang muncul saat di-klik (expanded)
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: <Widget>[
                  Text(
                    rule.description,
                    textAlign: TextAlign.justify, // Tambahkan ini agar teks rata kanan-kiri
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildDeveloperInfo(BuildContext context) {
    final Uri githubUrl = Uri.parse('https://github.com/servdal/quran-app');

    // Fungsi untuk membuka URL
    Future<void> _launchUrl() async {
      if (!await launchUrl(githubUrl, mode: LaunchMode.externalApplication)) {
        // Menampilkan pesan jika gagal membuka URL
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka link: $githubUrl')),
          );
        }
      }
    }

    return Column(
      children: [
        Text(
          'Dikembangkan dengan ❤️ oleh Duidev Software House',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _launchUrl, // Panggil fungsi saat di-klik
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              'Bantu kembangkan di https://github.com/servdal/quran-app',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}