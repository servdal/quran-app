import 'dart:async';

import 'package:flutter/services.dart';

enum OfflineRecitationEngine { whisper, vosk }

class OfflineRecognitionResult {
  final String transcript;
  final String phonemes;
  final List<String> alternatives;
  final double confidence;
  final bool isFinal;

  const OfflineRecognitionResult({
    required this.transcript,
    required this.phonemes,
    required this.alternatives,
    required this.confidence,
    required this.isFinal,
  });

  factory OfflineRecognitionResult.fromMap(Map<dynamic, dynamic> map) {
    return OfflineRecognitionResult(
      transcript: (map['transcript'] ?? '') as String,
      phonemes: (map['phonemes'] ?? '') as String,
      alternatives:
          ((map['alternatives'] as List?) ?? const [])
              .whereType<String>()
              .toList(),
      confidence: ((map['confidence'] as num?) ?? 0).toDouble(),
      isFinal: (map['isFinal'] as bool?) ?? false,
    );
  }
}

class OfflineRecitationRecognizer {
  static const MethodChannel _controlChannel = MethodChannel(
    'quran_app/offline_recitation/control',
  );
  static const EventChannel _eventChannel = EventChannel(
    'quran_app/offline_recitation/events',
  );

  Stream<OfflineRecognitionResult>? _results;

  Stream<OfflineRecognitionResult> get results {
    return _results ??= _eventChannel.receiveBroadcastStream().map((event) {
      return OfflineRecognitionResult.fromMap(event as Map<dynamic, dynamic>);
    });
  }

  Future<bool> isAvailable() async {
    try {
      return await _controlChannel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> configure({
    OfflineRecitationEngine engine = OfflineRecitationEngine.whisper,
    required List<String> activeWords,
    required String expectedPhrase,
    String? modelId,
    String? modelPath,
  }) async {
    await _controlChannel.invokeMethod<void>('configure', {
      'engine': engine.name,
      'language': 'ar',
      'activeWords': activeWords,
      'expectedPhrase': expectedPhrase,
      'mode': 'guided_recitation_alignment',
      if (modelId != null) 'modelId': modelId,
      if (modelPath != null) 'modelPath': modelPath,
      'modelHints': const ['whisper_tiny', 'whisper_base', 'vosk_arabic'],
    });
  }

  Future<void> start() async {
    await _controlChannel.invokeMethod<void>('start');
  }

  Future<void> stop() async {
    try {
      await _controlChannel.invokeMethod<void>('stop');
    } on MissingPluginException {
      return;
    }
  }
}
