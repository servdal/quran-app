// lib/screens/tafsir_view_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/models/surah_model.dart';
import 'package:quran_app/screens/sync_screen.dart';
import 'package:quran_app/services/surah_repository.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

class TafsirViewScreen extends ConsumerStatefulWidget {
  final int surahId;
  const TafsirViewScreen({super.key, required this.surahId});

  @override
  ConsumerState<TafsirViewScreen> createState() => _TafsirViewScreenState();
}

class _TafsirViewScreenState extends ConsumerState<TafsirViewScreen> {
  bool _isEditing = false;
  Surah? _editableSurah;
  Map<int, List<TextEditingController>> _wordControllers = {};

  @override
  void dispose() {
    _wordControllers.forEach((_, controllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    });
    super.dispose();
  }

  void _initializeControllers(Surah surah) {
    _wordControllers.forEach((_, controllers) {
      for (var controller in controllers) {
        controller.dispose();
      }
    });
    _wordControllers = {};
    for (var ayah in surah.ayahs) {
      _wordControllers[ayah.ayaId] = ayah.words
          .map((word) => TextEditingController(text: word.translation))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahDataProvider(widget.surahId));

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          // ignore: unnecessary_null_comparison
          data: (surah) => Text(surah != null ? "Tafsir ${surah.englishName}" : "Data Belum Tersedia"),
          loading: () => const Text("Memuat..."),
          error: (e, s) => const Text("Error"),
        ),
        actions: [
          surahAsync.when(
            data: (surah) {
              // ignore: unnecessary_null_comparison
              if (surah == null) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(_isEditing ? Icons.save_alt_rounded : Icons.edit_note_rounded),
                onPressed: () {
                  if (_isEditing) {
                    if (_editableSurah == null) return;
                    
                    // Salin data dari controller ke model
                    for (var ayah in _editableSurah!.ayahs) {
                      final controllers = _wordControllers[ayah.ayaId]!;
                      for (int i = 0; i < ayah.words.length; i++) {
                        ayah.words[i] = Word(
                          position: ayah.words[i].position,
                          arabic: ayah.words[i].arabic,
                          transliteration: ayah.words[i].transliteration,
                          translation: controllers[i].text,
                        );
                      }
                    }

                    // --- PERBAIKAN DI SINI ---
                    // Simpan data, DAN setelah selesai, perbarui state lokal dan refresh provider
                    final surahToUpdate = _editableSurah!;
                    ref.read(surahRepositoryProvider).updateSurah(surahToUpdate).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perubahan berhasil disimpan!")));
                      
                      // Perbarui state lokal dengan data yang baru saja disimpan
                      setState(() {
                        _editableSurah = surahToUpdate; 
                        _isEditing = false; // Keluar dari mode edit
                      });
                      
                      // Refresh provider untuk memastikan data di masa depan sinkron
                      ref.invalidate(surahDataProvider(widget.surahId));
                    });
                  } else {
                    _editableSurah = Surah.fromJson(surah.toJson());
                    _initializeControllers(_editableSurah!);
                    setState(() => _isEditing = true);
                  }
                },
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: surahAsync.when(
        data: (surah) {
          // ignore: unnecessary_null_comparison
          if (surah == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Data Belum Tersinkronisasi",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Data untuk surah ini belum ada di server. Silakan lakukan sinkronisasi terlebih dahulu.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const SyncScreen())
                        );
                      },
                      child: const Text("Buka Halaman Sinkronisasi"),
                    )
                  ],
                ),
              ),
            );
          }
          
          if (!_isEditing) {
            _editableSurah = surah;
            _initializeControllers(_editableSurah!);
          }

          if (_editableSurah == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _editableSurah!.ayahs.length,
            itemBuilder: (context, index) {
              final ayah = _editableSurah!.ayahs[index];
              final baseTextStyle = TextStyle(fontFamily: 'LPMQ', fontSize: 24, height: 2.2, color: Theme.of(context).colorScheme.onSurface);
              final textSpans = TajweedParser.parse(ayah.tajweedText, baseTextStyle);

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      text: TextSpan(style: baseTextStyle, children: textSpans),
                    ),
                    const SizedBox(height: 16),
                    _isEditing
                        ? _buildEditableWordByWord(ayah)
                        : _buildReadOnlyWordByWord(ayah),
                    const SizedBox(height: 16),
                    Text(
                      "Tafsir: ${ayah.tafsirJalalayn}",
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Divider(height: 32),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Gagal memuat data surah: $e")),
      ),
    );
  }

  Widget _buildReadOnlyWordByWord(Ayah ayah) {
    return Wrap(
      alignment: WrapAlignment.end,
      textDirection: TextDirection.rtl,
      spacing: 8.0,
      runSpacing: 4.0,
      children: ayah.words.map((word) {
        if (word.arabic.trim().length > 2) {
          return Column(
            children: [
              Text(word.arabic, style: const TextStyle(fontFamily: 'LPMQ', fontSize: 20)),
              Text(word.translation, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          );
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildEditableWordByWord(Ayah ayah) {
    final controllers = _wordControllers[ayah.ayaId] ?? [];
    return Wrap(
      alignment: WrapAlignment.end,
      textDirection: TextDirection.rtl,
      spacing: 8.0,
      runSpacing: 8.0,
      children: List.generate(ayah.words.length, (i) {
        final word = ayah.words[i];
        if (word.arabic.trim().length > 2) {
          return SizedBox(
            width: 100,
            child: Column(
              children: [
                Text(word.arabic, style: const TextStyle(fontFamily: 'LPMQ', fontSize: 20)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: (i < controllers.length) ? controllers[i] : null,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}