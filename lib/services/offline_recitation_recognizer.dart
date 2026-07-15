import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

enum OfflineRecitationEngine { sherpaOnnx }

class OfflineRecognitionResult {
  final String transcript;
  final String phonemes;
  final List<String> alternatives;
  final double confidence;
  final bool isFinal;
  final String debugType;
  final String debugMessage;
  final double micLevel;
  final double peakLevel;
  final int audioSamples;

  const OfflineRecognitionResult({
    required this.transcript,
    required this.phonemes,
    required this.alternatives,
    required this.confidence,
    required this.isFinal,
    required this.debugType,
    required this.debugMessage,
    required this.micLevel,
    required this.peakLevel,
    required this.audioSamples,
  });
}

class OfflineRecitationRecognizer {
  static const int _sampleRate = 16000;
  static const int _maxSpeechSamples = _sampleRate * 8;
  static const int _minDecodeSamples = _sampleRate * 1;
  static const Duration _decodeInterval = Duration(milliseconds: 1800);
  static const double _speechRmsThreshold = 0.006;
  static const double _speechPeakThreshold = 0.025;

  static bool _bindingsInitialized = false;

  final _resultsController =
      StreamController<OfflineRecognitionResult>.broadcast();

  final List<double> _speechSamples = [];

  sherpa.OfflineRecognizer? _recognizer;
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _audioSubscription;
  Timer? _finalTimer;

  String? _configuredModelPath;
  bool _isListening = false;
  bool _isDecoding = false;
  bool _hasSpeechSinceLastFinal = false;
  DateTime _lastDecodeAt = DateTime.fromMillisecondsSinceEpoch(0);

  Stream<OfflineRecognitionResult> get results => _resultsController.stream;

  Future<bool> isAvailable() async {
    try {
      _initSherpaBindings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> configure({
    OfflineRecitationEngine engine = OfflineRecitationEngine.sherpaOnnx,
    required List<String> activeWords,
    required String expectedPhrase,
    String? modelId,
    String? modelPath,
  }) async {
    if (modelPath == null || modelPath.isEmpty) {
      throw StateError('Model Sherpa-ONNX belum dipilih.');
    }

    _initSherpaBindings();
    final modelFiles = await _resolveSherpaModelFiles(modelPath);
    if (modelFiles == null) {
      throw StateError('Folder model Sherpa-ONNX tidak valid.');
    }
    final resolved = modelFiles.root.path;

    if (_configuredModelPath == resolved && _recognizer != null) return;

    await stop();
    _recognizer?.free();
    _recognizer = null;

    _recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          whisper: sherpa.OfflineWhisperModelConfig(
            encoder: modelFiles.encoder.path,
            decoder: modelFiles.decoder.path,
            language: 'ar',
            task: 'transcribe',
            tailPaddings: -1,
          ),
          tokens: modelFiles.tokens.path,
          numThreads: math.max(1, Platform.numberOfProcessors ~/ 2),
          debug: false,
          provider: 'cpu',
        ),
      ),
    );
    _configuredModelPath = resolved;
  }

  Future<void> start() async {
    if (_isListening) return;
    if (_recognizer == null) {
      throw StateError('Recognizer Sherpa-ONNX belum dikonfigurasi.');
    }

    final recorder = AudioRecorder();
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) {
      await recorder.dispose();
      throw StateError('Izin mikrofon belum diberikan.');
    }

    _recorder = recorder;
    _speechSamples.clear();
    _hasSpeechSinceLastFinal = false;
    _isListening = true;

    final audioStream = await recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
        streamBufferSize: 3200,
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.voiceRecognition,
          manageBluetooth: false,
        ),
      ),
    );

    _audioSubscription = audioStream.listen(
      _handleAudioChunk,
      onError: (Object error) {
        _emitError(error.toString());
      },
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    _isListening = false;
    _finalTimer?.cancel();
    _finalTimer = null;
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    await _recorder?.stop().catchError((_) => null);
    await _recorder?.dispose().catchError((_) => null);
    _recorder = null;

    if (_hasSpeechSinceLastFinal &&
        _speechSamples.length >= _minDecodeSamples) {
      await _decodeCurrentBuffer(isFinal: true);
    }
    _speechSamples.clear();
    _hasSpeechSinceLastFinal = false;
  }

  void dispose() {
    unawaited(stop());
    _recognizer?.free();
    _recognizer = null;
    unawaited(_resultsController.close());
  }

  void _handleAudioChunk(Uint8List bytes) {
    if (!_isListening || bytes.length < 2) return;

    final samples = _pcm16ToFloat32(bytes);
    final level = _measureLevel(samples);

    _resultsController.add(
      OfflineRecognitionResult(
        transcript: '',
        phonemes: '',
        alternatives: const [],
        confidence: 0,
        isFinal: false,
        debugType: 'audio',
        debugMessage: 'Mic aktif',
        micLevel: level.rms,
        peakLevel: level.peak,
        audioSamples: samples.length,
      ),
    );

    if (level.rms < _speechRmsThreshold || level.peak < _speechPeakThreshold) {
      return;
    }

    _hasSpeechSinceLastFinal = true;
    _speechSamples.addAll(samples);
    if (_speechSamples.length > _maxSpeechSamples) {
      _speechSamples.removeRange(0, _speechSamples.length - _maxSpeechSamples);
    }

    _finalTimer?.cancel();
    _finalTimer = Timer(const Duration(milliseconds: 1100), () {
      if (_hasSpeechSinceLastFinal) {
        unawaited(_decodeCurrentBuffer(isFinal: true));
      }
    });

    final now = DateTime.now();
    if (_speechSamples.length >= _minDecodeSamples &&
        now.difference(_lastDecodeAt) >= _decodeInterval) {
      _lastDecodeAt = now;
      unawaited(_decodeCurrentBuffer(isFinal: false));
    }
  }

  Future<void> _decodeCurrentBuffer({required bool isFinal}) async {
    if (_isDecoding || _recognizer == null) return;
    if (_speechSamples.length < _minDecodeSamples) return;

    _isDecoding = true;
    final snapshot = Float32List.fromList(_speechSamples);
    try {
      final stream = _recognizer!.createStream();
      try {
        stream.acceptWaveform(samples: snapshot, sampleRate: _sampleRate);
        _recognizer!.decode(stream);
        final result = _recognizer!.getResult(stream);
        final transcript = _normalizeTranscript(result.text);
        if (transcript.isNotEmpty) {
          _resultsController.add(
            OfflineRecognitionResult(
              transcript: transcript,
              phonemes: transcript,
              alternatives: const [],
              confidence: 1,
              isFinal: isFinal,
              debugType: 'result',
              debugMessage: '',
              micLevel: 0,
              peakLevel: 0,
              audioSamples: snapshot.length,
            ),
          );
        }
      } finally {
        stream.free();
      }

      if (isFinal) {
        _speechSamples.clear();
        _hasSpeechSinceLastFinal = false;
      }
    } catch (error) {
      _emitError(error.toString());
    } finally {
      _isDecoding = false;
    }
  }

  Float32List _pcm16ToFloat32(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final sampleCount = bytes.length ~/ 2;
    final samples = Float32List(sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      samples[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return samples;
  }

  _AudioLevel _measureLevel(Float32List samples) {
    if (samples.isEmpty) return const _AudioLevel(0, 0);

    var sumSquares = 0.0;
    var peak = 0.0;
    for (final sample in samples) {
      final abs = sample.abs();
      peak = math.max(peak, abs);
      sumSquares += sample * sample;
    }
    return _AudioLevel(math.sqrt(sumSquares / samples.length), peak);
  }

  String _normalizeTranscript(String text) {
    return text
        .replaceAll(RegExp(r'<\|[^>]+?\|>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<_SherpaModelFiles?> _resolveSherpaModelFiles(String path) async {
    final root = Directory(path);
    if (!await root.exists()) return null;
    final rootFiles = await _sherpaWhisperModelFiles(root);
    if (rootFiles != null) return rootFiles;

    final pending = <Directory>[root];
    var scanned = 0;
    while (pending.isNotEmpty && scanned < 80) {
      final current = pending.removeAt(0);
      scanned++;
      try {
        await for (final entity in current.list(followLinks: false)) {
          if (entity is! Directory) continue;
          final files = await _sherpaWhisperModelFiles(entity);
          if (files != null) return files;
          pending.add(entity);
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  Future<_SherpaModelFiles?> _sherpaWhisperModelFiles(Directory dir) async {
    final encoder = await _findSherpaFile(
      dir,
      (name) => name.endsWith('encoder.int8.onnx') || name == 'encoder.onnx',
    );
    final decoder = await _findSherpaFile(
      dir,
      (name) => name.endsWith('decoder.int8.onnx') || name == 'decoder.onnx',
    );
    final tokens = await _findSherpaFile(
      dir,
      (name) => name.endsWith('tokens.txt'),
    );

    if (encoder == null || decoder == null || tokens == null) return null;
    return _SherpaModelFiles(
      root: dir,
      encoder: encoder,
      decoder: decoder,
      tokens: tokens,
    );
  }

  Future<File?> _findSherpaFile(
    Directory dir,
    bool Function(String name) matches,
  ) async {
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (matches(name)) return entity;
    }
    return null;
  }

  void _emitError(String message) {
    _resultsController.add(
      OfflineRecognitionResult(
        transcript: '',
        phonemes: '',
        alternatives: const [],
        confidence: 0,
        isFinal: true,
        debugType: 'error',
        debugMessage: message,
        micLevel: 0,
        peakLevel: 0,
        audioSamples: 0,
      ),
    );
  }

  void _initSherpaBindings() {
    if (_bindingsInitialized) return;
    sherpa.initBindings();
    _bindingsInitialized = true;
  }
}

class _AudioLevel {
  final double rms;
  final double peak;

  const _AudioLevel(this.rms, this.peak);
}

class _SherpaModelFiles {
  final Directory root;
  final File encoder;
  final File decoder;
  final File tokens;

  const _SherpaModelFiles({
    required this.root,
    required this.encoder,
    required this.decoder,
    required this.tokens,
  });
}
