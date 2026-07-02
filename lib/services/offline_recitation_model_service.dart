import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class OfflineRecitationModel {
  final String id;
  final String name;
  final String engine;
  final String sizeLabel;
  final String fileName;
  final String sourceUrl;
  final bool archive;
  final bool recommended;

  const OfflineRecitationModel({
    required this.id,
    required this.name,
    required this.engine,
    required this.sizeLabel,
    required this.fileName,
    required this.sourceUrl,
    this.archive = false,
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
      sizeLabel: '~44 MB',
      fileName: 'ggml-tiny.bin',
      sourceUrl:
          'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
      recommended: true,
    ),
    OfflineRecitationModel(
      id: 'whisper_base_ar',
      name: 'Whisper Base Arabic',
      engine: 'Whisper',
      sizeLabel: '~148 MB',
      fileName: 'ggml-base.bin',
      sourceUrl:
          'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin',
    ),
    OfflineRecitationModel(
      id: 'vosk_arabic',
      name: 'Vosk Arabic',
      engine: 'Vosk',
      sizeLabel: '~318 MB',
      fileName: 'vosk-model-ar-mgb2-0.4.zip',
      sourceUrl:
          'https://alphacephei.com/vosk/models/vosk-model-ar-mgb2-0.4.zip',
      archive: true,
    ),
  ];

  final Dio _dio = Dio();
  final Map<String, OfflineModelDownloadInfo> _downloads = {};
  final Set<String> _installedModelIds = {};
  final Map<String, String> _installedModelPaths = {};
  final Set<String> _activeFlutterDownloads = {};
  StreamSubscription<dynamic>? _downloadSubscription;

  bool _nativeAvailable = true;
  bool _isRefreshing = false;
  String _statusMessage = 'Memeriksa model offline...';

  bool get nativeAvailable => _nativeAvailable;
  bool get isRefreshing => _isRefreshing;
  String get statusMessage => _statusMessage;
  Set<String> get installedModelIds => Set.unmodifiable(_installedModelIds);
  Map<String, String> get installedModelPaths =>
      Map.unmodifiable(_installedModelPaths);

  OfflineRecitationModel get recommendedModel {
    return availableModels.firstWhere(
      (model) => model.recommended,
      orElse: () => availableModels.first,
    );
  }

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
      await _loadLocalInstalledModels();
      _nativeAvailable = true;
      _statusMessage =
          _installedModelIds.isEmpty
              ? 'Pilih model untuk mode hafalan offline'
              : 'Model offline siap digunakan';
    } on MissingPluginException {
      _nativeAvailable = false;
      await _loadLocalInstalledModels();
      _statusMessage =
          _installedModelIds.isEmpty
              ? 'Model akan diunduh oleh aplikasi'
              : 'Model offline sudah tersimpan';
    } catch (error) {
      _nativeAvailable = false;
      await _loadLocalInstalledModels();
      _statusMessage = 'Gagal memeriksa model: $error';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> downloadModel(String modelId) async {
    final model = _modelById(modelId);
    if (model == null) return;

    if (_activeFlutterDownloads.contains(modelId)) return;

    _downloads[modelId] = const OfflineModelDownloadInfo(
      state: OfflineModelDownloadState.downloading,
      progress: 0,
      message: 'Menyiapkan unduhan...',
    );
    notifyListeners();

    try {
      await _controlChannel.invokeMethod<void>('downloadModel', {
        'modelId': modelId,
        'url': model.sourceUrl,
        'fileName': model.fileName,
        'archive': model.archive,
      });
      _nativeAvailable = true;
      _ensureNativeDownloadListening();
    } on MissingPluginException {
      _nativeAvailable = false;
      await _downloadWithFlutter(model);
    } catch (error) {
      if (_nativeAvailable) {
        _downloads[modelId] = OfflineModelDownloadInfo(
          state: OfflineModelDownloadState.failed,
          progress: 0,
          message: error.toString(),
        );
        notifyListeners();
      } else {
        await _downloadWithFlutter(model);
      }
    }
  }

  Future<void> ensureRecommendedModel() async {
    await refresh();
    if (_installedModelIds.isNotEmpty) return;
    final model = recommendedModel;
    if (downloadInfo(model.id).isDownloading) return;
    await downloadModel(model.id);
  }

  Future<void> deleteModel(String modelId) async {
    try {
      await _controlChannel.invokeMethod<void>('deleteModel', {
        'modelId': modelId,
      });
      _installedModelIds.remove(modelId);
      _installedModelPaths.remove(modelId);
      await _deleteLocalModel(modelId);
      _downloads.remove(modelId);
      notifyListeners();
    } on MissingPluginException {
      _nativeAvailable = false;
      _installedModelIds.remove(modelId);
      _installedModelPaths.remove(modelId);
      await _deleteLocalModel(modelId);
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

  Future<void> _downloadWithFlutter(OfflineRecitationModel model) async {
    _activeFlutterDownloads.add(model.id);
    try {
      final modelDir = await _modelDirectory(model);
      final downloadPath = '${modelDir.path}/${model.fileName}';
      await modelDir.create(recursive: true);

      if (await _canReuseDownloadedFile(model, downloadPath)) {
        _downloads[model.id] = OfflineModelDownloadInfo(
          state: OfflineModelDownloadState.downloading,
          progress: model.archive ? 0.94 : 1,
          message: 'Menggunakan file lokal ${model.fileName}',
        );
        _statusMessage = 'Melanjutkan instalasi model lokal...';
        notifyListeners();
      } else {
        await _dio.download(
          model.sourceUrl,
          downloadPath,
          onReceiveProgress: (received, total) {
            final progress = total <= 0 ? 0.0 : received / total;
            _downloads[model.id] = OfflineModelDownloadInfo(
              state: OfflineModelDownloadState.downloading,
              progress: progress.clamp(0, 1).toDouble(),
              message: 'Mengunduh ${model.fileName}',
            );
            _statusMessage = 'Mengunduh model offline...';
            notifyListeners();
          },
          options: Options(
            followRedirects: true,
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 20),
          ),
        );
        await _writeDownloadedChecksum(model, downloadPath);
      }

      var installedPath = downloadPath;
      if (model.archive) {
        _downloads[model.id] = const OfflineModelDownloadInfo(
          state: OfflineModelDownloadState.downloading,
          progress: 0.96,
          message: 'Mengekstrak model...',
        );
        notifyListeners();
        installedPath = await _extractArchive(model, downloadPath);
      }

      await _writeMarker(model, installedPath);
      await _registerLocalModelWithNative(model, installedPath);
      _installedModelIds.add(model.id);
      _installedModelPaths[model.id] = installedPath;
      _downloads[model.id] = OfflineModelDownloadInfo(
        state: OfflineModelDownloadState.installed,
        progress: 1,
        message: installedPath,
      );
      _statusMessage = 'Model offline siap digunakan';
      notifyListeners();
    } catch (error) {
      _downloads[model.id] = OfflineModelDownloadInfo(
        state: OfflineModelDownloadState.failed,
        progress: downloadInfo(model.id).progress,
        message: error.toString(),
      );
      _statusMessage = 'Unduhan model gagal';
      notifyListeners();
    } finally {
      _activeFlutterDownloads.remove(model.id);
    }
  }

  Future<void> _loadLocalInstalledModels() async {
    for (final model in availableModels) {
      final marker = await _markerFile(model);
      if (!await marker.exists()) continue;

      final path = await marker.readAsString();
      if (path.trim().isEmpty) continue;

      final exists =
          model.archive
              ? await Directory(path.trim()).exists()
              : await File(path.trim()).exists();
      if (!exists) continue;

      _installedModelIds.add(model.id);
      _installedModelPaths[model.id] = path.trim();
      _downloads[model.id] = OfflineModelDownloadInfo(
        state: OfflineModelDownloadState.installed,
        progress: 1,
        message: path.trim(),
      );
    }
  }

  Future<String> _extractArchive(
    OfflineRecitationModel model,
    String archivePath,
  ) async {
    final targetDir = Directory('${(await _modelDirectory(model)).path}/model');
    if (await targetDir.exists()) {
      await targetDir.delete(recursive: true);
    }
    await targetDir.create(recursive: true);

    await extractFileToDisk(archivePath, targetDir.path, bufferSize: 1024 * 64);

    final rootName = model.fileName.replaceAll('.zip', '');
    final nestedRoot = Directory('${targetDir.path}/$rootName');
    return await nestedRoot.exists() ? nestedRoot.path : targetDir.path;
  }

  Future<void> _writeMarker(
    OfflineRecitationModel model,
    String installedPath,
  ) async {
    final marker = await _markerFile(model);
    await marker.parent.create(recursive: true);
    await marker.writeAsString(installedPath);
  }

  Future<bool> _canReuseDownloadedFile(
    OfflineRecitationModel model,
    String filePath,
  ) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    if (await file.length() == 0) return false;

    final checksumFile = await _downloadChecksumFile(model);
    if (await checksumFile.exists()) {
      final expected = (await checksumFile.readAsString()).trim();
      final actual = await _sha256OfFile(file);
      if (expected == actual) return true;
      await file.delete();
      await checksumFile.delete();
      return false;
    }

    if (model.archive && !await _zipCanOpen(filePath)) {
      await file.delete();
      return false;
    }

    await _writeDownloadedChecksum(model, filePath);
    return true;
  }

  Future<void> _writeDownloadedChecksum(
    OfflineRecitationModel model,
    String filePath,
  ) async {
    final checksumFile = await _downloadChecksumFile(model);
    await checksumFile.parent.create(recursive: true);
    await checksumFile.writeAsString(await _sha256OfFile(File(filePath)));
  }

  Future<String> _sha256OfFile(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  Future<bool> _zipCanOpen(String filePath) async {
    InputFileStream? input;
    try {
      input = InputFileStream(filePath);
      ZipDecoder().decodeStream(input);
      return true;
    } catch (_) {
      return false;
    } finally {
      await input?.close();
    }
  }

  Future<void> _registerLocalModelWithNative(
    OfflineRecitationModel model,
    String installedPath,
  ) async {
    try {
      await _controlChannel.invokeMethod<void>('registerLocalModel', {
        'modelId': model.id,
        'engine': model.engine.toLowerCase(),
        'path': installedPath,
        'archive': model.archive,
      });
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> _deleteLocalModel(String modelId) async {
    final model = _modelById(modelId);
    if (model == null) return;

    final dir = await _modelDirectory(model);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  OfflineRecitationModel? _modelById(String modelId) {
    for (final model in availableModels) {
      if (model.id == modelId) return model;
    }
    return null;
  }

  Future<Directory> _modelsRootDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}/offline_recitation_models');
  }

  Future<Directory> _modelDirectory(OfflineRecitationModel model) async {
    final root = await _modelsRootDirectory();
    return Directory('${root.path}/${model.id}');
  }

  Future<File> _markerFile(OfflineRecitationModel model) async {
    final modelDir = await _modelDirectory(model);
    return File('${modelDir.path}/installed.path');
  }

  Future<File> _downloadChecksumFile(OfflineRecitationModel model) async {
    final modelDir = await _modelDirectory(model);
    return File('${modelDir.path}/${model.fileName}.sha256');
  }

  void _ensureNativeDownloadListening() {
    if (_downloadSubscription != null) return;

    try {
      _downloadSubscription = _downloadChannel.receiveBroadcastStream().listen(
        _handleDownloadEvent,
        onError: (error) {
          _downloadSubscription?.cancel();
          _downloadSubscription = null;
          _statusMessage =
              'Progress native tidak tersedia, gunakan unduhan aplikasi';
          notifyListeners();
        },
      );
    } on MissingPluginException {
      _nativeAvailable = false;
      _downloadSubscription = null;
    }
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
