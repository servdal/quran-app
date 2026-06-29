import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OfflineRecitationModel {
  final String id;
  final String name;
  final String engine;
  final String sizeLabel;
  final bool recommended;

  const OfflineRecitationModel({
    required this.id,
    required this.name,
    required this.engine,
    required this.sizeLabel,
    this.recommended = false,
  });
}

enum OfflineModelDownloadState { idle, downloading, installed, failed }

class OfflineModelDownloadInfo {
  final OfflineModelDownloadState state;
  final double progress;
  final String message;

  const OfflineModelDownloadInfo({
    required this.state,
    required this.progress,
    this.message = '',
  });

  bool get isDownloading => state == OfflineModelDownloadState.downloading;
}

class OfflineRecitationModelService extends ChangeNotifier {
  static const MethodChannel _controlChannel = MethodChannel(
    'quran_app/offline_recitation/models',
  );
  static const EventChannel _downloadChannel = EventChannel(
    'quran_app/offline_recitation/model_downloads',
  );

  static const List<OfflineRecitationModel> availableModels = [
    OfflineRecitationModel(
      id: 'whisper_tiny_ar',
      name: 'Whisper Tiny Arabic',
      engine: 'Whisper',
      sizeLabel: '~75 MB',
      recommended: true,
    ),
    OfflineRecitationModel(
      id: 'whisper_base_ar',
      name: 'Whisper Base Arabic',
      engine: 'Whisper',
      sizeLabel: '~145 MB',
    ),
    OfflineRecitationModel(
      id: 'vosk_arabic',
      name: 'Vosk Arabic',
      engine: 'Vosk',
      sizeLabel: '~45-130 MB',
    ),
  ];

  final Map<String, OfflineModelDownloadInfo> _downloads = {};
  final Set<String> _installedModelIds = {};
  StreamSubscription<dynamic>? _downloadSubscription;

  bool _nativeAvailable = true;
  bool _isRefreshing = false;
  String _statusMessage = 'Memeriksa model offline...';

  bool get nativeAvailable => _nativeAvailable;
  bool get isRefreshing => _isRefreshing;
  String get statusMessage => _statusMessage;
  Set<String> get installedModelIds => Set.unmodifiable(_installedModelIds);

  OfflineModelDownloadInfo downloadInfo(String modelId) {
    if (_installedModelIds.contains(modelId)) {
      return const OfflineModelDownloadInfo(
        state: OfflineModelDownloadState.installed,
        progress: 1,
        message: 'Model siap digunakan',
      );
    }

    return _downloads[modelId] ??
        const OfflineModelDownloadInfo(
          state: OfflineModelDownloadState.idle,
          progress: 0,
        );
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      final ids = await _controlChannel.invokeMethod<List<dynamic>>(
        'installedModels',
      );
      _installedModelIds
        ..clear()
        ..addAll((ids ?? const []).whereType<String>());
      _nativeAvailable = true;
      _statusMessage =
          _installedModelIds.isEmpty
              ? 'Pilih model untuk mode hafalan offline'
              : 'Model offline siap digunakan';
      _ensureListening();
    } on MissingPluginException {
      _nativeAvailable = false;
      _statusMessage = 'Downloader model offline belum tersedia di native app';
    } catch (error) {
      _nativeAvailable = false;
      _statusMessage = 'Gagal memeriksa model: $error';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> downloadModel(String modelId) async {
    _downloads[modelId] = const OfflineModelDownloadInfo(
      state: OfflineModelDownloadState.downloading,
      progress: 0,
      message: 'Menyiapkan unduhan...',
    );
    notifyListeners();

    try {
      _ensureListening();
      await _controlChannel.invokeMethod<void>('downloadModel', {
        'modelId': modelId,
      });
      _nativeAvailable = true;
    } on MissingPluginException {
      _nativeAvailable = false;
      _downloads[modelId] = const OfflineModelDownloadInfo(
        state: OfflineModelDownloadState.failed,
        progress: 0,
        message: 'Native downloader belum dipasang',
      );
      notifyListeners();
    } catch (error) {
      _downloads[modelId] = OfflineModelDownloadInfo(
        state: OfflineModelDownloadState.failed,
        progress: 0,
        message: error.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> deleteModel(String modelId) async {
    try {
      await _controlChannel.invokeMethod<void>('deleteModel', {
        'modelId': modelId,
      });
      _installedModelIds.remove(modelId);
      _downloads.remove(modelId);
      notifyListeners();
    } catch (error) {
      _downloads[modelId] = OfflineModelDownloadInfo(
        state: OfflineModelDownloadState.failed,
        progress: downloadInfo(modelId).progress,
        message: error.toString(),
      );
      notifyListeners();
    }
  }

  void _ensureListening() {
    _downloadSubscription ??= _downloadChannel.receiveBroadcastStream().listen(
      _handleDownloadEvent,
      onError: (error) {
        _statusMessage = 'Progress unduhan tidak tersedia: $error';
        notifyListeners();
      },
    );
  }

  void _handleDownloadEvent(dynamic event) {
    if (event is! Map) return;

    final modelId = (event['modelId'] ?? '') as String;
    if (modelId.isEmpty) return;

    final rawState = (event['state'] ?? 'downloading') as String;
    final progress =
        ((event['progress'] as num?) ?? 0).toDouble().clamp(0, 1).toDouble();
    final message = (event['message'] ?? '') as String;
    final state = switch (rawState) {
      'installed' || 'complete' => OfflineModelDownloadState.installed,
      'failed' || 'error' => OfflineModelDownloadState.failed,
      _ => OfflineModelDownloadState.downloading,
    };

    if (state == OfflineModelDownloadState.installed) {
      _installedModelIds.add(modelId);
    }

    _downloads[modelId] = OfflineModelDownloadInfo(
      state: state,
      progress: state == OfflineModelDownloadState.installed ? 1 : progress,
      message: message,
    );
    _statusMessage =
        state == OfflineModelDownloadState.installed
            ? 'Model selesai diunduh'
            : 'Mengunduh model offline...';
    notifyListeners();
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }
}
