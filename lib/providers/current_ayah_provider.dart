import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/repository/quran_repository.dart';
import 'package:quran_app/providers/player_provider.dart';

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

final currentAyahProvider = FutureProvider<Ayah?>((ref) async {
  final player = ref.watch(playerServiceProvider);

  if (player.currentSurah <= 0 ||
      player.currentAyah <= 0) {
    return null;
  }

  final repository = ref.read(quranRepositoryProvider);

  return repository.getAyah(
    surahId: player.currentSurah,
    ayahNumber: player.currentAyah,
  );
});