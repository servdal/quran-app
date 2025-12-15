import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quran_app/models/grammar_model.dart';

import '../models/ayah_model.dart';
import '../widgets/grammar_popup.dart';
import '../providers/settings_provider.dart';
import '../services/quran_data_service.dart';
import '../utils/tajweed_parser.dart';

/* ============================================================
   ENUM & HELPER
============================================================ */

enum GrammarType { fiil, isim, harf, other }

GrammarType detectGrammarType({
  required Grammar g,
  required bool isId,
}) {
  final d = (isId ? g.grammarDescId : g.grammarDescEn).toLowerCase();

  if (d.contains('fi') || d.contains('verb')) return GrammarType.fiil;
  if (d.contains('isim') || d.contains('noun')) return GrammarType.isim;
  if (d.contains('harf') || d.contains('particle')) return GrammarType.harf;

  return GrammarType.other;
}

/* ============================================================
   UI STATE (FILTER, MODE BELAJAR, HIGHLIGHT ROOT)
============================================================ */

class GrammarUiState {
  final GrammarType? filter;
  final bool highlightRoot;
  final bool learningMode;

  const GrammarUiState({
    this.filter,
    this.highlightRoot = false,
    this.learningMode = false,
  });

  GrammarUiState copyWith({
    GrammarType? filter,
    bool? highlightRoot,
    bool? learningMode,
  }) {
    return GrammarUiState(
      filter: filter,
      highlightRoot: highlightRoot ?? this.highlightRoot,
      learningMode: learningMode ?? this.learningMode,
    );
  }
}

class GrammarUiNotifier extends StateNotifier<GrammarUiState> {
  GrammarUiNotifier() : super(const GrammarUiState());

  void setFilter(GrammarType? t) => state = state.copyWith(filter: t);
  void toggleHighlightRoot() =>
      state = state.copyWith(highlightRoot: !state.highlightRoot);
  void toggleLearningMode() =>
      state = state.copyWith(learningMode: !state.learningMode);
}

final grammarUiProvider =
    StateNotifierProvider<GrammarUiNotifier, GrammarUiState>(
        (ref) => GrammarUiNotifier());

/* ============================================================
   PROVIDER: GRAMMAR PER AYAT
============================================================ */

final ayahWordsProvider = FutureProvider.family<
    List<Grammar>,
    ({int surahId, int ayahNumber})>((ref, param) {
  return ref
      .read(quranDataServiceProvider)
      .getAyahWords(param.surahId, param.ayahNumber);
});

/* ============================================================
   SCREEN
============================================================ */

class TafsirViewScreen extends ConsumerWidget {
  final int surahId;
  const TafsirViewScreen({super.key, required this.surahId});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahDetailProvider(surahId));

    return Scaffold(
      appBar: AppBar(
        title: surahAsync.when(
          data: (s) => Text('Tafsir ${s.surahName}'),
          loading: () => const Text('Memuat...'),
          error: (_, __) => const Text('Error'),
        ),
      ),
      body: surahAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (surah) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: surah.ayahs.length,
          itemBuilder: (context, index) {
            final ayah = surah.ayahs[index];
            return _AyahBlock(ayah: ayah, surahName: surah.surahName);
          },
        ),
      ),
    );
  }
}

/* ============================================================
   AYAH BLOCK
============================================================ */

class _AyahBlock extends ConsumerWidget {
  final Ayah ayah;
  final String surahName;
  
  const _AyahBlock({
    required this.ayah,
    required this.surahName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseStyle = TextStyle(
      fontFamily: 'LPMQ',
      fontSize: ref.watch(settingsProvider).arabicFontSize,
      height: 2.1,
    );

    final spans = TajweedParser.parse(ayah.tajweedText, baseStyle);

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AyahHeader(ayah: ayah, surahName: surahName),
            const SizedBox(height: 12),
            RichText(
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              text: TextSpan(children: spans),
            ),
            const SizedBox(height: 12),
            Text(
              ayah.translation,
              textAlign: TextAlign.justify,
            ),
            const Divider(height: 32),
            _GrammarSection(ayah: ayah),
            const Divider(height: 32),
            Text(
              'Tafsir Jalalayn:\n${ayah.tafsir}',
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   GRAMMAR SECTION
============================================================ */

class _GrammarSection extends ConsumerWidget {
  final Ayah ayah;
  const _GrammarSection({required this.ayah});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(grammarUiProvider);
    final isId = ref.watch(settingsProvider).language == 'id';
    final asyncWords = ref.watch(
      ayahWordsProvider(
        (surahId: ayah.id, ayahNumber: ayah.number),
      ),
    );

    return asyncWords.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text('Gagal memuat analisis: $e'),
      data: (words) {
        if (words.isEmpty) return const SizedBox.shrink();

        final filtered = ui.filter == null
            ? words
            : words
                .where((g) =>
                    detectGrammarType(g: g, isId: isId) == ui.filter)
                .toList();

        final rootCount = <String, int>{};
        for (var g in words) {
          rootCount[g.rootAr] = (rootCount[g.rootAr] ?? 0) + 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GrammarToolbar(),
            const SizedBox(height: 8),
            ...filtered.map((g) {
              final sameRoot = rootCount[g.rootAr]! > 1;
              return _GrammarCard(
                grammar: g,
                type: detectGrammarType(g: g, isId: isId),
                highlightRoot: ui.highlightRoot && sameRoot,
                learningMode: ui.learningMode,
              );
            }),
          ],
        );
      },
    );
  }
}

/* ============================================================
   TOOLBAR
============================================================ */

class _GrammarToolbar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ui = ref.watch(grammarUiProvider);
    final n = ref.read(grammarUiProvider.notifier);
    final isId = ref.watch(settingsProvider).language == 'id';
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      children: [
        _chip('Semua', ui.filter == null, () => n.setFilter(null)),
        _chip('Fi’il', ui.filter == GrammarType.fiil,
            () => n.setFilter(GrammarType.fiil)),
        _chip('Isim', ui.filter == GrammarType.isim,
            () => n.setFilter(GrammarType.isim)),
        _chip('Harf', ui.filter == GrammarType.harf,
            () => n.setFilter(GrammarType.harf)),
        _chip('Highlight Root', ui.highlightRoot, n.toggleHighlightRoot),
        _chip('Mode Belajar', ui.learningMode, n.toggleLearningMode),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/* ============================================================
   GRAMMAR CARD
============================================================ */

class _GrammarCard extends ConsumerWidget {
  final Grammar grammar;
  final GrammarType type;
  final bool highlightRoot;
  final bool learningMode;

  const _GrammarCard({
    required this.grammar,
    required this.type,
    required this.highlightRoot,
    required this.learningMode,
  });

  Color _color(BuildContext context) {
    switch (type) {
      case GrammarType.fiil:
        return Colors.red;
      case GrammarType.isim:
        return Colors.blue;
      case GrammarType.harf:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isId = ref.watch(settingsProvider).language == 'id';

    final meaning = isId ? grammar.meaningId : grammar.meaningEn;
    final grammarDesc =
        isId ? grammar.grammarDescId : grammar.grammarDescEn;

    return Card(
      color: highlightRoot
          ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
          : null,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        onTap: () => showDialog(
          context: context,
          builder: (_) => GrammarPopup(grammar: grammar),
        ),
        leading: CircleAvatar(
          backgroundColor: _color(context),
          child: Text(
            grammar.rootWordId.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          grammar.wordAr,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'LPMQ', fontSize: 22),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(meaning.isEmpty ? '-' : meaning),
            if (learningMode) ...[
              const SizedBox(height: 4),
              Text(isId
                  ? 'Akar: ${grammar.rootAr} (${grammar.rootCode})'
                  : 'Root: ${grammar.rootAr} (${grammar.rootEn})'),
              Text(grammarDesc),
            ],
          ],
        ),
        trailing: Chip(
          label: Text(grammarDesc),
          backgroundColor: _color(context).withOpacity(0.15),
        ),
      ),
    );
  }
}

/* ============================================================
   HEADER
============================================================ */

class _AyahHeader extends StatelessWidget {
  final Ayah ayah;
  final String surahName;

  const _AyahHeader({required this.ayah, required this.surahName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('QS ${ayah.id}:${ayah.number}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Icon(Icons.menu_book_outlined, color: Theme.of(context).primaryColor),
      ],
    );
  }
}
