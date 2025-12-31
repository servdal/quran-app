import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:math' as math;
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
  final ScrollController _scrollController = ScrollController();
  late int _currentPage;
  List<String> _targetWords = [];
  List<GlobalKey> _wordKeys = [];
  int _currentIndex = 0;

  int _mistakeCount = 0;
  int _totalSkipCount = 0;
  Set<int> _skippedIndices = {};

  static const int _hintThreshold = 3;
  static const int _skipThreshold = 6;

  String _statusMessage = 'Tekan mikrofon untuk mulai';
  bool _isListening = false;

  String _currentSurahName = '';
  int _currentSurahId = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _initSpeech();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        }
      },
    );
    if (mounted) setState(() {});
  }

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
      _wordKeys = List.generate(words.length, (_) => GlobalKey());
      _currentIndex = 0;
      _currentSurahName = ayahs.first.surahName;
      _currentSurahId = ayahs.first.surahId;
      _mistakeCount = 0;
      _totalSkipCount = 0;
      _skippedIndices.clear();

      _advanceToNextSpeakable();
    }
  }

  void _advanceToNextSpeakable() {
    if (_targetWords.isEmpty) return;

    while (_currentIndex < _targetWords.length &&
        _normalize(_targetWords[_currentIndex]).isEmpty) {
      _currentIndex++;
    }
    _mistakeCount = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToActiveWord();
    });
  }

  void _scrollToActiveWord() {
    if (_currentIndex >= _wordKeys.length) return;

    final key = _wordKeys[_currentIndex];
    if (key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.35,
      );
    }
  }

  void _skipCurrentWord() {
    if (_currentIndex >= _targetWords.length) return;

    if (_mistakeCount < _skipThreshold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Belum bisa skip! Coba ${_skipThreshold - _mistakeCount} kali lagi.",
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _skippedIndices.add(_currentIndex);
      _totalSkipCount++;
      _currentIndex++;
      _statusMessage = "Kata dilewati (Skip)";
    });

    _advanceToNextSpeakable();
  }

  void _startListening() async {
    setState(() {
      _statusMessage = "Mendengarkan...";
      _isListening = true;
    });

    await _speechToText.listen(
      onResult: (result) {
        bool matchFound = _verifyStream(
          result.recognizedWords,
          result.alternates.map((e) => e.recognizedWords).toList(),
        );

        if (result.finalResult && !matchFound) {
          setState(() {
            _mistakeCount++;
            int sisaSkip = _skipThreshold - _mistakeCount;

            if (_mistakeCount < _hintThreshold) {
              _statusMessage = "Salah (${_mistakeCount}). Ayo coba lagi!";
            } else if (_mistakeCount < _skipThreshold) {
              _statusMessage = "Hint muncul. Skip aktif dalam ${sisaSkip}x.";
            } else {
              _statusMessage = "Sudah 6x salah. Tombol Skip AKTIF.";
            }

            if (_mistakeCount < 10) {
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
      pauseFor: const Duration(seconds: 4),
    );
  }

  bool _verifyStream(String primaryResult, List<String> alternates) {
    if (_currentIndex >= _targetWords.length) {
      setState(
        () => _statusMessage = "Halaman Selesai! Total Skip: $_totalSkipCount",
      );
      return true;
    }

    List<String> inputPossibilities = [primaryResult, ...alternates];
    String targetRaw = _targetWords[_currentIndex];
    String targetClean = _normalize(targetRaw);
    double bestMatchScore = 0.0;

    for (String fullSentence in inputPossibilities) {
      String fullNormalized = _normalize(fullSentence);
      double scoreFull = _calculateSimilarity(fullNormalized, targetClean);
      if (scoreFull > bestMatchScore) bestMatchScore = scoreFull;

      List<String> words = fullSentence.split(' ');
      int startIdx = (words.length > 5) ? words.length - 5 : 0;
      List<String> recentWords = words.sublist(startIdx);

      for (String word in recentWords) {
        String wordClean = _normalize(word);
        double score = _calculateSimilarity(wordClean, targetClean);
        if (score > bestMatchScore) bestMatchScore = score;
      }
    }

    if (bestMatchScore >= 0.40) {
      setState(() {
        _currentIndex++;
        _statusMessage = "Benar!";
        _mistakeCount = 0;
      });
      _advanceToNextSpeakable();
      return true;
    }
    return false;
  }

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

    clean = clean.replaceAll('الموس', 'المس');
    clean = clean.replaceAll('تعقيم', 'تقيم');
    clean = clean.replaceAll('سيرات', 'سراط');
    clean = clean.replaceAll('1000', 'ا');
    clean = clean.replaceAll('١٠٠٠', 'ا');

    clean = clean.replaceAll('ص', 'س');
    clean = clean.replaceAll('ط', 'ت');
    clean = clean.replaceAll('ظ', 'ز');
    clean = clean.replaceAll('ذ', 'ز');
    clean = clean.replaceAll('ث', 'س');
    clean = clean.replaceAll('ق', 'ك');

    Map<String, String> map = {
      'الف': 'ا',
      'لام': 'ل',
      'ميم': 'م',
      'كاف': 'ك',
      'ها': 'ه',
      'يا': 'ي',
      'عين': 'ع',
      'سين': 'س',
      'نون': 'ن',
      'طه': 'طه',
      'يس': 'يس',
      'حم': 'حم',
    };
    map.forEach((k, v) {
      if (k.length > 1) clean = clean.replaceAll(RegExp(r'\b' + k + r'\b'), v);
    });

    clean = clean.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    clean = clean.replaceAll(RegExp(r'[ىئ]'), 'ي');
    clean = clean.replaceAll('ة', 'ه');
    clean = clean.replaceAll('ؤ', 'و');

    clean = clean.replaceAll(RegExp(r'[^\u0600-\u06FF]'), '');
    clean = clean.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
      '',
    );
    clean = clean.replaceAll(' ', '');

    return clean.trim();
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
          title: Text(lang == 'en' ? 'Bookmark Hafalan' : 'Tandai Hafalan'),
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
                            ? 'e.g., Juz 30 Lancar'
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
                    height: 150,
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
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
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
                        bool isSkipped = _skippedIndices.contains(index);

                        Color textColor = Colors.black87;
                        double opacity = 0.0;

                        if (isSkipped) {
                          opacity = 1.0;
                          textColor = Colors.red;
                        } else if (isPassed) {
                          opacity = 1.0;
                        } else if (isCurrent) {
                          opacity = _mistakeCount >= _hintThreshold ? 0.2 : 0.0;
                        } else {
                          opacity = 0.0;
                        }

                        return Container(
                          key:
                              _wordKeys.length > index
                                  ? _wordKeys[index]
                                  : null, // PASANG KEY DISINI
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: opacity,
                            child: Text(
                              _targetWords[index],
                              style: TextStyle(
                                fontFamily: 'LPMQ',
                                fontSize: settings.arabicFontSize + 8,
                                height: 1.6,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),

              _buildControlBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlBar() {
    bool canSkip = _mistakeCount >= _skipThreshold;

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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _totalSkipCount > 0
                  ? "$_statusMessage • Error/Skip: $_totalSkipCount"
                  : _statusMessage,
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

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            color: (_isListening
                                    ? Colors.redAccent
                                    : Colors.teal)
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

                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      color:
                          canSkip
                              ? Colors.orange.shade50
                              : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            canSkip
                                ? Colors.orange.shade200
                                : Colors.grey.shade300,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      color: canSkip ? Colors.orange : Colors.grey.shade400,
                      tooltip:
                          canSkip ? "Skip kata ini" : "Salah 6x untuk skip",
                      onPressed: () {
                        if (canSkip) {
                          _skipCurrentWord();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Belum bisa skip! Coba ${_skipThreshold - _mistakeCount} kali lagi.",
                              ),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
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
      _totalSkipCount = 0;
      _skippedIndices.clear();
      _wordKeys = [];
      _statusMessage = "Siap hafalan?";
      _isListening = false;
    });
    _speechToText.stop();
  }
}
