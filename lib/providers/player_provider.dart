import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_app/providers/download_provider.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  static const List<int> _ayahCountsBySurah = [
    0, 7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52,
    99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69,
    60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37,
    35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14,
    11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50,
    40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11,
    8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
  ];

  final AudioPlayer _player = AudioPlayer();
  bool _isChangingTrack = false;

  PlaylistItem? activePlaylist;
  int currentSurah = 0;
  int currentAyah = 0;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).listen(_setPlaybackState);
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        unawaited(_runTrackChange(_skipToNextUnlocked));
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    _setPlaybackState(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  Future<void> startPlaylist(PlaylistItem playlist) async {
    await _runTrackChange(() async {
      activePlaylist = playlist;
      currentSurah = playlist.startSurah;
      currentAyah = playlist.startAyah;
      await _playCurrentFile();
    });
  }

  Future<void> _runTrackChange(Future<void> Function() action) async {
    if (_isChangingTrack) return;

    _isChangingTrack = true;
    try {
      await action();
    } finally {
      _isChangingTrack = false;
    }
  }

  static String buildAudioFileName(int surah, int ayah) {
    final sPad = surah.toString().padLeft(3, '0');
    final aPad = ayah.toString().padLeft(3, '0');
    return '$sPad$aPad.mp3';
  }

  Future<void> _playCurrentFile() async {
    if (activePlaylist == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final folder = activePlaylist!.reciterName
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(' ', '_');

      final fileName = buildAudioFileName(currentSurah, currentAyah);
      final fullPath = '${directory.path}/quran_audio/$folder/$fileName';
      final file = File(fullPath);

      if (await file.exists()) {
        mediaItem.add(
          MediaItem(
            id: fullPath,
            album: 'Murottal Per Ayat',
            title: 'Surah $currentSurah : Ayat $currentAyah',
            artist: folder.split('_').join(' ').toUpperCase(),
            extras: {
              'surah': currentSurah,
              'ayah': currentAyah,
              'fileName': fileName,
            },
          ),
        );

        // File murottal adalah file lokal. setFilePath lebih langsung dan
        // menghindari pembuatan AudioSource baru yang tidak diperlukan.
        await _player.setFilePath(file.path);

        // Volume video background diatur 0 secara terpisah. Pastikan volume
        // player murottal sendiri selalu penuh.
        await _player.setVolume(1.0);
        // play() completes only when playback ends, pauses, or stops. Keep
        // the track-change lock scoped to loading so completion can advance.
        unawaited(_playWithErrorHandling());
      } else {
        _setPlaybackState(
          playbackState.value.copyWith(
            playing: false,
            errorMessage: 'Berkas $fileName tidak ditemukan, melewati ayat ini...',
          ),
        );
        await _skipToNextUnlocked();
      }
    } on PlayerException catch (e) {
      debugPrint('PlayerException: ${e.message}');
      await _notifyPlaybackError('Gagal memutar berkas: Audio rusak.');
    } catch (e) {
      debugPrint('Audio error: $e');
      await _notifyPlaybackError('Terjadi kesalahan pemutaran lokal.');
    }
  }

  Future<void> _playWithErrorHandling() async {
    try {
      await _player.play();
    } on PlayerException catch (e) {
      debugPrint('PlayerException: ${e.message}');
      await _notifyPlaybackError('Gagal memutar berkas: Audio rusak.');
    } catch (e) {
      debugPrint('Audio error: $e');
      await _notifyPlaybackError('Terjadi kesalahan pemutaran lokal.');
    }
  }

  Future<void> _notifyPlaybackError(String message) async {
    await _player.stop();
    _setPlaybackState(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.error,
        errorMessage: message,
      ),
    );
  }

  void _setPlaybackState(PlaybackState state) {
    if (!playbackState.isClosed) playbackState.add(state);
  }

  bool _isAfterPlaylistEnd(int surah, int ayah) {
    if (activePlaylist == null) return true;
    if (surah > activePlaylist!.endSurah) return true;
    return surah == activePlaylist!.endSurah && ayah > activePlaylist!.endAyah;
  }

  bool _isBeforePlaylistStart(int surah, int ayah) {
    if (activePlaylist == null) return true;
    if (surah < activePlaylist!.startSurah) return true;
    return surah == activePlaylist!.startSurah && ayah < activePlaylist!.startAyah;
  }

  ({int surah, int ayah}) _nextAyahPosition(int surah, int ayah) {
    if (surah > 0 &&
        surah < _ayahCountsBySurah.length &&
        ayah >= _ayahCountsBySurah[surah]) {
      return (surah: surah + 1, ayah: 1);
    }
    return (surah: surah, ayah: ayah + 1);
  }

  ({int surah, int ayah}) _previousAyahPosition(int surah, int ayah) {
    if (ayah > 1) return (surah: surah, ayah: ayah - 1);

    if (surah > 1) {
      final previousSurah = surah - 1;
      return (
        surah: previousSurah,
        ayah: _ayahCountsBySurah[previousSurah],
      );
    }
    return (surah: 1, ayah: 1);
  }

  Future<void> _skipToNextUnlocked() async {
    if (activePlaylist == null) return;

    final next = _nextAyahPosition(currentSurah, currentAyah);

    if (_isAfterPlaylistEnd(next.surah, next.ayah)) {
      if (activePlaylist!.isRepeat) {
        currentSurah = activePlaylist!.startSurah;
        currentAyah = activePlaylist!.startAyah;
        await _playCurrentFile();
      } else {
        await stop();
      }
      return;
    }

    currentSurah = next.surah;
    currentAyah = next.ayah;
    await _playCurrentFile();
  }

  Future<void> _skipToPreviousUnlocked() async {
    if (activePlaylist == null) return;

    final previous = _previousAyahPosition(currentSurah, currentAyah);

    if (_isBeforePlaylistStart(previous.surah, previous.ayah)) {
      currentSurah = activePlaylist!.startSurah;
      currentAyah = activePlaylist!.startAyah;
    } else {
      currentSurah = previous.surah;
      currentAyah = previous.ayah;
    }

    await _playCurrentFile();
  }

  @override
  Future<void> skipToNext() => _runTrackChange(_skipToNextUnlocked);

  @override
  Future<void> skipToPrevious() => _runTrackChange(_skipToPreviousUnlocked);

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}

class PlayerUIState {
  final bool isPlaying;
  final String title;
  final String subtitle;
  final int currentSurah;
  final int currentAyah;
  final Duration position;
  final Duration duration;
  final PlaylistItem? activePlaylist;
  final String? errorMessage;

  const PlayerUIState({
    this.isPlaying = false,
    this.title = '',
    this.subtitle = '',
    this.currentSurah = 0,
    this.currentAyah = 0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.activePlaylist,
    this.errorMessage,
  });

  PlayerUIState copyWith({
    bool? isPlaying,
    String? title,
    String? subtitle,
    int? currentSurah,
    int? currentAyah,
    Duration? position,
    Duration? duration,
    PlaylistItem? activePlaylist,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerUIState(
      isPlaying: isPlaying ?? this.isPlaying,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyah: currentAyah ?? this.currentAyah,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      activePlaylist: activePlaylist ?? this.activePlaylist,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final playerServiceProvider =
    StateNotifierProvider<PlayerNotifier, PlayerUIState>((ref) {
  return PlayerNotifier();
});

class PlayerNotifier extends StateNotifier<PlayerUIState> {
  MyAudioHandler? _handler;
  bool _isInitialized = false;

  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  Duration _lastPublishedPosition = Duration.zero;

  PlayerNotifier() : super(const PlayerUIState()) {
    unawaited(_initAudioService());
  }

  Future<void> _initAudioService() async {
    try {
      _handler = await AudioService.init(
        builder: () => MyAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'alquran.duidev.com.audio.channel',
          androidNotificationChannelName: 'Pemutar Murottal Al-Quran',
          androidNotificationOngoing: true,
          androidShowNotificationBadge: true,
        ),
      );

      _isInitialized = true;

      _playbackSubscription = _handler!.playbackState.listen((playbackState) {
        state = state.copyWith(
          isPlaying: playbackState.playing,
          activePlaylist: _handler!.activePlaylist,
          errorMessage: playbackState.errorMessage,
        );
      });

      _mediaItemSubscription = _handler!.mediaItem.listen((item) {
        if (item == null) return;

        final extras = item.extras ?? const <String, dynamic>{};

        _lastPublishedPosition = Duration.zero;

        state = state.copyWith(
          title: item.title,
          subtitle: item.artist ?? '',
          currentSurah: (extras['surah'] as num?)?.toInt() ?? 0,
          currentAyah: (extras['ayah'] as num?)?.toInt() ?? 0,
          position: Duration.zero,
          activePlaylist: _handler!.activePlaylist,
          clearError: true,
        );
      });

      _positionSubscription = _handler!.positionStream.listen((position) {
        // Position stream dapat sangat sering mengirim event. Batasi update UI
        // supaya seluruh screen tidak rebuild puluhan kali per detik.
        final delta = (position - _lastPublishedPosition).abs();
        if (position != Duration.zero &&
            delta < const Duration(milliseconds: 200)) {
          return;
        }

        _lastPublishedPosition = position;
        state = state.copyWith(position: position);
      });

      _durationSubscription = _handler!.durationStream.listen((duration) {
        state = state.copyWith(duration: duration ?? Duration.zero);
      });
    } catch (e) {
      debugPrint('Gagal memuat sistem audio: $e');
      state = PlayerUIState(errorMessage: 'Gagal memuat sistem audio: $e');
    }
  }

  Future<void> playPlaylist(PlaylistItem playlist) async {
    if (!_isInitialized || _handler == null) {
      state = state.copyWith(
        isPlaying: false,
        errorMessage: 'Sistem audio sedang bersiap, silakan coba lagi.',
      );
      return;
    }
    await _handler!.startPlaylist(playlist);
  }

  Future<void> togglePausePlay() async {
    if (_handler == null) return;
    if (state.isPlaying) {
      await _handler!.pause();
    } else {
      await _handler!.play();
    }
  }

  Future<void> next() async => _handler?.skipToNext();
  Future<void> previous() async => _handler?.skipToPrevious();
  Future<void> seek(Duration position) async => _handler?.seek(position);
  Future<void> stop() async => _handler?.stop();

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _playbackSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }
}
