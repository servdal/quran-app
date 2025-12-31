import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:math' as math;

// Imports dari project Anda
import '../services/quran_data_service.dart';
import '../providers/settings_provider.dart';
import '../providers/bookmark_provider.dart';
import '../models/ayah_model.dart';

class HafalanViewScreen extends ConsumerStatefulWidget {
  final int initialPage;
  const HafalanViewScreen({super.key, required this.initialPage});

  @override
  ConsumerState<HafalanViewScreen> createState() => _HafalanViewScreenState();
}

class _HafalanViewScreenState extends ConsumerState<HafalanViewScreen> {
  final SpeechToText _speechToText = SpeechToText();

  // State Data Hafalan
  late int _currentPage;
  List<String> _targetWords = [];
  int _currentIndex = 0;

  // State Logika Hint
  int _mistakeCount = 0; // Menghitung berapa kali salah/gagal

  // State UI
  String _statusMessage = 'Tekan mikrofon untuk mulai';
  bool _isListening = false;

  // Info Surat
  String _currentSurahName = '';
  int _currentSurahId = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _initSpeech();
  }

  void _initSpeech() async {
    await _speechToText.initialize(
      onError:
          (val) => setState(() {
            _statusMessage = "Error: ${val.errorMsg}";
            _isListening = false;
          }),
      onStatus: (val) {
        if (mounted) {
          setState(() => _isListening = val == 'listening');
          if (val == 'done' || val == 'notListening') {
            // Jika mic mati sendiri dan belum benar, kita anggap 1x percobaan selesai
            // (Logic increment mistake ada di onResult final)
          }
        }
      },
    );
    if (mounted) setState(() {});
  }

  // --- PERSIAPAN DATA ---
  void _prepareData(List<Ayah> ayahs) {
    if (_targetWords.isEmpty && ayahs.isNotEmpty) {
      List<String> words = [];
      for (var ayah in ayahs) {
        if (ayah.arabicWords.isNotEmpty) {
          words.addAll(ayah.arabicWords);
        } else {
          words.addAll(ayah.arabicText.split(' '));
        }
      }

      _targetWords = words;
      _currentIndex = 0;
      _currentSurahName = ayahs.first.surahName;
      _currentSurahId = ayahs.first.surahId;
      _mistakeCount = 0;

      // Lompat otomatis jika kata pertama adalah simbol/bismillah (opsional)/nomor
      _advanceToNextSpeakable();
    }
  }

  // Melompati simbol/tanda waqaf/nomor ayat yang tidak diucapkan
  void _advanceToNextSpeakable() {
    if (_targetWords.isEmpty) return;

    // Loop selama kata saat ini kosong setelah dinormalisasi
    while (_currentIndex < _targetWords.length &&
        _normalize(_targetWords[_currentIndex]).isEmpty) {
      _currentIndex++;
    }

    // Reset mistake count setiap kali pindah kata
    _mistakeCount = 0;
  }

  // --- LOGIKA UTAMA (STT & MATCHING) ---
  void _startListening() async {
    setState(() {
      _statusMessage = "Mendengarkan...";
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        // Cek kecocokan secara realtime
        bool matchFound = _verifyStream(
          result.recognizedWords,
          result.alternates.map((e) => e.recognizedWords).toList(),
        );

        // LOGIKA MISTAKE COUNT:
        // Kita tambah counter HANYA jika hasil sudah Final (Google selesai mikir) DAN belum cocok.
        if (result.finalResult && !matchFound) {
          setState(() {
            _mistakeCount++;
            _statusMessage = "Kurang pas, coba lagi (${_mistakeCount}/3)";

            // Auto restart mic jika belum benar (opsional, agar user tidak capek tekan tombol)
            if (_mistakeCount < 3) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && !_isListening) _startListening();
              });
            }
          });
        }
      },
      localeId: "ar_SA",
      listenMode: ListenMode.dictation,
      partialResults: true,
      pauseFor: const Duration(seconds: 3),
    );
  }

  bool _verifyStream(String primaryResult, List<String> alternates) {
    if (_currentIndex >= _targetWords.length) {
      setState(() => _statusMessage = "Halaman Selesai!");
      return true;
    }

    // Gabungkan hasil utama dan alternatif untuk dicek semua
    List<String> inputPossibilities = [primaryResult, ...alternates];

    String targetRaw = _targetWords[_currentIndex];
    String targetClean = _normalize(targetRaw);

    double bestMatchScore = 0.0;

    for (String fullSentence in inputPossibilities) {
      // 1. Cek Full Sentence (Khusus Muqatta'at pendek: 'Alif Lam Mim')
      if (targetClean.length < 5) {
        String fullNormalized = _normalize(fullSentence);
        double score = _calculateSimilarity(fullNormalized, targetClean);
        if (score > bestMatchScore) bestMatchScore = score;
      }

      // 2. Cek Per Kata (Ambil 5 kata terakhir)
      List<String> words = fullSentence.split(' ');
      int startIdx = (words.length > 5) ? words.length - 5 : 0;
      List<String> recentWords = words.sublist(startIdx);

      for (String word in recentWords) {
        String wordClean = _normalize(word);
        double score = _calculateSimilarity(wordClean, targetClean);
        if (score > bestMatchScore) bestMatchScore = score;
      }
    }

    // THRESHOLD: 40% (0.4)
    if (bestMatchScore >= 0.40) {
      setState(() {
        _currentIndex++;
        _statusMessage = "Benar! Lanjut...";
        _mistakeCount = 0; // Reset counter karena berhasil
      });
      _advanceToNextSpeakable();
      return true;
    }

    // Update live text feedback (tanpa error message kasar)
    if (_isListening) {
      // Opsional: Tampilkan apa yang didengar sekilas
      // setState(() => _statusMessage = primaryResult);
    }

    return false;
  }

  // --- ALGORITMA PENDUKUNG ---

  double _calculateSimilarity(String s1, String s2) {
    if (s1.isEmpty || s2.isEmpty) return 0.0;
    if (s1 == s2) return 1.0;
    int dist = _levenshtein(s1, s2);
    int maxLen = math.max(s1.length, s2.length);
    return 1.0 - (dist / maxLen);
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);
    for (int i = 0; i < t.length + 1; i++) v0[i] = i;
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = math.min(v1[j] + 1, math.min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < t.length + 1; j++) v0[j] = v1[j];
    }
    return v1[t.length];
  }

  String _normalize(String text) {
    if (text.isEmpty) return "";
    String clean = text;

    // Fix Angka 1000 -> Alif
    clean = clean.replaceAll('1000', 'ا');
    clean = clean.replaceAll('١٠٠٠', 'ا');

    // Mapping Muqatta'at & Normalisasi Huruf
    Map<String, String> map = {
      'الف': 'ا',
      'لام': 'ل',
      'ميم': 'م',
      'صاد': 'ص',
      'كاف': 'ك',
      'ها': 'ه',
      'يا': 'ي',
      'عين': 'ع',
      'سين': 'س',
      'قاف': 'ق',
      'نون': 'ن',
      'طه': 'طه',
      'يس': 'يس',
      'حم': 'حم',
      'ة': 'ه',
      'ؤ': 'و',
      'إ': 'ا',
      'أ': 'ا',
      'آ': 'ا',
      'ٱ': 'ا',
      'ى': 'ي',
      'ئ': 'ي',
    };

    // Replace whole words for Muqatta'at
    map.forEach((k, v) {
      if (k.length > 1) clean = clean.replaceAll(RegExp(r'\b' + k + r'\b'), v);
    });

    // Replace chars for standard letters
    map.forEach((k, v) {
      if (k.length == 1) clean = clean.replaceAll(k, v);
    });

    // Remove non-Arabic & Harakat
    clean = clean.replaceAll(RegExp(r'[^\u0600-\u06FF]'), '');
    clean = clean.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
      '',
    );

    return clean.trim();
  }

  // --- UI ---
  Future<void> _saveBookmark(String name) async {
    final newBookmark = Bookmark(
      type: BookmarkViewType.hafalan,
      surahId: _currentSurahId,
      surahName: _currentSurahName,
      ayahNumber: 1,
      pageNumber: _currentPage,
    );
    await ref
        .read(bookmarkProvider.notifier)
        .addOrUpdateBookmark(name, newBookmark);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Hafalan '$name' berhasil disimpan!"),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _showBookmarkDialog() {
    final settings = ref.read(settingsProvider);
    final lang = settings.language;
    final bookmarks = ref.read(bookmarkProvider);

    final existingHafalanNames =
        bookmarks.entries
            .where((entry) => entry.value.type == BookmarkViewType.hafalan)
            .map((entry) => entry.key)
            .toList();

    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(lang == 'en' ? 'Bookmark Tahsin' : 'Tandai Hafalan'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    labelText:
                        lang == 'en'
                            ? 'New Bookmark Name'
                            : 'Nama Bookmark Baru',
                    hintText:
                        lang == 'en'
                            ? 'e.g., Page 30 Fluent'
                            : 'Contoh: Juz 30 Lancar',
                  ),
                ),

                if (existingHafalanNames.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    lang == 'en'
                        ? 'Overwrite existing:'
                        : 'Timpa yang sudah ada:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(),
                  SizedBox(
                    height: 150, // Batasi tinggi list
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: existingHafalanNames.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final name = existingHafalanNames[index];
                        final bookmark = bookmarks[name]!;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          leading: const Icon(
                            Icons.history,
                            size: 20,
                            color: Colors.grey,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "Hal. ${bookmark.pageNumber} • ${bookmark.surahName}",
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            _saveBookmark(name);
                            Navigator.pop(dialogContext);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang == 'en' ? 'Cancel' : 'Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  _saveBookmark(textController.text.trim());
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(lang == 'en' ? 'Save' : 'Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ayahsAsync = ref.watch(pageAyahsProvider(_currentPage));
    final settings = ref.watch(settingsProvider);
    final bookmarksMap = ref.watch(bookmarkProvider);
    final isBookmarked = bookmarksMap.values.any(
      (b) => b.type == BookmarkViewType.hafalan && b.pageNumber == _currentPage,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Hafalan Hal. $_currentPage"),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.amber : null,
            ),
            onPressed: _showBookmarkDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _changePage(_currentPage),
          ),
        ],
      ),
      body: ayahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Gagal memuat: $e")),
        data: (ayahs) {
          _prepareData(ayahs);

          if (_targetWords.isEmpty)
            return const Center(child: Text("Data ayat kosong."));

          return Column(
            children: [
              // --- AREA AYAT ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 24,
                      alignment: WrapAlignment.center,
                      children: List.generate(_targetWords.length, (index) {
                        bool isPassed = index < _currentIndex;
                        bool isCurrent = index == _currentIndex;

                        // LOGIKA VISIBILITY (Opacity)
                        double opacity = 0.0;
                        if (isPassed) {
                          opacity = 1.0; // Sudah lewat -> Muncul Jelas
                        } else if (isCurrent) {
                          // Jika salah >= 3x, muncul 20% (samar). Jika belum, 0% (invisible).
                          opacity = _mistakeCount >= 3 ? 0.2 : 0.0;
                        } else {
                          opacity = 0.0; // Kata depan -> Invisible
                        }

                        return AnimatedOpacity(
                          duration: const Duration(milliseconds: 500),
                          opacity: opacity,
                          child: Text(
                            _targetWords[index],
                            style: TextStyle(
                              fontFamily: 'LPMQ',
                              fontSize: settings.arabicFontSize + 8,
                              height: 1.6,
                              color:
                                  isPassed
                                      ? Colors.black87
                                      : Colors
                                          .black, // Warna hint tetap hitam tapi transparan
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              // --- CONTROLS & STATUS BAR ---
              _buildControlBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status Text
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _statusMessage,
              key: ValueKey(_statusMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _mistakeCount > 0 ? Colors.orange : Colors.grey[600],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed:
                    _currentPage > 1
                        ? () => _changePage(_currentPage - 1)
                        : null,
              ),

              // MIC BUTTON BESAR
              GestureDetector(
                onTap: () {
                  if (_isListening) {
                    _speechToText.stop();
                    setState(() => _isListening = false);
                  } else {
                    _startListening();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.redAccent : Colors.teal,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isListening ? Colors.redAccent : Colors.teal)
                            .withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed:
                    _currentPage < 604
                        ? () => _changePage(_currentPage + 1)
                        : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _changePage(int p) {
    setState(() {
      _currentPage = p;
      _targetWords = [];
      _currentIndex = 0;
      _mistakeCount = 0;
      _statusMessage = "Siap hafalan?";
      _isListening = false;
    });
    _speechToText.stop();
  }
}
