import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/widgets/ayah_widget.dart';

class PageViewScreen extends StatefulWidget {
  const PageViewScreen({super.key, this.initialPage = 1});

  final int initialPage;

  @override
  State<PageViewScreen> createState() => _PageViewScreenState();
}

class _PageViewScreenState extends State<PageViewScreen> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    // PageController diinisialisasi dengan halaman awal. Ingat, index array dimulai dari 0.
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halaman $_currentPage dari 604'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              // Balik arah geser agar sesuai dengan mushaf (kanan ke kiri)
              reverse: true,
              itemCount: 604, // Total halaman dalam mushaf standar
              itemBuilder: (context, index) {
                // index dimulai dari 0, sedangkan nomor halaman dari 1
                final pageNumber = index + 1;
                return _QuranPageWidget(pageNumber: pageNumber);
              },
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index + 1;
                });
              },
            ),
          ),
          // Tombol navigasi halaman
          _buildPageControls(),
        ],
      ),
    );
  }

  Widget _buildPageControls() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('Sebelumnya'),
            onPressed: _currentPage > 1
                ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null, // Tombol nonaktif jika di halaman pertama
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Berikutnya'),
            onPressed: _currentPage < 604
                ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null, // Tombol nonaktif jika di halaman terakhir
          ),
        ],
      ),
    );
  }
}

// Widget untuk memuat dan menampilkan konten satu halaman Al-Quran
class _QuranPageWidget extends ConsumerWidget {
  const _QuranPageWidget({required this.pageNumber});

  final int pageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memanggil provider.family dengan nomor halaman yang sesuai
    final pageDataAsync = ref.watch(pageAyahsProvider(pageNumber));

    return pageDataAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Gagal memuat halaman $pageNumber')),
      data: (ayahs) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          itemCount: ayahs.length,
          itemBuilder: (context, index) {
            final ayah = ayahs[index];
            // Cek jika ini adalah ayat pertama dari sebuah surah untuk menampilkan header
            final bool isFirstAyahInSurah = ayah.ayaNumber == 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isFirstAyahInSurah)
                  _SurahHeader(surahName: ayah.surah?.name ?? ''),
                AyahWidget(
                  ayah: ayah,
                  // Memberi tahu AyahWidget bahwa bookmark harus disimpan sebagai 'page'
                  viewType: BookmarkViewType.page,
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// Widget untuk header nama surah
class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surahName});

  final String surahName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Theme.of(context).primaryColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          surahName,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'LPMQ',
            fontSize: 24,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }
}

