import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran_app/providers/download_provider.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  PlaylistItem? activePlaylist;
  int currentSurah = 0;
  int currentAyah = 0;

  MyAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).listen(_setPlaybackState);

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _handleNextAyah();
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

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
    activePlaylist = playlist;
    currentSurah = playlist.startSurah;
    currentAyah = playlist.startAyah;
    await _playCurrentFile();
  }

  Future<void> _playCurrentFile() async {
    if (activePlaylist == null) return;

    try {
      final directory = await getApplicationDocumentsDirectory();
      String sPad = currentSurah.toString().padLeft(3, '0');
      String aPad = currentAyah.toString().padLeft(3, '0');
      String folder = activePlaylist!.reciterName
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s\-]'), '')
          .replaceAll(' ', '_');
      String fullPath = '${directory.path}/quran_audio/$folder/$sPad$aPad.mp3';
      final file = File(fullPath);

      if (await file.exists()) {
        mediaItem.add(
          MediaItem(
            id: fullPath,
            album: "Murottal Per Ayat",
            title: "Surah $currentSurah : Ayat $currentAyah",
            artist: folder.split('_').join(' ').toUpperCase(),
          ),
        );

        await _player.setAudioSource(AudioSource.file(file.path));
        _player.play();
      } else {
        _setPlaybackState(
          playbackState.value.copyWith(
            playing: false,
            errorMessage:
                "Berkas ayat $currentAyah tidak ditemukan, melewati...",
          ),
        );
        _handleNextAyah();
      }
    } on PlayerException {
      await _notifyPlaybackError("Gagal memutar berkas: Audio rusak.");
    } catch (e) {
      // Menangkap eror sistem lainnya
      await _notifyPlaybackError("Terjadi kesalahan pemutaran lokal.");
    }
  }

  // Fungsi pembantu untuk mengirim notifikasi eror ke laci Android dan sistem UI
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
    if (!playbackState.isClosed) {
      playbackState.add(state);
    }
  }

  void _handleNextAyah() {
    if (activePlaylist == null) return;

    int nextSurah = currentSurah;
    int nextAyah = currentAyah + 1;
    bool isFinished = false;

    if (nextSurah > activePlaylist!.endSurah) {
      isFinished = true;
    } else if (nextSurah == activePlaylist!.endSurah &&
        nextAyah > activePlaylist!.endAyah) {
      isFinished = true;
    }

    if (isFinished) {
      if (activePlaylist!.isRepeat) {
        currentSurah = activePlaylist!.startSurah;
        currentAyah = activePlaylist!.startAyah;
        _playCurrentFile();
      } else {
        stop();
      }
    } else {
      currentSurah = nextSurah;
      currentAyah = nextAyah;
      _playCurrentFile();
    }
  }

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
      androidCompactActionIndices: const [1],
      processingState:
          const {
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
  final PlaylistItem? activePlaylist;
  final String? errorMessage;

  PlayerUIState({
    this.isPlaying = false,
    this.title = "",
    this.subtitle = "",
    this.activePlaylist,
    this.errorMessage,
  });
}

final playerServiceProvider =
    StateNotifierProvider<PlayerNotifier, PlayerUIState>((ref) {
      return PlayerNotifier();
    });

class PlayerNotifier extends StateNotifier<PlayerUIState> {
  MyAudioHandler? _handler;
  bool _isInitialized = false;

  PlayerNotifier() : super(PlayerUIState()) {
    _initAudioService();
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

      _handler!.playbackState.listen((playbackState) {
        state = PlayerUIState(
          isPlaying: playbackState.playing,
          title: _handler!.mediaItem.value?.title ?? "",
          subtitle: _handler!.mediaItem.value?.artist ?? "",
          activePlaylist: _handler!.activePlaylist,
          errorMessage: playbackState.errorMessage,
        );
      });
    } catch (e) {
      debugPrint("Gagal memuat sistem audio: $e");
      state = PlayerUIState(errorMessage: "Gagal memuat sistem audio: $e");
    }
  }

  void playPlaylist(PlaylistItem playlist) {
    if (!_isInitialized || _handler == null) {
      state = PlayerUIState(
        isPlaying: false,
        errorMessage: "Sistem audio sedang bersiap, silakan coba lagi.",
      );
      return;
    }
    _handler!.startPlaylist(playlist);
  }

  void togglePausePlay() {
    _handler?.pause();
  }

  void stop() {
    _handler?.stop();
  }

  void clearError() {
    state = PlayerUIState(
      isPlaying: state.isPlaying,
      title: state.title,
      subtitle: state.subtitle,
      activePlaylist: state.activePlaylist,
      errorMessage: null,
    );
  }
}
