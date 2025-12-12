import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:quran_app/utils/tajweed_parser.dart';
import 'package:quran_app/utils/auto_tajweed_parser.dart';

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
      builder: (ctx) => SettingsModalContent(currentPage: _currentPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Halaman $_currentPage'),
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
              label: const Text(''),
              onPressed: () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            ElevatedButton.icon(
              label: const Text(''),
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                _pageController.previousPage(
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
  String _convertToArabicNumber(int number, TextStyle baseNumberStyle) {
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
        final List<Widget> pageWidgets = [];
        List<InlineSpan> currentSurahSpans = [];
        for (int i = 0; i < ayahs.length; i++) {
          final ayah = ayahs[i];
          
          // Cek jika ini adalah surah baru
          if (i == 0 || ayah.suraId != ayahs[i - 1].suraId) {
            // 1. Tambahkan RichText dari surah sebelumnya (jika ada) ke dalam list widget
            if (currentSurahSpans.isNotEmpty) {
              pageWidgets.add(
                RichText(
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                  text: TextSpan(children: currentSurahSpans),
                ),
              );
              currentSurahSpans = []; // Kosongkan lagi untuk surah baru
            }

            // 2. Tambahkan Header Nama Surah sebagai widget baru
            pageWidgets.add(_SurahHeaderWidget(surahName: ayah.suraName ?? 'Surah ${ayah.suraId}'));

            // 3. Tambahkan Bismillah sebagai widget baru jika perlu
            if (ayah.suraId != 9 && ayah.ayaNumber == 1) {
              pageWidgets.add(_BismillahWidget(fontSize: settings.arabicFontSize));
            }
          }
          final baseTextStyle = TextStyle(
            fontFamily: 'LPMQ',
            fontSize: settings.arabicFontSize,
            height: 2.2,
            color: theme.colorScheme.onSurface,
          );
          final baseNumberStyle = TextStyle(
            fontFamily: 'Uthmani',
            fontSize: settings.arabicFontSize,
            height: 2.2,
            color: theme.colorScheme.onSurface,
          );
          currentSurahSpans.addAll(AutoTajweedParser.parse(ayah.ayaText, baseTextStyle));
          currentSurahSpans.add(const TextSpan(text: ' '));
          currentSurahSpans.add(WidgetSpan(
            child: _AyahNumberMarker(
              number: _convertToArabicNumber(ayah.ayaNumber, baseNumberStyle),
              hasSajda: false, 
            ),
            alignment: PlaceholderAlignment.middle,
          ));
          currentSurahSpans.add(const TextSpan(text: ' '));
        }
        if (currentSurahSpans.isNotEmpty) {
          pageWidgets.add(
            RichText(
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              text: TextSpan(children: currentSurahSpans),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 80.0), 
          child: Column(
            children: pageWidgets,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Gagal memuat halaman $pageNumber: $e')),
    );
  }
}

// Widget untuk header nama surah (berfungsi sebagai pemisah)
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

class _BismillahWidget extends StatelessWidget {
  final double fontSize;
  const _BismillahWidget({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: double.infinity, // Tidak wajib di dalam Column, tapi tidak masalah
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Center( // Center akan memastikan teks berada di tengah
        child: Text(
          "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'LPMQ',
            fontSize: fontSize * 1.1, // Sedikit lebih besar dari teks ayat
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

  const _AyahNumberMarker({
    required this.number,
    required this.hasSajda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5),
      ),
      child: Text(
        '${hasSajda ? '۩ ' : ''}$number',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'LPMQ', 
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}

// Widget untuk konten modal pengaturan
class SettingsModalContent extends ConsumerWidget {
  final int currentPage;
  const SettingsModalContent({super.key, required this.currentPage});

  void _saveBookmark(WidgetRef ref, String name) async {
    final ayahs = await ref.read(pageAyahsProvider(currentPage).future);
    if (ayahs.isNotEmpty) {
      final firstAyah = ayahs.first;
      final newBookmark = Bookmark(
        type: BookmarkViewType.deresan.name,
        surahId: firstAyah.suraId,
        surahName: firstAyah.surah?.englishName ?? 'Surah ${firstAyah.suraId}',
        ayahNumber: firstAyah.ayaNumber, // Gunakan ayat pertama sebagai acuan
        pageNumber: currentPage,
      );
      ref.read(bookmarkProvider.notifier).addOrUpdateBookmark(name, newBookmark);
    }
  }
  void _showBookmarkDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    final bookmarks = ref.read(bookmarkProvider);
    final existingNames = bookmarks.keys.toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tandai Halaman Ini'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bookmark Baru',
                    hintText: 'Contoh: Hafalan Harian',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Atau timpa yang sudah ada:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(),
                if (existingNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('Belum ada bookmark.')),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: existingNames.length,
                      itemBuilder: (context, index) {
                        final name = existingNames[index];
                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            _saveBookmark(ref, name);
                            Navigator.of(dialogContext).pop(); // Tutup dialog
                            Navigator.of(context).pop(); // Tutup modal sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Bookmark "$name" diperbarui.')),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Simpan Baru'),
              onPressed: () {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  _saveBookmark(ref, newName);
                  Navigator.of(dialogContext).pop(); // Tutup dialog
                  Navigator.of(context).pop(); // Tutup modal sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Halaman ditandai di "$newName".')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama bookmark tidak boleh kosong.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

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
              onPressed: () {
                _showBookmarkDialog(context, ref);
              },
            ),
          )
        ],
      ),
    );
  }
}

