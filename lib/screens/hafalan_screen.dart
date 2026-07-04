import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/quran_data_service.dart';
import '../providers/settings_provider.dart';
import '../providers/bookmark_provider.dart';
import '../providers/offline_recitation_model_provider.dart';
import '../models/ayah_model.dart';
import '../services/offline_recitation_recognizer.dart';
import '../utils/recitation_alignment.dart';
import 'offline_model_manager_screen.dart';

enum HafalanScope { page, surah }

class HafalanViewScreen extends ConsumerStatefulWidget {
  final int initialPage;
  final int? initialSurah;
  final HafalanScope scope;

  const HafalanViewScreen({super.key, required this.initialPage})
    : initialSurah = null,
      scope = HafalanScope.page;

  const HafalanViewScreen.bySurah({super.key, required this.initialSurah})
    : initialPage = 1,
      scope = HafalanScope.surah;

  @override
  ConsumerState<HafalanViewScreen> createState() => _HafalanViewScreenState();
}

class _HafalanViewScreenState extends ConsumerState<HafalanViewScreen>
    with SingleTickerProviderStateMixin {
  final OfflineRecitationRecognizer _recitationRecognizer =
      OfflineRecitationRecognizer();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<OfflineRecognitionResult>? _recognizerSubscription;
  late int _currentPage;
  late int _currentSurah;
  List<String> _targetWords = [];
  List<GlobalKey> _wordKeys = [];
  int _currentIndex = 0;

  int _mistakeCount = 0;
  int _totalSkipCount = 0;
  final Set<int> _skippedIndices = {};

  static const int _hintThreshold = 3;
  static const int _skipThreshold = 6;

  String _statusMessage = 'Tekan mikrofon untuk mulai';
  bool _isListening = false;
  bool _isRecognizerReady = false;

  String _currentSurahName = '';
  int _currentSurahId = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  String _liveRecognizedWords = "";
  double _debugMicLevel = 0;
  double _debugPeakLevel = 0;
  int _debugAudioSamples = 0;
  String _debugAudioMessage = '';

  bool get _isSurahScope => widget.scope == HafalanScope.surah;
  int get _currentUnit => _isSurahScope ? _currentSurah : _currentPage;
  int get _lastUnit => _isSurahScope ? 114 : 604;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _currentSurah = widget.initialSurah ?? 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = ref.read(settingsProvider).language;
      setState(() {
        _statusMessage =
            lang == 'en'
                ? 'Tap microphone to start'
                : 'Tekan mikrofon untuk mulai';
      });
    });
    _initOfflineRecognizer();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recognizerSubscription?.cancel();
    _recitationRecognizer.stop();
    _pulseController.stop();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initOfflineRecognizer() async {
    final lang = ref.read(settingsProvider).language;
    final available = await _recitationRecognizer.isAvailable();
    if (!mounted) return;

    await _recognizerSubscription?.cancel();
    _recognizerSubscription = null;

    if (available) {
      _recognizerSubscription = _recitationRecognizer.results.listen(
        _handleRecognitionResult,
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _statusMessage =
                lang == 'en'
                    ? 'Offline recitation engine error: $error'
                    : 'Mesin hafalan offline bermasalah: $error';
            _isListening = false;
            _mistakeCount++;
          });
          _pulseController.stop();
          _pulseController.reset();
        },
      );
    }

    setState(() {
      _isRecognizerReady = available;
      if (!available) {
        _statusMessage =
            lang == 'en'
                ? 'Offline Whisper/Vosk model is not ready'
                : 'Model offline Whisper/Vosk belum siap';
      }
    });
  }

  void _prepareData(List<Ayah> ayahs) {
    if (_targetWords.isEmpty && ayahs.isNotEmpty) {
      List<String> words = [];
      for (var ayah in ayahs) {
        if (ayah.arabicWords.isNotEmpty) {
          words.addAll(ayah.arabicWords);
        } else {
          words.addAll(ayah.ayaTextKemenag.split(' '));
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
        RecitationAlignment.normalizePhonetic(
          _targetWords[_currentIndex],
        ).isEmpty) {
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
    final lang = ref.read(settingsProvider).language;
    if (_currentIndex >= _targetWords.length) return;

    if (_mistakeCount < _skipThreshold) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'en'
                ? "Can't skip yet! Try ${_skipThreshold - _mistakeCount} more times."
                : "Belum bisa skip! Coba ${_skipThreshold - _mistakeCount} kali lagi.",
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
      _statusMessage = lang == 'en' ? "Word skipped" : "Kata dilewati (Skip)";
      _liveRecognizedWords = "";
    });

    _recitationRecognizer.stop();
    _advanceToNextSpeakable();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _startListening();
    });
  }

  Future<void> _startListening() async {
    final lang = ref.read(settingsProvider).language;
    if (!_isRecognizerReady) {
      setState(() {
        _statusMessage =
            lang == 'en'
                ? 'Install an offline Whisper tiny/base or Vosk Arabic model first'
                : 'Pasang model offline Whisper tiny/base atau Vosk Arabic dulu';
      });
      _openOfflineModelManager(autoStartDownload: true);
      return;
    }

    if (_currentIndex >= _targetWords.length) return;

    setState(() {
      _statusMessage = lang == 'en' ? "Listening..." : "Mendengarkan...";
      _liveRecognizedWords = "";
      _debugMicLevel = 0;
      _debugPeakLevel = 0;
      _debugAudioSamples = 0;
      _debugAudioMessage = '';
      _isListening = true;
    });

    _pulseController.repeat(reverse: true);
    final activeWords =
        _targetWords
            .skip(_currentIndex)
            .take(12)
            .where(
              (word) => RecitationAlignment.normalizePhonetic(word).isNotEmpty,
            )
            .toList();

    try {
      final modelService = ref.read(offlineRecitationModelServiceProvider);
      final modelId = _selectRecognizerModelId(modelService.installedModelIds);
      await _recitationRecognizer.configure(
        engine:
            modelId == 'vosk_arabic'
                ? OfflineRecitationEngine.vosk
                : OfflineRecitationEngine.whisper,
        activeWords: activeWords,
        expectedPhrase: activeWords.join(' '),
        modelId: modelId,
        modelPath:
            modelId == null ? null : modelService.installedModelPaths[modelId],
      );
      await _recitationRecognizer.start();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isListening = false;
        _statusMessage =
            lang == 'en'
                ? 'Offline recitation engine is unavailable'
                : 'Mesin hafalan offline belum tersedia';
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  void _handleRecognitionResult(OfflineRecognitionResult result) {
    final lang = ref.read(settingsProvider).language;
    final displayText =
        result.transcript.isNotEmpty ? result.transcript : result.phonemes;

    setState(() {
      if (result.debugType == 'audio') {
        _debugMicLevel = result.micLevel;
        _debugPeakLevel = result.peakLevel;
        _debugAudioSamples = result.audioSamples;
        _debugAudioMessage = result.debugMessage;
      } else {
        _liveRecognizedWords = displayText;
      }
    });

    if (result.debugType == 'audio') return;

    final matchFound = _verifyStream([
      result.transcript,
      result.phonemes,
      ...result.alternatives,
    ]);

    if (!result.isFinal || matchFound) return;

    setState(() {
      _mistakeCount++;
      final sisaSkip = _skipThreshold - _mistakeCount;

      if (_mistakeCount < _hintThreshold) {
        _statusMessage =
            lang == 'en'
                ? "Wrong ($_mistakeCount). Try again!"
                : "Salah ($_mistakeCount). Ayo coba lagi!";
      } else if (_mistakeCount < _skipThreshold) {
        _statusMessage =
            lang == 'en'
                ? "Hint shown. Skip available in ${sisaSkip}x."
                : "Hint muncul. Skip aktif dalam ${sisaSkip}x.";
      } else {
        _statusMessage =
            lang == 'en'
                ? "6 mistakes. Skip button ACTIVE."
                : "Sudah 6x salah. Tombol Skip AKTIF.";
      }
      _isListening = false;
    });

    _pulseController.stop();
    _pulseController.reset();

    if (_mistakeCount < 10) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isListening) _startListening();
      });
    }
  }

  // Update logika saat stop manual atau ganti halaman
  void _stopListeningManual() {
    _recitationRecognizer.stop();
    _pulseController.stop(); // Stop animasi
    _pulseController.reset();
    setState(() {
      _isListening = false;
      _liveRecognizedWords = "";
      _debugMicLevel = 0;
      _debugPeakLevel = 0;
      _debugAudioSamples = 0;
      _debugAudioMessage = '';
    });
  }

  bool _verifyStream(List<String> hypotheses) {
    final lang = ref.read(settingsProvider).language;
    if (_currentIndex >= _targetWords.length) {
      _recitationRecognizer.stop();
      setState(
        () =>
            _statusMessage =
                lang == 'en'
                    ? "Page Complete! Total Skip: $_totalSkipCount"
                    : "Halaman Selesai! Total Skip: $_totalSkipCount",
      );
      return true;
    }

    final match = RecitationAlignment.align(
      hypotheses: hypotheses,
      targetWords: _targetWords,
      currentIndex: _currentIndex,
    );

    if (match.isMatch) {
      setState(() {
        _currentIndex += match.matchedWordCount;
        _statusMessage = lang == 'en' ? "Correct!" : "Benar!";
        _mistakeCount = 0;
      });

      _advanceToNextSpeakable();

      return true;
    }

    return false;
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
                    hintText: lang == 'en' ? 'e.g., Juz 30' : 'Contoh: Juz 30',
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
                            bookmark.pageNumber == null
                                ? "Surah • ${bookmark.surahName}"
                                : "Page. ${bookmark.pageNumber} • ${bookmark.surahName}",
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
    final lang = ref.read(settingsProvider).language;
    final newBookmark = Bookmark(
      type: BookmarkViewType.hafalan,
      surahId: _currentSurahId,
      surahName: _currentSurahName,
      ayahNumber: 1,
      pageNumber: _isSurahScope ? null : _currentPage,
    );
    await ref
        .read(bookmarkProvider.notifier)
        .addOrUpdateBookmark(name, newBookmark);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'en'
                ? "Memorization '$name' saved successfully!"
                : "Hafalan '$name' berhasil disimpan!",
          ),
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
    final ayahsAsync =
        _isSurahScope
            ? ref.watch(surahAyahsProvider(_currentSurah))
            : ref.watch(pageAyahsProvider(_currentPage));
    final settings = ref.watch(settingsProvider);
    final bookmarksMap = ref.watch(bookmarkProvider);
    final lang = settings.language;
    final isBookmarked = bookmarksMap.values.any(
      (b) =>
          b.type == BookmarkViewType.hafalan &&
          (_isSurahScope
              ? b.pageNumber == null && b.surahId == _currentSurah
              : b.pageNumber == _currentPage),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSurahScope
              ? (lang == 'en'
                  ? "Memorization Surah $_currentSurah"
                  : "Hafalan Surah $_currentSurah")
              : (lang == 'en'
                  ? "Memorization Pg. $_currentPage"
                  : "Hafalan Hal. $_currentPage"),
        ),
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
            icon: const Icon(Icons.model_training_outlined),
            tooltip:
                lang == 'en'
                    ? 'Offline recitation models'
                    : 'Model hafalan offline',
            onPressed: _openOfflineModelManager,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _changeUnit(_currentUnit),
          ),
        ],
      ),
      body: ayahsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                lang == 'en' ? "Failed to load: $e" : "Gagal memuat: $e",
              ),
            ),
        data: (ayahs) {
          _prepareData(ayahs);
          if (_targetWords.isEmpty) {
            return Center(
              child: Text(lang == 'en' ? "Empty data." : "Data ayat kosong."),
            );
          }
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
                                  : null,
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
    final settings = ref.watch(settingsProvider);
    final lang = settings.language;

    bool canSkip = _mistakeCount >= _skipThreshold;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLiveListeningPanel(),
          if (!_isRecognizerReady) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download_for_offline_outlined),
                label: Text(
                  lang == 'en'
                      ? 'Download offline model'
                      : 'Unduh model offline',
                ),
                onPressed: () {
                  _openOfflineModelManager(autoStartDownload: true);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _totalSkipCount > 0
                  ? "$_statusMessage • ${lang == 'en' ? 'Skip' : 'Skip'}: $_totalSkipCount"
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
                    _currentUnit < _lastUnit
                        ? () => _changeUnit(_currentUnit + 1)
                        : null,
              ),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_isListening) {
                        _stopListeningManual();
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
                                .withValues(alpha: 0.4),
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
                          canSkip
                              ? (lang == 'en' ? "Skip word" : "Skip kata ini")
                              : (lang == 'en'
                                  ? "6 mistakes to skip"
                                  : "Salah 6x untuk skip"),
                      onPressed: () {
                        if (canSkip) {
                          _skipCurrentWord();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                lang == 'en'
                                    ? "Can't skip yet! Try ${_skipThreshold - _mistakeCount} more times."
                                    : "Belum bisa skip! Coba ${_skipThreshold - _mistakeCount} kali lagi.",
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
                    _currentUnit > 1
                        ? () => _changeUnit(_currentUnit - 1)
                        : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveListeningPanel() {
    if (!_isListening && _liveRecognizedWords.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            // Ikon berdenyut
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 24),
              ),
            ),
            const SizedBox(height: 12),
            // Teks Live
            Text(
              _liveRecognizedWords.isEmpty ? "..." : _liveRecognizedWords,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl, // Karena bahasa Arab
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontFamily: 'LPMQ', // Pakai font arab jika ada
              ),
            ),
            const SizedBox(height: 14),
            _buildMicDebugMeter(),
          ],
        ),
      ),
    );
  }

  Widget _buildMicDebugMeter() {
    final levelPercent = (_debugMicLevel * 100)
        .clamp(0, 100)
        .toStringAsFixed(1);
    final peakPercent = (_debugPeakLevel * 100)
        .clamp(0, 100)
        .toStringAsFixed(1);
    final meterValue = _debugMicLevel.clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _debugMicLevel > 0.01
                    ? Icons.graphic_eq_rounded
                    : Icons.mic_none_rounded,
                size: 16,
                color: _debugMicLevel > 0.01 ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _debugAudioMessage.isEmpty
                      ? 'Debug mic: menunggu audio...'
                      : _debugAudioMessage,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: meterValue,
              minHeight: 7,
              backgroundColor: Colors.grey.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation<Color>(
                _debugMicLevel > 0.01 ? Colors.green : Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'RMS $levelPercent% • peak $peakPercent% • samples $_debugAudioSamples',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black45,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  void _changeUnit(int value) {
    final lang = ref.read(settingsProvider).language;
    setState(() {
      if (_isSurahScope) {
        _currentSurah = value;
      } else {
        _currentPage = value;
      }
      _targetWords = [];
      _currentIndex = 0;
      _mistakeCount = 0;
      _totalSkipCount = 0;
      _skippedIndices.clear();
      _wordKeys = [];
      _statusMessage = lang == 'en' ? "Ready for recitation?" : "Siap hafalan?";
      _isListening = false;
      _debugMicLevel = 0;
      _debugPeakLevel = 0;
      _debugAudioSamples = 0;
      _debugAudioMessage = '';
    });
    _recitationRecognizer.stop();
  }

  Future<void> _openOfflineModelManager({
    bool autoStartDownload = false,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                OfflineModelManagerScreen(autoStartDownload: autoStartDownload),
      ),
    );
    if (mounted) {
      _initOfflineRecognizer();
    }
  }

  String? _selectRecognizerModelId(Set<String> installedModelIds) {
    if (installedModelIds.contains('vosk_arabic')) return 'vosk_arabic';
    if (installedModelIds.contains('whisper_tiny_ar')) return 'whisper_tiny_ar';
    if (installedModelIds.contains('whisper_base_ar')) return 'whisper_base_ar';
    return installedModelIds.isEmpty ? null : installedModelIds.first;
  }
}
