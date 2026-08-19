import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/player_provider.dart';
import 'package:quran_app/repository/quran_repository.dart';

/// Sesuaikan bila lokasi asset maskot Anda berbeda.
const String kMurottalMascotAsset = 'assets/images/mascot.png';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

final currentPlayerAyahProvider = FutureProvider<Ayah?>((ref) async {
  final currentSurah = ref.watch(
    playerServiceProvider.select((player) => player.currentSurah),
  );
  final currentAyah = ref.watch(
    playerServiceProvider.select((player) => player.currentAyah),
  );

  if (currentSurah <= 0 || currentAyah <= 0) {
    return null;
  }

  return ref.read(quranRepositoryProvider).getAyah(
        surahId: currentSurah,
        ayahNumber: currentAyah,
      );
});

class MurottalPlayerScreen extends ConsumerStatefulWidget {
  const MurottalPlayerScreen({super.key});

  static Future<T?> open<T>(BuildContext context) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    if (!context.mounted) return null;

    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const MurottalPlayerScreen(),
      ),
    );
  }

  @override
  ConsumerState<MurottalPlayerScreen> createState() =>
      _MurottalPlayerScreenState();
}

class _MurottalPlayerScreenState
    extends ConsumerState<MurottalPlayerScreen>
    with TickerProviderStateMixin {
  late final AnimationController _beatController;
  late final AnimationController _phaseController;
  bool? _lastAnimationPlayingState;

  bool _showArabic = true;
  bool _showTransliteration = true;
  bool _showTranslation = true;

  static const String _backgroundPrefKey = 'murottal_background_video';

  static const List<Map<String, String?>> _backgroundOptions = [
    {
      'title': 'Background Default',
      'subtitle': 'Gradient biru bawaan aplikasi',
      'asset': null,
    },
    {
      'title': 'Dunia Bawah Laut',
      'subtitle': 'Keindahan bawah laut yang menenangkan',
      'asset': 'assets/video/video1.mp4',
    },
    {
      'title': 'Sungai',
      'subtitle': 'Tenang, asri dan menenangkan',
      'asset': 'assets/video/video2.mp4',
    },
    {
      'title': 'Deburan Ombak',
      'subtitle': 'Damai dan menenangkan, cocok untuk fokus',
      'asset': 'assets/video/video3.mp4',
    },
  ];

  VideoPlayerController? _backgroundVideoController;
  String? _backgroundVideoAsset;
  bool _useVideoBackground = false;
  bool _isChangingBackground = false;

  Timer? _controlsTimer;
  bool _showControls = true;
  bool _screenReady = false;

  static const Duration _controlsVisibleDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    _beatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );

    _phaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _prepareScreen();
  }


  void _syncBeatAnimations(bool isPlaying) {
    if (_lastAnimationPlayingState == isPlaying) return;
    _lastAnimationPlayingState = isPlaying;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (isPlaying) {
        if (!_beatController.isAnimating) {
          _beatController.repeat(reverse: true);
        }
        if (!_phaseController.isAnimating) {
          _phaseController.repeat();
        }
      } else {
        _beatController.stop();
        _phaseController.stop();
      }
    });
  }

  Future<void> _prepareScreen() async {
    // Stabilkan orientasi + immersive mode sebelum membuat Texture/Surface
    // VideoPlayer. Di Android emulator/perangkat tertentu, membuat decoder
    // saat viewport masih berubah dapat membuat playback pertama tidak loop
    // sampai terjadi rebuild berikutnya.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    if (!mounted) return;

    // Beri Flutter dua frame agar perubahan WindowInsets/viewport selesai.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    await _restoreSavedBackground();

    if (!mounted) return;

    setState(() {
      _screenReady = true;
      _showControls = true;
    });

    _restartControlsTimer();
  }

  void _restartControlsTimer() {
    _controlsTimer?.cancel();

    if (!_showControls && mounted) {
      setState(() => _showControls = true);
    }

    _controlsTimer = Timer(_controlsVisibleDuration, () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    if (!_screenReady) return;

    if (_showControls) {
      _controlsTimer?.cancel();
      setState(() => _showControls = false);
    } else {
      setState(() => _showControls = true);
      _restartControlsTimer();
    }
  }

  Future<void> _restoreSavedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_backgroundPrefKey);

    if (!mounted || saved == null || saved.isEmpty) {
      return;
    }

    final isKnownAsset = _backgroundOptions.any(
      (item) => item['asset'] == saved,
    );

    if (!isKnownAsset) {
      return;
    }

    await setBackgroundVideoAsset(
      saved,
      persist: false,
    );
  }

  Future<void> setBackgroundVideoAsset(
    String assetPath, {
    bool persist = true,
  }) async {
    if (_isChangingBackground) return;

    // Jangan membuat ulang ExoPlayer/MediaCodec bila background yang sama
    // sudah aktif. Rebuild ayat, progress, play/pause, dan toolbar tidak boleh
    // memicu re-inisialisasi video.
    final currentController = _backgroundVideoController;
    if (_useVideoBackground &&
        _backgroundVideoAsset == assetPath &&
        currentController != null &&
        currentController.value.isInitialized) {
      if (!currentController.value.isPlaying) {
        await currentController.play();
      }
      return;
    }

    if (mounted) {
      setState(() => _isChangingBackground = true);
    }

    final oldController = _backgroundVideoController;
    final oldAsset = _backgroundVideoAsset;
    final oldUseVideoBackground = _useVideoBackground;
    VideoPlayerController? newController;

    try {
      newController = VideoPlayerController.asset(
        assetPath,
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
        ),
      );

      // Siapkan decoder lebih dahulu, tetapi jangan play sebelum Texture
      // benar-benar terpasang pada widget tree.
      await newController.initialize();
      await newController.setVolume(0);
      await newController.setLooping(true);

      if (!mounted) {
        await newController.dispose();
        return;
      }

      setState(() {
        _backgroundVideoAsset = assetPath;
        _backgroundVideoController = newController;
        _useVideoBackground = true;
      });

      // Frame ini memasang VideoPlayer/Texture ke Surface Android.
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted || _backgroundVideoController != newController) {
        await newController.dispose();
        return;
      }

      // Mulai selalu dari frame pertama setelah Surface siap.
      await newController.seekTo(Duration.zero);
      await newController.play();

      if (persist) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_backgroundPrefKey, assetPath);
      }

      // Controller lama baru dilepas sesudah controller baru sudah hidup,
      // sehingga perpindahan background tidak menghasilkan frame kosong.
      if (oldController != null && oldController != newController) {
        await oldController.dispose();
      }
    } catch (e) {
      await newController?.dispose();

      // Bila controller baru gagal, jangan menyisakan referensi ke controller
      // yang sudah dibuang.
      if (mounted && _backgroundVideoController == newController) {
        setState(() {
          _backgroundVideoController = oldController;
          _backgroundVideoAsset = oldAsset;
          _useVideoBackground = oldUseVideoBackground;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Video background tidak dapat dibuka: $assetPath',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingBackground = false);
      }
    }
  }

  Future<void> clearBackgroundVideo({
    bool persist = true,
  }) async {
    if (_isChangingBackground) return;

    setState(() => _isChangingBackground = true);

    final oldController = _backgroundVideoController;

    if (mounted) {
      setState(() {
        _backgroundVideoController = null;
        _backgroundVideoAsset = null;
        _useVideoBackground = false;
      });
    }

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_backgroundPrefKey);
    }

    await oldController?.dispose();

    if (mounted) {
      setState(() => _isChangingBackground = false);
    }
  }

  Future<void> _selectBackground(String? assetPath) async {
    Navigator.of(context).pop();

    if (assetPath == null) {
      await clearBackgroundVideo();
    } else {
      await setBackgroundVideoAsset(assetPath);
    }
  }

  void _openBackgroundSelector() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF08162F),
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return _BackgroundPickerSheet(
          options: _backgroundOptions,
          selectedAsset:
              _useVideoBackground ? _backgroundVideoAsset : null,
          isChanging: _isChangingBackground,
          onSelected: (assetPath) async {
            Navigator.of(sheetContext).pop();

            if (assetPath == null) {
              await clearBackgroundVideo();
            } else {
              await setBackgroundVideoAsset(assetPath);
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _beatController.dispose();
    _phaseController.dispose();
    _backgroundVideoController?.dispose();

    // Screen lain boleh kembali memakai orientasi normal.
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  String _formatDuration(Duration value) {
    final secondsTotal = value.inSeconds < 0 ? 0 : value.inSeconds;
    final minutes = secondsTotal ~/ 60;
    final seconds = secondsTotal % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _openTextOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF08162F),
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(VoidCallback action) {
              setSheetState(action);
              setState(action);
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Icon(Icons.visibility_outlined, color: Colors.cyanAccent),
                        SizedBox(width: 10),
                        Text(
                          'Tampilan Teks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile.adaptive(
                      value: _showArabic,
                      activeColor: Colors.cyanAccent,
                      title: const Text('Teks Arab'),
                      onChanged: (value) =>
                          update(() => _showArabic = value),
                    ),
                    SwitchListTile.adaptive(
                      value: _showTransliteration,
                      activeColor: Colors.cyanAccent,
                      title: const Text('Transliterasi'),
                      onChanged: (value) =>
                          update(() => _showTransliteration = value),
                    ),
                    SwitchListTile.adaptive(
                      value: _showTranslation,
                      activeColor: Colors.cyanAccent,
                      title: const Text('Terjemahan'),
                      onChanged: (value) =>
                          update(() => _showTranslation = value),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerServiceProvider);
    final ayahAsync = ref.watch(currentPlayerAyahProvider);

    // Beat/equalizer hanya berjalan ketika murottal benar-benar playing.
    _syncBeatAnimations(player.isPlaying);

    if (!_screenReady) {
      return const Scaffold(
        backgroundColor: Color(0xFF020817),
        body: SizedBox.expand(),
      );
    }

    final durationMs = player.duration.inMilliseconds;
    final positionMs = player.position.inMilliseconds;
    final progress = durationMs <= 0
        ? 0.0
        : (positionMs / durationMs).clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF020817),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (_showControls) {
            _restartControlsTimer();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _toggleControls,
          child: Stack(
            children: [
              Positioned.fill(
                child: _MurottalBackground(
                  videoController:
                      _useVideoBackground ? _backgroundVideoController : null,
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: ayahAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, _) => Center(
                      child: Text(
                        'Gagal membaca data ayat:\\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    data: (ayah) => _buildMainContent(
                      player: player,
                      ayah: ayah,
                      controlsVisible: _showControls,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    offset: _showControls
                        ? Offset.zero
                        : const Offset(0, -1.15),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _showControls ? 1 : 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                          child: _TopBar(
                            player: player,
                            onClose: () => Navigator.of(context).maybePop(),
                            onTextOptions: () {
                              _controlsTimer?.cancel();
                              _openTextOptions();
                            },
                            onBackgroundOptions: () {
                              _controlsTimer?.cancel();
                              _openBackgroundSelector();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 18,
                right: 18,
                bottom: 10,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    offset: _showControls
                        ? Offset.zero
                        : const Offset(0, 1.25),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _showControls ? 1 : 0,
                      child: SafeArea(
                        top: false,
                        child: _PlayerBar(
                          player: player,
                          progress: progress,
                          formatDuration: _formatDuration,
                          onSeek: (value) {
                            _restartControlsTimer();
                            if (player.duration <= Duration.zero) return;
                            final target = Duration(
                              milliseconds:
                                  (player.duration.inMilliseconds * value)
                                      .round(),
                            );
                            ref.read(playerServiceProvider.notifier).seek(target);
                          },
                          onPrevious: () {
                            _restartControlsTimer();
                            ref.read(playerServiceProvider.notifier).previous();
                          },
                          onPlayPause: () {
                            _restartControlsTimer();
                            ref
                                .read(playerServiceProvider.notifier)
                                .togglePausePlay();
                          },
                          onNext: () {
                            _restartControlsTimer();
                            ref.read(playerServiceProvider.notifier).next();
                          },
                          onTextOptions: () {
                            _controlsTimer?.cancel();
                            _openTextOptions();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent({
    required PlayerUIState player,
    required Ayah? ayah,
    required bool controlsVisible,
  }) {
    final surahName = ayah?.surahName.trim().isNotEmpty == true
        ? ayah!.surahName
        : 'Surah ${player.currentSurah}';

    final transliteration =
        ayah?.transliterationKemenag.trim().isNotEmpty == true
            ? ayah!.transliterationKemenag
            : (ayah?.transliteration ?? '');

    return LayoutBuilder(
      builder: (context, constraints) {
        // Compact berdasarkan ruang NYATA yang tersedia setelah top bar + player bar,
        // bukan tinggi layar keseluruhan. Ini mencegah bottom overflow.
        final compact = constraints.maxHeight < 620;
        final veryCompact = constraints.maxHeight < 500;

        final beatHeight = veryCompact ? 78.0 : (compact ? 100.0 : 128.0);
        final arabicSize = veryCompact ? 25.0 : (compact ? 31.0 : 39.0);
        final translitSize = veryCompact ? 13.0 : (compact ? 15.0 : 18.0);
        final translationSize = veryCompact ? 12.0 : (compact ? 13.5 : 15.5);

        return Row(
          children: [
            IgnorePointer(
              ignoring: !controlsVisible,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: controlsVisible ? 1 : 0,
                child: SizedBox(
                  width: compact ? 58 : 74,
                  child: Center(
                    child: _SideButton(
                      icon: Icons.chevron_left_rounded,
                      tooltip: 'Ayat sebelumnya',
                      size: compact ? 50 : 58,
                      onTap: () {
                        _restartControlsTimer();
                        ref.read(playerServiceProvider.notifier).previous();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      surahName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        shadows: const [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      player.subtitle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10.5 : 12,
                        color: Colors.white.withValues(alpha: .78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: compact ? 2 : 5),

                    // Beat animation mendapat tinggi terbatas, sehingga tidak
                    // mendorong teks ke bawah.
                    SizedBox(
                      height: beatHeight,
                      width: math.min(constraints.maxWidth * .78, 850),
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _beatController,
                          _phaseController,
                        ]),
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _BeatPainter(
                              beat: player.isPlaying
                                  ? _beatController.value
                                  : .12,
                              phase: player.isPlaying
                                  ? _phaseController.value
                                  : 0,
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: compact ? 1 : 3),
                    _VerseBadge(
                      number: player.currentAyah,
                      size: compact ? 42 : 48,
                    ),

                    // Sisa tinggi diberikan ke area teks. FittedBox scaleDown
                    // menjaga semua teks tetap terlihat tanpa overflow.
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.min(
                                constraints.maxWidth - (compact ? 140 : 190),
                                1000,
                              ),
                            ),
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 220),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_showArabic) ...[
                                    SizedBox(height: compact ? 2 : 5),
                                    Text(
                                      ayah?.arabicText ?? '',
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: arabicSize,
                                        height: 1.45,
                                        fontWeight: FontWeight.w600,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            offset: Offset(0, 2),
                                            blurRadius: 7,
                                          ),
                                          Shadow(
                                            color: Color(0x5523D7FF),
                                            blurRadius: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (_showTransliteration) ...[
                                    SizedBox(height: compact ? 2 : 5),
                                    Text(
                                      transliteration,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: translitSize,
                                        height: 1.25,
                                        color: const Color(0xFF39F3B3),
                                        fontWeight: FontWeight.w700,
                                        shadows: const [
                                          Shadow(
                                            color: Colors.black87,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  if (_showTranslation) ...[
                                    SizedBox(height: compact ? 4 : 7),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 12 : 18,
                                        vertical: compact ? 6 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: .20),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: .06),
                                        ),
                                      ),
                                      child: Text(
                                        ayah?.translation ?? '',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: translationSize,
                                          height: 1.35,
                                          color: Colors.white.withValues(alpha: .96),
                                          fontWeight: FontWeight.w500,
                                          shadows: const [
                                            Shadow(
                                              color: Colors.black87,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !controlsVisible,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: controlsVisible ? 1 : 0,
                child: SizedBox(
                  width: compact ? 58 : 74,
                  child: Center(
                    child: _SideButton(
                      icon: Icons.chevron_right_rounded,
                      tooltip: 'Ayat berikutnya',
                      size: compact ? 50 : 58,
                      onTap: () {
                        _restartControlsTimer();
                        ref.read(playerServiceProvider.notifier).next();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.player,
    required this.onClose,
    required this.onTextOptions,
    required this.onBackgroundOptions,
  });

  final PlayerUIState player;
  final VoidCallback onClose;
  final VoidCallback onTextOptions;
  final VoidCallback onBackgroundOptions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SideButton(
          icon: Icons.keyboard_arrow_down_rounded,
          tooltip: 'Kembali',
          onTap: onClose,
          size: 50,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          height: 48,
          child: Image.asset(
            kMurottalMascotAsset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy_outlined,
              color: Colors.cyanAccent,
              size: 34,
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DuiDev',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                height: 1,
                fontWeight: FontWeight.w800,
                shadows: [
                  Shadow(color: Colors.black54, blurRadius: 6),
                ],
              ),
            ),
            SizedBox(height: 3),
            Text(
              'MUROTTAL PLAYER',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.45,
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        if (player.currentSurah > 0)
          Text(
            '${player.currentSurah.toString().padLeft(3, '0')}'
            '${player.currentAyah.toString().padLeft(3, '0')}.mp3',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        const SizedBox(width: 15),
        _SideButton(
          icon: Icons.video_library_outlined,
          tooltip: 'Pilih background video',
          onTap: onBackgroundOptions,
          size: 50,
        ),
        const SizedBox(width: 8),
        _SideButton(
          icon: Icons.visibility_outlined,
          tooltip: 'Show / hide teks',
          onTap: onTextOptions,
          size: 50,
        ),
      ],
    );
  }
}

class _PlayerBar extends StatelessWidget {
  const _PlayerBar({
    required this.player,
    required this.progress,
    required this.formatDuration,
    required this.onSeek,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onTextOptions,
  });

  final PlayerUIState player;
  final double progress;
  final String Function(Duration) formatDuration;
  final ValueChanged<double> onSeek;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onTextOptions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xB8081730),
        border: Border.all(
          color: const Color(0xFF4D7CFE).withValues(alpha: .16),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Text(
              formatDuration(player.position),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: Colors.cyanAccent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.white,
                overlayColor: Colors.cyanAccent.withValues(alpha: .12),
              ),
              child: Slider(
                value: progress,
                onChanged: player.duration > Duration.zero ? onSeek : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              formatDuration(player.duration),
              style: TextStyle(
                color: Colors.white.withValues(alpha: .48),
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 20),
          IconButton(
            tooltip: 'Sebelumnya',
            onPressed: onPrevious,
            icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
            iconSize: 34,
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF00D7FF),
                    Color(0xFF6B4EFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D7FF).withValues(alpha: .23),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF071731),
                ),
                child: Icon(
                  player.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 38,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Berikutnya',
            onPressed: onNext,
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
            iconSize: 34,
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Tampilan teks',
            onPressed: onTextOptions,
            icon: const Icon(Icons.translate_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _VerseBadge extends StatelessWidget {
  const _VerseBadge({
    required this.number,
    this.size = 48,
  });

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF74BFFF),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: .10),
            blurRadius: 15,
          ),
        ],
      ),
      child: Text(
        number > 0 ? '$number' : '-',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
          shadows: [
            Shadow(color: Colors.black87, blurRadius: 5),
          ],
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 58,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xB8081730),
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: .22),
              ),
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}



class _BackgroundPickerSheet extends StatelessWidget {
  const _BackgroundPickerSheet({
    required this.options,
    required this.selectedAsset,
    required this.isChanging,
    required this.onSelected,
  });

  final List<Map<String, String?>> options;
  final String? selectedAsset;
  final bool isChanging;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: math.min(height * .74, 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Icon(Icons.video_library_outlined, color: Colors.cyanAccent),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih Background',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Thumbnail otomatis',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.35,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final asset = option['asset'];
                    final title = option['title'] ?? 'Background';
                    final subtitle = option['subtitle'] ?? '';

                    final selected = asset == null
                        ? selectedAsset == null
                        : selectedAsset == asset;

                    return _BackgroundOptionCard(
                      asset: asset,
                      title: title,
                      subtitle: subtitle,
                      selected: selected,
                      enabled: !isChanging,
                      onTap: () => onSelected(asset),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundOptionCard extends StatelessWidget {
  const _BackgroundOptionCard({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String? asset;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? const Color(0xFF12325B)
                : Colors.white.withValues(alpha: .035),
            border: Border.all(
              color: selected
                  ? Colors.cyanAccent
                  : Colors.white.withValues(alpha: .08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: asset == null
                    ? const _DefaultBackgroundThumbnail()
                    : _VideoThumbnail(assetPath: asset!),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.cyanAccent,
                              size: 20,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.25,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DefaultBackgroundThumbnail extends StatelessWidget {
  const _DefaultBackgroundThumbnail();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.2,
              colors: [
                Color(0xFF0A2250),
                Color(0xFF041329),
                Color(0xFF020817),
              ],
            ),
          ),
        ),
        const Center(
          child: Icon(
            Icons.gradient_rounded,
            color: Colors.cyanAccent,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  const _VideoThumbnail({
    required this.assetPath,
  });

  final String assetPath;

  @override
  State<_VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final controller = VideoPlayerController.asset(
      widget.assetPath,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
      ),
    );

    try {
      await controller.initialize();
      await controller.setVolume(0);

      final duration = controller.value.duration;
      final previewPosition =
          duration > const Duration(milliseconds: 600)
              ? const Duration(milliseconds: 500)
              : Duration.zero;

      await controller.seekTo(previewPosition);
      await controller.pause();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
      });
    } catch (_) {
      await controller.dispose();

      if (mounted) {
        setState(() {
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (_failed) {
      return const ColoredBox(
        color: Color(0xFF07152D),
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Colors.white38,
          ),
        ),
      );
    }

    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Color(0xFF07152D),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.cyanAccent,
            ),
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        Container(
          color: Colors.black.withValues(alpha: .14),
        ),
        const Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x99020817),
            ),
            child: Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MurottalBackground extends StatelessWidget {
  const _MurottalBackground({
    required this.videoController,
  });

  final VideoPlayerController? videoController;

  @override
  Widget build(BuildContext context) {
    final controller = videoController;
    final hasVideo =
        controller != null && controller.value.isInitialized;

    if (!hasVideo) {
      return const _Background();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: const Color(0xFF020817),
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: controller.value.size.width,
              height: controller.value.size.height,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        // Overlay gelap supaya teks tetap terbaca di atas video.
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99020817),
                Color(0x77041329),
                Color(0xAA020817),
              ],
              stops: [0, .48, 1],
            ),
          ),
        ),

        // Motif sangat tipis tetap dipertahankan agar identitas UI tidak hilang.
        CustomPaint(
          painter: _PatternPainter(),
        ),
      ],
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.18),
          radius: 1.18,
          colors: [
            Color(0xFF0A2250),
            Color(0xFF041329),
            Color(0xFF020817),
          ],
          stops: [0, .55, 1],
        ),
      ),
      child: CustomPaint(painter: _PatternPainter()),
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: .025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const step = 44.0;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        final p = Path()
          ..moveTo(x + step * .5, y)
          ..lineTo(x + step, y + step * .25)
          ..lineTo(x + step * .75, y + step * .5)
          ..lineTo(x + step, y + step * .75)
          ..lineTo(x + step * .5, y + step)
          ..lineTo(x, y + step * .75)
          ..lineTo(x + step * .25, y + step * .5)
          ..lineTo(x, y + step * .25)
          ..close();
        canvas.drawPath(p, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BeatPainter extends CustomPainter {
  const _BeatPainter({
    required this.beat,
    required this.phase,
  });

  final double beat;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.height * .28, 54.0);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00D7FF),
          Color(0xFF4F7BFF),
          Color(0xFF8F4DFF),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius + 20),
      );

    canvas.drawCircle(center, radius + beat * 6, ring);

    const barCount = 9;
    const barWidth = 8.0;
    const gap = 5.0;
    final totalWidth = barCount * barWidth + (barCount - 1) * gap;
    final startX = center.dx - totalWidth / 2;

    final eqPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF23E7FF),
          Color(0xFF5B62FF),
          Color(0xFF9D4DFF),
        ],
      ).createShader(
        Rect.fromCenter(center: center, width: totalWidth, height: 82),
      );

    for (var i = 0; i < barCount; i++) {
      final wave =
          .35 +
          .65 *
              ((math.sin(i * .82 + phase * math.pi * 2 + beat * 2) + 1) / 2);
      final h = 18 + wave * 52;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            startX + i * (barWidth + gap),
            center.dy - h / 2,
            barWidth,
            h,
          ),
          const Radius.circular(3),
        ),
        eqPaint,
      );
    }

    final wavePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00CCFF),
          Color(0xFF4D7CFE),
          Color(0xFF9A4DFF),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    const barsPerSide = 24;
    final sideStart = radius + 35;

    for (int side = -1; side <= 1; side += 2) {
      for (var i = 0; i < barsPerSide; i++) {
        final normalized = i / barsPerSide;
        final amplitude =
            5 +
            27 *
                (1 - normalized) *
                (.3 +
                    .7 *
                        ((math.sin(
                                      i * .85 +
                                          phase * math.pi * 2 +
                                          (side == -1 ? 0 : 1.2),
                                    ) +
                                    1) /
                                2)) *
                (.45 + beat * .55);

        final available = size.width / 2 - sideStart - 10;
        final x = center.dx +
            side * (sideStart + i * (available / barsPerSide));

        canvas.drawLine(
          Offset(x, center.dy - amplitude),
          Offset(x, center.dy + amplitude),
          wavePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BeatPainter oldDelegate) {
    return oldDelegate.beat != beat || oldDelegate.phase != phase;
  }
}
