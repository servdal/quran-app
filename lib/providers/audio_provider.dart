import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quran_app/services/download_service.dart';

final audioIndexProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final jsonStr = await rootBundle.loadString('assets/audio/audio_index.json');
  return List<Map<String, dynamic>>.from(json.decode(jsonStr));
});

final downloadServiceProvider =
    ChangeNotifierProvider<DownloadService>((ref) {
  return DownloadService();
});