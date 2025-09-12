import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

// Layar utama yang mengelola navigasi halaman (PageView)
class DeresanViewScreen extends StatefulWidget {
  final int initialPage;

  const DeresanViewScreen({super.key, required this.initialPage});

  @override
  State<DeresanViewScreen> createState() => _DeresanViewScreenState();
}

class _DeresanViewScreenState extends State<DeresanViewScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // Fungsi untuk menampilkan modal pengaturan
  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // === PERUBAHAN: Melewatkan nomor halaman saat ini ke modal ===
      builder: (ctx) => SettingsModalContent(currentPage: _currentPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Deresan - Halaman $_currentPage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Pengaturan',
            onPressed: () => _showSettingsModal(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            // === PERUBAHAN: Menonaktifkan scroll dengan swipe gesture ===
            physics: const NeverScrollableScrollPhysics(), 
            itemCount: 604, // Jumlah halaman Al-Quran
            onPageChanged: (page) {
              setState(() {
                _currentPage = page + 1;
              });
            },
            itemBuilder: (context, index) {
              return DeresanPage(pageNumber: index + 1);
            },
          ),
          // Tombol Navigasi di bagian bawah
          _buildNavigationControls(),
        ],
      ),
    );
  }

  // Widget untuk tombol navigasi "Sebelumnya" dan "Selanjutnya"
  Widget _buildNavigationControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Sebelumnya'),
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            ElevatedButton.icon(
              label: const Text('Selanjutnya'),
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// Widget yang menampilkan konten satu halaman Al-Quran
class DeresanPage extends ConsumerWidget {
  final int pageNumber;

  const DeresanPage({super.key, required this.pageNumber});
  
  // Fungsi untuk mengubah angka latin ke angka Arab
  String _convertToArabicNumber(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((digit) => arabicDigits[int.parse(digit)]).join();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahsProvider = pageAyahsProvider(pageNumber);
    final ayahsAsync = ref.watch(ayahsProvider);

    return ayahsAsync.when(
      data: (ayahs) {
        if (ayahs.isEmpty) {
          return Center(child: Text('Tidak ada data untuk halaman $pageNumber.'));
        }
        
        final settings = ref.watch(settingsProvider);
        final theme = Theme.of(context);
        
        final List<InlineSpan> textSpans = [];
        String currentSurah = '';

        for (var ayah in ayahs) {
          // 1. Menambahkan header surah jika surah berganti
          if (ayah.surah!.englishName != currentSurah) {
            currentSurah = ayah.surah!.englishName;
            textSpans.add(WidgetSpan(
              child: _SurahHeaderWidget(surahName: currentSurah),
              alignment: PlaceholderAlignment.middle,
            ));
          }

          // 2. Menambahkan teks ayat dengan tajwid
          final baseTextStyle = TextStyle(
            fontFamily: 'LPMQ',
            fontSize: settings.arabicFontSize,
            height: 2.2,
            color: theme.colorScheme.onSurface,
          );
          textSpans.addAll(TajweedParser.parse(ayah.ayaText, baseTextStyle));
          textSpans.add(const TextSpan(text: ' ')); // Spasi antar ayat

          // 3. Menambahkan penanda nomor ayat dan sajdah
          textSpans.add(WidgetSpan(
            child: _AyahNumberMarker(
              number: _convertToArabicNumber(ayah.ayaNumber),
              hasSajda: ayah.sajda,
              fontSize: settings.arabicFontSize * 0.75, // Ukuran penanda relatif
            ),
            alignment: PlaceholderAlignment.middle,
          ));
          textSpans.add(const TextSpan(text: ' '));
        }

        return SingleChildScrollView(
          // === PERUBAHAN: Menambahkan padding bawah agar tidak tertutup tombol navigasi ===
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 80.0), 
          child: RichText(
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            text: TextSpan(children: textSpans),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Gagal memuat halaman $pageNumber: $e')),
    );
  }
}

// Widget untuk header nama surah
class _SurahHeaderWidget extends StatelessWidget {
  final String surahName;
  const _SurahHeaderWidget({required this.surahName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.primaryColor),
      ),
      child: Center(
        child: Text(
          surahName,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'LPMQ',
            color: theme.primaryColor,
          ),
        ),
      ),
    );
  }
}

// Widget untuk penanda nomor ayat
class _AyahNumberMarker extends StatelessWidget {
  final String number;
  final bool hasSajda;
  final double fontSize;

  const _AyahNumberMarker({
    required this.number,
    required this.hasSajda,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasSajda)
            const Text(' ۩', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(
            number,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: 'LPMQ',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget untuk konten modal pengaturan
class SettingsModalContent extends ConsumerWidget {
  // === PERUBAHAN: Menambahkan properti untuk menerima nomor halaman ===
  final int currentPage;
  const SettingsModalContent({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ukuran Font Arab', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: settings.arabicFontSize,
            min: 18,
            max: 40,
            divisions: 22,
            label: settings.arabicFontSize.round().toString(),
            onChanged: (double value) {
              ref.read(settingsProvider.notifier).setFontSize(value);
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Tandai Halaman Ini'),
              // === PERUBAHAN: Menambahkan logika bookmark halaman ===
              onPressed: () async {
                // Ambil data ayat untuk halaman saat ini
                final ayahs = await ref.read(pageAyahsProvider(currentPage).future);
                if (ayahs.isNotEmpty) {
                  final firstAyah = ayahs.first;
                  // Simpan bookmark dengan data ayat pertama sebagai acuan
                  ref.read(bookmarkProvider.notifier).setBookmark(
                        surahId: firstAyah.suraId,
                        surahName: firstAyah.surah!.englishName,
                        ayahNumber: firstAyah.ayaId,
                        pageNumber: currentPage,
                        viewType: BookmarkViewType.deresan,
                      );
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Halaman $currentPage telah ditandai.')),
                  );
                } else {
                   Navigator.of(context).pop();
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menandai halaman: data tidak ditemukan.')),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}

