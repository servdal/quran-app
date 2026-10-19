import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:quran_app/models/grammar_model.dart';
import 'package:quran_app/utils/arabic_source_spans.dart';

import '../models/ayah_model.dart';
import '../widgets/grammar_popup.dart';
import '../providers/settings_provider.dart';
import '../services/quran_data_service.dart';

/* ============================================================
   ENUM & HELPER
============================================================ */

enum GrammarType { fiil, isim, harf, other }

GrammarType detectGrammarType({required Grammar g, required bool isId}) {
  final localized = isId ? g.grammarDescId : g.grammarDescEn;
  final d =
      (localized.trim().isEmpty ? g.grammarDescEn : localized).toLowerCase();

  if (d.contains('fi') || d.contains('verb')) return GrammarType.fiil;
  if (d.contains('isim') || d.contains('noun')) return GrammarType.isim;
  if (d.contains('harf') || d.contains('particle')) return GrammarType.harf;

  return GrammarType.other;
}

String tr(WidgetRef ref, {required String id, required String en}) {
  final lang = ref.read(settingsProvider).language;
  return lang == 'id' ? id : en;
}
/* ============================================================
   UI STATE (FILTER, MODE BELAJAR, HIGHLIGHT ROOT)
============================================================ */

class GrammarUiState {
  final GrammarType? filter;
  final bool highlightRoot;
  final bool learningMode;

  // 🆕 tajwid highlight
  final String? activeTajweedKey;

  const GrammarUiState({
    this.filter,
    this.highlightRoot = false,
    this.learningMode = false,
    this.activeTajweedKey,
  });

  GrammarUiState copyWith({
    GrammarType? filter,
    bool? highlightRoot,
    bool? learningMode,
    String? activeTajweedKey,
  }) {
    return GrammarUiState(
      filter: filter,
      highlightRoot: highlightRoot ?? this.highlightRoot,
      learningMode: learningMode ?? this.learningMode,
      activeTajweedKey: activeTajweedKey,
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
  void setActiveTajweed(String? key) =>
      state = state.copyWith(activeTajweedKey: key);
}

final grammarUiProvider =
    StateNotifierProvider<GrammarUiNotifier, GrammarUiState>(
      (ref) => GrammarUiNotifier(),
    );

/* ============================================================
   PROVIDER: GRAMMAR PER AYAT
============================================================ */

final ayahWordsProvider =
    FutureProvider.family<List<Grammar>, ({int surahId, int ayahNumber})>((
      ref,
      param,
    ) {
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
          data:
              (s) => Text(
                'QS ${s.surahName}',
                style: const TextStyle(
                  fontFamily: 'Roboto', // Menggunakan font Roboto
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
          loading:
              () => Text(
                tr(ref, id: 'Memuat...', en: 'Loading...'),
                style: const TextStyle(fontFamily: 'Roboto'),
              ),
          error:
              (_, _) =>
                  const Text('Error', style: TextStyle(fontFamily: 'Roboto')),
        ),
      ),
      body: surahAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data:
            (surah) => ListView.builder(
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

  const _AyahBlock({required this.ayah, required this.surahName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final source = settings.arabicSource;

    final baseStyle = TextStyle(
      fontFamily: source.arabicFontFamily,
      fontSize: settings.arabicFontSize,
      height: 2.1,
      color: Theme.of(context).colorScheme.onSurface,
    );

    final ui = ref.watch(grammarUiProvider);
    final notifier = ref.read(grammarUiProvider.notifier);
    final lang = ref.watch(settingsProvider).language;
    final spans = buildArabicSourceSpans(
      source: source,
      quranCloudText: ayah.arabicText,
      quranCloudTajweedText: ayah.tajweedText,
      kemenagText: ayah.ayaTextKemenag,
      baseStyle: baseStyle,
      lang: lang,
      learningMode: ui.learningMode,
      activeKey: ui.activeTajweedKey,
      onTapRule: (key) => notifier.setActiveTajweed(key),
      onClosePopup: () => notifier.setActiveTajweed(null),
      context: context,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
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
              text: TextSpan(style: baseStyle, children: spans),
            ),
            const SizedBox(height: 24),
            _GrammarSection(ayah: ayah),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    ayah.translation.trim().isEmpty
                        ? tr(
                          ref,
                          id: 'Terjemahan belum tersedia.',
                          en: 'Translation is not available yet.',
                        )
                        : ayah.translation,
                    style: TextStyle(
                      fontSize: settings.ayahPanelFontSize,
                      height: 1.7,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed:
                  () => showModalBottomSheet<void>(
                    context: context,
                    showDragHandle: true,
                    isScrollControlled: true,
                    builder:
                        (context) => DraggableScrollableSheet(
                          expand: false,
                          initialChildSize: 0.55,
                          builder:
                              (context, controller) => ListView(
                                controller: controller,
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  32,
                                ),
                                children: [
                                  Text(
                                    'Tafsir • $surahName ${ayah.surahId}:${ayah.number}',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    ayah.tafsir.trim().isEmpty
                                        ? tr(
                                          ref,
                                          id: 'Tafsir belum tersedia.',
                                          en: 'Tafsir is not available yet.',
                                        )
                                        : ayah.tafsir,
                                    style: TextStyle(
                                      fontSize: settings.ayahPanelFontSize,
                                      height: 1.8,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                  ),
              child: const Text('Tafsir'),
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
      ayahWordsProvider((surahId: ayah.surahId, ayahNumber: ayah.number)),
    );

    return asyncWords.when(
      loading: () => const LinearProgressIndicator(),
      error:
          (e, _) => Text(
            '${tr(ref, id: 'Gagal memuat analisis', en: 'Failed to load analysis')}: $e',
          ),
      data: (words) {
        if (words.isEmpty) {
          return Text(
            tr(
              ref,
              id: 'Analisis kata belum tersedia.',
              en: 'Word analysis is not available yet.',
            ),
          );
        }

        final filtered =
            ui.filter == null
                ? words
                : words
                    .where(
                      (g) => detectGrammarType(g: g, isId: isId) == ui.filter,
                    )
                    .toList();

        final rootCount = <int, int>{};
        for (var g in words) {
          if (g.hasRoot) {
            rootCount[g.rootWordId] = (rootCount[g.rootWordId] ?? 0) + 1;
          }
        }

        // One tile per word position; multiple root annotations stay in its popup.
        final grouped = <int, List<Grammar>>{};
        for (final word in filtered) {
          grouped.putIfAbsent(word.wordNumber, () => []).add(word);
        }
        final positions = grouped.keys.toList()..sort();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (filtered.isEmpty)
              Text(
                tr(
                  ref,
                  id: 'Tidak ada kata dalam kategori ini.',
                  en: 'No words in this category.',
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth =
                    constraints.maxWidth < 500
                        ? (constraints.maxWidth - 24) / 3
                        : 170.0;
                return Wrap(
                  textDirection: TextDirection.rtl,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 20,
                  children: [
                    for (final position in positions)
                      SizedBox(
                        width: tileWidth,
                        child: _WordTile(
                          analyses: grouped[position]!,
                          highlightRoot:
                              ui.highlightRoot &&
                              grouped[position]!.any(
                                (g) =>
                                    g.hasRoot &&
                                    (rootCount[g.rootWordId] ?? 0) > 1,
                              ),
                          learningMode: ui.learningMode,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                tr(ref, id: 'Pilihan belajar', en: 'Study options'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              children: [_GrammarToolbar()],
            ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== FILTER BAR =====
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _chip(
                tr(ref, id: 'Semua', en: 'All'),
                ui.filter == null,
                () => n.setFilter(null),
              ),
              _chip(
                tr(ref, id: 'Fi’il', en: 'Verb'),
                ui.filter == GrammarType.fiil,
                () => n.setFilter(GrammarType.fiil),
              ),
              _chip(
                tr(ref, id: 'Isim', en: 'Noun'),
                ui.filter == GrammarType.isim,
                () => n.setFilter(GrammarType.isim),
              ),
              _chip(
                tr(ref, id: 'Harf', en: 'Particle'),
                ui.filter == GrammarType.harf,
                () => n.setFilter(GrammarType.harf),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ===== MODE BAR =====
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: Text(tr(ref, id: 'Sorot Akar Kata', en: 'Highlight Root')),
              selected: ui.highlightRoot,
              onSelected: (_) => n.toggleHighlightRoot(),
            ),
            FilterChip(
              label: Text(tr(ref, id: 'Mode Belajar', en: 'Learning Mode')),
              selected: ui.learningMode,
              onSelected: (_) => n.toggleLearningMode(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

/* ============================================================
   GRAMMAR CARD
============================================================ */

class _WordTile extends ConsumerWidget {
  final List<Grammar> analyses;
  final bool highlightRoot;
  final bool learningMode;

  const _WordTile({
    required this.analyses,
    required this.highlightRoot,
    required this.learningMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thisContext = context;
    final settings = ref.watch(settingsProvider);
    final isId = settings.language == 'id';
    final grammar = analyses.first;
    final meaning = isId ? grammar.meaningId : grammar.meaningEn;
    final description = isId ? grammar.grammarDescId : grammar.grammarDescEn;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      key: ValueKey('word-${grammar.surahId}-${grammar.ayahNumber}-${grammar.wordNumber}'),
      button: true,
      label: '${isId ? 'Kata' : 'Word'} ${grammar.wordNumber}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap:
            () => showDialog<void>(
              context: context,
              builder:
                  (context) =>
                      analyses.length == 1
                          ? GrammarPopup(grammar: grammar)
                          : SimpleDialog(
                            title: Text(
                              tr(
                                ref,
                                id: 'Analisis akar kata',
                                en: 'Root analyses',
                              ),
                            ),
                            children: [
                              for (final item in analyses)
                                SimpleDialogOption(
                                  child: Text(
                                    item.rootAr.isEmpty ? '—' : item.rootAr,
                                    textDirection: TextDirection.rtl,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showDialog<void>(
                                      context: thisContext,
                                      builder:
                                          (_) => GrammarPopup(grammar: item),
                                    );
                                  },
                                ),
                            ],
                          ),
            ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color:
                highlightRoot
                    ? colors.primaryContainer.withValues(alpha: 0.5)
                    : null,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: Column(
            children: [
              Text(
                grammar.wordAr.isEmpty ? '—' : grammar.wordAr,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'LPMQ',
                  fontSize: settings.arabicFontSize,
                  height: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meaning.trim().isEmpty ? '—' : meaning,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: settings.ayahPanelFontSize,
                  height: 1.5,
                  color: colors.onSurfaceVariant,
                ),
              ),
              if (learningMode) ...[
                const SizedBox(height: 8),
                Text(
                  description.isEmpty ? '—' : description,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (grammar.hasRoot)
                  Text(
                    grammar.rootAr,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(color: colors.primary),
                  ),
              ],
            ],
          ),
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
        Text(
          'QS ${ayah.surahId}:${ayah.number}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Icon(Icons.menu_book_outlined, color: Theme.of(context).primaryColor),
      ],
    );
  }
}
