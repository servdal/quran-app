import 'dart:async';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:quran_app/providers/hadith_reader_provider.dart';
import 'package:quran_app/data/hadith_chapter_labels.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/repository/hadith_repository.dart';
import 'package:quran_app/services/hadith_translation_service.dart';

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  late Future<List<HadithBook>> _books;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _books = HadithRepository.instance.books();
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: Text(_t(ref, 'Hadist', 'Hadith')),
        actions: [
          IconButton(
            tooltip: _t(ref, 'Tentang koleksi', 'About this library'),
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHadithSources(context),
          ),
          IconButton(
            tooltip: _t(ref, 'Cari di semua kitab', 'Search all collections'),
            icon: Icon(Icons.search),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder:
                        (_) => HadithListScreen(
                          title: _t(ref, 'Semua Kitab', 'All Collections'),
                        ),
                  ),
                ),
          ),
        ],
        bottom: TabBar(
          tabs: [
            Tab(text: _t(ref, 'Kitab', 'Collections')),
            Tab(text: _t(ref, 'Bab', 'Chapters')),
            Tab(text: _t(ref, 'Bookmark', 'Bookmarks')),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          FutureBuilder<List<HadithBook>>(
            future: _books,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _LoadError(onRetry: () => setState(_load));
              }
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              final books = snapshot.data!;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _HadithLibraryHero(books: books),
                      const SizedBox(height: 28),
                      Text(
                        _t(ref, 'Jelajahi kitab', 'Explore collections'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _t(
                          ref,
                          'Pilih kitab untuk mulai membaca atau temukan riwayat melalui tab Bab.',
                          'Choose a collection to read, or explore narrations in Chapters.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width =
                              constraints.maxWidth >= 700
                                  ? (constraints.maxWidth - 16) / 2
                                  : constraints.maxWidth;
                          return Wrap(
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              for (final book in books)
                                SizedBox(
                                  width: width,
                                  child: _HadithCollectionCard(book: book),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _Notice(
                        _t(
                          ref,
                          'Metadata bab dan penilaian tersedia untuk sebagian riwayat. Teks Arab–Indonesia tetap lengkap sesuai dataset lokal.',
                          'Chapter metadata and grading cover selected matched narrations. The local Arabic–Indonesian corpus is preserved.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => _showHadithSources(context),
                        icon: const Icon(Icons.info_outline),
                        label: Text(
                          _t(
                            ref,
                            'Tentang koleksi & sumber data',
                            'About this library & its sources',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const HadithChaptersView(),
          const HadithBookmarksView(),
        ],
      ),
    ),
  );
}

class HadithListScreen extends ConsumerStatefulWidget {
  final String title;
  final String? bookId;
  final String? chapterId;

  const HadithListScreen({
    super.key,
    required this.title,
    this.bookId,
    this.chapterId,
  });

  @override
  ConsumerState<HadithListScreen> createState() => _HadithListScreenState();
}

class _HadithListScreenState extends ConsumerState<HadithListScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  final _entries = <HadithEntry>[];
  Timer? _debounce;
  int _generation = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 500) _load();
    });
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (!reset && (_loading || !_hasMore || (_debounce?.isActive ?? false))) {
      return;
    }
    final generation = reset ? ++_generation : _generation;
    setState(() {
      if (reset) {
        _entries.clear();
        _hasMore = true;
      }
      _loading = true;
      _failed = false;
    });
    try {
      final rows = await HadithRepository.instance.entries(
        bookId: widget.bookId,
        chapterId: widget.chapterId,
        query: _search.text,
        offset: _entries.length,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _entries.addAll(rows);
        _hasMore = rows.length == 40;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.bookId == null && widget.chapterId == null
            ? _t(ref, 'Semua Kitab', 'All Collections')
            : widget.title,
      ),
      actions: [
        if (widget.bookId != null && widget.chapterId == null)
          IconButton(
            tooltip: _t(ref, 'Pilih bab', 'Choose chapter'),
            icon: const Icon(Icons.collections_bookmark_outlined),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder:
                        (_) => Scaffold(
                          appBar: AppBar(
                            title: Text(
                              _t(
                                ref,
                                'Bab • ${widget.title}',
                                'Chapters • ${widget.title}',
                              ),
                            ),
                          ),
                          body: HadithChaptersView(bookId: widget.bookId),
                        ),
                  ),
                ),
          ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: _t(
                ref,
                'Cari teks Indonesia, Inggris, Arab, atau nomor',
                'Search Indonesian, English, Arabic, or number',
              ),
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _t(ref, 'Hapus pencarian', 'Clear search'),
                icon: Icon(Icons.clear),
                onPressed: () {
                  _search.clear();
                  _debounce?.cancel();
                  _load(reset: true);
                },
              ),
            ),
            onChanged: (_) {
              _debounce?.cancel();
              // Invalidate requests immediately so old results cannot replace the new query.
              _generation++;
              _debounce = Timer(
                const Duration(milliseconds: 350),
                () => _load(reset: true),
              );
            },
          ),
        ),
        Expanded(
          child:
              _entries.isEmpty && !_loading
                  ? (_failed
                      ? _LoadError(onRetry: () => _load(reset: true))
                      : Center(
                        child: Text(
                          _t(ref, 'Hadis tidak ditemukan.', 'No hadith found.'),
                        ),
                      ))
                  : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: _entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _entries.length) {
                        if (_failed) return _LoadError(onRetry: _load);
                        if (_loading) {
                          return Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (_hasMore) {
                          return TextButton(
                            onPressed: _load,
                            child: Text(_t(ref, 'Muat lagi', 'Load more')),
                          );
                        }
                        return SizedBox(height: 16);
                      }
                      final entry = _entries[index];
                      return _HadithListCard(
                        entry: entry,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder:
                                    (_) => HadithDetailScreen(entry: entry),
                              ),
                            ),
                      );
                    },
                  ),
        ),
      ],
    ),
  );
}

class HadithDetailScreen extends ConsumerStatefulWidget {
  final HadithEntry entry;
  const HadithDetailScreen({super.key, required this.entry});

  @override
  ConsumerState<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

class _HadithDetailScreenState extends ConsumerState<HadithDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  Future<String?>? _translation;
  String? _language;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (_tabs.index == 1 && !_requested) {
        setState(() => _requested = true);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final reader = ref.watch(hadithReaderProvider);
    final entry = widget.entry;
    if (_language != settings.language) {
      _language = settings.language;
      _translation = null;
    }
    final visible =
        _requested ||
        reader.mode == HadithTextMode.translation ||
        reader.mode == HadithTextMode.both;
    if (visible && settings.language != 'id') {
      _translation ??= ref
          .read(hadithTranslationServiceProvider)
          .translate(entry, settings.language);
    }
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: reader.translationSize ?? settings.ayahPanelFontSize,
      height: 1.7,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('${entry.bookTitle} • ${entry.number}'),
        actions: [
          _HadithBookmarkButton(entry: entry),
          IconButton(
            tooltip: _t(ref, 'Informasi hadis', 'Hadith information'),
            icon: const Icon(Icons.info_outline),
            onPressed:
                () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => HadithMetadataSheet(entry: entry),
                ),
          ),
          IconButton(
            tooltip: _t(ref, 'Tampilan teks', 'Text appearance'),
            icon: const Icon(Icons.text_fields),
            onPressed:
                () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const HadithAppearanceSheet(),
                ),
          ),
        ],
        bottom:
            reader.mode == HadithTextMode.tabs
                ? TabBar(
                  controller: _tabs,
                  tabs: [
                    Tab(text: _t(ref, 'Teks Arab', 'Arabic')),
                    Tab(text: _t(ref, 'Terjemah', 'Translation')),
                  ],
                )
                : null,
      ),
      body: switch (reader.mode) {
        HadithTextMode.tabs => TabBarView(
          controller: _tabs,
          children: [
            _arabicBody(),
            _resolvedTranslation(style, visible: visible),
          ],
        ),
        HadithTextMode.arabic => _arabicBody(),
        HadithTextMode.translation => _resolvedTranslation(
          style,
          visible: true,
        ),
        HadithTextMode.both => ListView(
          children: [
            _arabicBody(embedded: true),
            const Divider(),
            _resolvedTranslation(style, visible: true, embedded: true),
          ],
        ),
      },
    );
  }

  Widget _arabicBody({bool embedded = false}) {
    final settings = ref.watch(settingsProvider);
    final reader = ref.watch(hadithReaderProvider);
    return SelectionArea(
      child: ListView(
        shrinkWrap: embedded,
        physics: embedded ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _t(
              ref,
              'Hadis No. ${widget.entry.number}',
              'Hadith No. ${widget.entry.number}',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _HadithEntryBadges(entry: widget.entry),
          const SizedBox(height: 28),
          Text(
            widget.entry.arabic,
            key: const ValueKey('hadith-arabic-text'),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: reader.font,
              fontSize: reader.arabicSize ?? settings.arabicFontSize,
              height: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resolvedTranslation(
    TextStyle? style, {
    required bool visible,
    bool embedded = false,
  }) {
    if (_language == 'id') {
      return _translationBody(
        widget.entry.translation,
        style,
        embedded: embedded,
      );
    }
    if (!visible) return const SizedBox.shrink();
    return FutureBuilder<String?>(
      future: _translation,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _translationBody(
          snapshot.data ?? widget.entry.translation,
          style,
          fallback: snapshot.data == null,
          embedded: embedded,
        );
      },
    );
  }

  Widget _translationBody(
    String text,
    TextStyle? style, {
    bool fallback = false,
    bool embedded = false,
  }) => SelectionArea(
    child: ListView(
      shrinkWrap: embedded,
      physics: embedded ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          _t(
            ref,
            'Terjemahan Indonesia',
            fallback ? 'Indonesian translation' : 'Translation',
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (!fallback && _language == 'en' && widget.entry.english != null)
          const Text('English • fawazahmed0/hadith-api'),
        if (fallback) ...[
          const SizedBox(height: 12),
          _Notice(
            _t(
              ref,
              'Terjemahan bahasa pilihan belum tersedia. Menampilkan teks Indonesia.',
              'Translation into your selected language is unavailable. Showing the Indonesian text.',
            ),
          ),
          if (ref.read(hadithTranslationServiceProvider).available)
            TextButton(
              onPressed: () => setState(() => _translation = null),
              child: Text(_t(ref, 'Coba lagi', 'Retry')),
            ),
        ],
        const SizedBox(height: 12),
        Text(
          text,
          key: const ValueKey('hadith-translation-text'),
          style: style,
          textDirection:
              !fallback && ['ar', 'fa', 'he', 'ur'].contains(_language)
                  ? TextDirection.rtl
                  : TextDirection.ltr,
        ),
        const SizedBox(height: 28),
        _Notice(
          _t(
            ref,
            'Nomor utama mengikuti dataset Indonesia. Metadata tambahan hanya tersedia pada riwayat yang cocok.',
            'Primary numbering follows the Indonesian dataset. Additional metadata is available only for matched narrations.',
          ),
        ),
        if (widget.entry.sourceReference != null) ...[
          const SizedBox(height: 12),
          Text(
            '${_t(ref, 'Referensi tambahan', 'Additional reference')}: ${widget.entry.sourceReference}',
          ),
          const Text('fawazahmed0/hadith-api'),
        ],
        if (widget.entry.grades.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _t(ref, 'Penilaian sumber', 'Source grading'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final grade in widget.entry.grades)
            Text('${grade['name']}: ${grade['grade']}'),
        ],
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  final String text;
  const _Notice(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text),
  );
}

class _LoadError extends ConsumerWidget {
  final VoidCallback onRetry;
  const _LoadError({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _t(
              ref,
              'Data hadis belum berhasil dibuka.',
              'Unable to open hadith data.',
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: Text(_t(ref, 'Coba lagi', 'Retry')),
          ),
        ],
      ),
    ),
  );
}

String _t(WidgetRef ref, String id, String en) =>
    ref.watch(settingsProvider).language == 'id' ? id : en;

class HadithChaptersView extends ConsumerStatefulWidget {
  final String? bookId;
  const HadithChaptersView({super.key, this.bookId});

  @override
  ConsumerState<HadithChaptersView> createState() => _HadithChaptersViewState();
}

class _HadithChaptersViewState extends ConsumerState<HadithChaptersView> {
  late Future<List<HadithChapter>> _chapters;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _chapters = HadithRepository.instance.chapters(bookId: widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(settingsProvider).language;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: _t(ref, 'Cari judul bab', 'Search chapter titles'),
              border: const OutlineInputBorder(),
            ),
            onChanged:
                (value) => setState(() => _query = value.trim().toLowerCase()),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _t(
              ref,
              'Cakupan bab belum lengkap. Kelompok lintas kitab memakai judul sumber yang sama, bukan penyamaan tema. Judul yang belum diterjemahkan ditampilkan dalam bahasa sumber.',
              'Chapter coverage is partial. Cross-collection groups share the same source title; they are not a thematic concordance. Untranslated titles use the source language.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<HadithChapter>>(
            future: _chapters,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _LoadError(onRetry: () => setState(_load));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final chapters =
                  snapshot.data!
                      .where(
                        (chapter) =>
                            chapter.title.toLowerCase().contains(_query) ||
                            hadithChapterLabel(
                              chapter.title,
                              language,
                            ).toLowerCase().contains(_query),
                      )
                      .toList();
              if (chapters.isEmpty) {
                return Center(
                  child: Text(
                    _t(ref, 'Bab tidak ditemukan.', 'No chapters found.'),
                  ),
                );
              }
              return ListView.builder(
                itemCount: chapters.length,
                itemBuilder: (context, index) {
                  final chapter = chapters[index];
                  final label = hadithChapterLabel(chapter.title, language);
                  return ListTile(
                    title: Text(label),
                    subtitle: Text(
                      '${label != chapter.title ? '${chapter.title}\n' : ''}${chapter.count} ${_t(ref, 'hadis', 'hadiths')} • ${chapter.bookCount} ${_t(ref, 'kitab', 'collections')}',
                    ),
                    isThreeLine: label != chapter.title,
                    trailing: const Icon(Icons.chevron_right),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder:
                                (_) => HadithListScreen(
                                  title: label,
                                  chapterId: chapter.id,
                                  bookId: widget.bookId,
                                ),
                          ),
                        ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HadithBookmarkButton extends ConsumerWidget {
  final HadithEntry entry;
  const _HadithBookmarkButton({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref
        .watch(hadithReaderProvider)
        .isBookmarked(entry.bookId, entry.number);
    return IconButton(
      tooltip:
          saved
              ? _t(ref, 'Hapus bookmark', 'Remove bookmark')
              : _t(ref, 'Simpan bookmark', 'Save bookmark'),
      icon: Icon(
        saved ? Icons.bookmark : Icons.bookmark_border,
        color: saved ? Theme.of(context).colorScheme.primary : null,
      ),
      onPressed: () async {
        final message = _t(
          ref,
          'Bookmark gagal disimpan. Coba lagi.',
          'Unable to save bookmark. Please retry.',
        );
        try {
          await ref
              .read(hadithReaderProvider.notifier)
              .toggleBookmark(entry.bookId, entry.number);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(message)));
          }
        }
      },
    );
  }
}

class HadithBookmarksView extends ConsumerStatefulWidget {
  const HadithBookmarksView({super.key});
  @override
  ConsumerState<HadithBookmarksView> createState() =>
      _HadithBookmarksViewState();
}

class _HadithBookmarksViewState extends ConsumerState<HadithBookmarksView> {
  String? _fingerprint;
  String _book = 'all';
  Future<List<HadithEntry>>? _entries;

  void _load(Set<String> keys) {
    final sorted = keys.toList()..sort();
    _fingerprint = sorted.join('|');
    _entries = Future.wait(
      sorted.map((key) {
        final parts = key.split(':');
        return HadithRepository.instance.entry(parts[0], int.parse(parts[1]));
      }),
    ).then(
      (rows) =>
          rows.whereType<HadithEntry>().toList()..sort((a, b) {
            final bookOrder = hadithBookIds
                .indexOf(a.bookId)
                .compareTo(hadithBookIds.indexOf(b.bookId));
            return bookOrder == 0 ? a.number.compareTo(b.number) : bookOrder;
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(hadithReaderProvider).bookmarks;
    final fingerprint = (keys.toList()..sort()).join('|');
    if (_fingerprint != fingerprint) _load(keys);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            initialValue: _book,
            decoration: InputDecoration(
              labelText: _t(ref, 'Filter kitab', 'Filter collection'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'all',
                child: Text(_t(ref, 'Semua Kitab', 'All Collections')),
              ),
              for (final book in hadithBookIds)
                DropdownMenuItem(value: book, child: Text(_bookNames[book]!)),
            ],
            onChanged: (book) {
              if (book != null) setState(() => _book = book);
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<HadithEntry>>(
            future: _entries,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _LoadError(onRetry: () => setState(() => _load(keys)));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries =
                  snapshot.data!
                      .where((e) => _book == 'all' || e.bookId == _book)
                      .toList();
              if (entries.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _t(
                        ref,
                        'Belum ada bookmark di pilihan ini. Simpan hadis melalui ikon bookmark.',
                        'No bookmarks in this selection. Save a hadith using its bookmark icon.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ListTile(
                    title: Text('${entry.bookTitle} • No. ${entry.number}'),
                    subtitle: Text(
                      ref.watch(settingsProvider).language == 'en'
                          ? entry.english ?? entry.translation
                          : entry.translation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: _HadithBookmarkButton(entry: entry),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => HadithDetailScreen(entry: entry),
                          ),
                        ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

const _bookNames = {
  'bukhari': 'Shahih Bukhari',
  'muslim': 'Shahih Muslim',
  'abu-daud': 'Sunan Abu Daud',
  'ibnu-majah': 'Sunan Ibnu Majah',
  'nasai': 'Sunan Nasa’i',
  'tirmidzi': 'Sunan Tirmidzi',
};

class HadithAppearanceSheet extends ConsumerStatefulWidget {
  const HadithAppearanceSheet({super.key});
  @override
  ConsumerState<HadithAppearanceSheet> createState() =>
      _HadithAppearanceSheetState();
}

class _HadithAppearanceSheetState extends ConsumerState<HadithAppearanceSheet> {
  late HadithTextMode _mode;
  late String _font;
  late double _arabicSize;
  late double _translationSize;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final reader = ref.read(hadithReaderProvider);
    final settings = ref.read(settingsProvider);
    _mode = reader.mode;
    _font = reader.font;
    _arabicSize = (reader.arabicSize ?? settings.arabicFontSize).clamp(18, 60);
    _translationSize = (reader.translationSize ?? settings.ayahPanelFontSize)
        .clamp(12, 32);
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      24,
      20,
      24,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(ref, 'Tampilan teks', 'Text appearance'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<HadithTextMode>(
          initialValue: _mode,
          decoration: InputDecoration(
            labelText: _t(ref, 'Pilihan teks', 'Text display'),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: HadithTextMode.tabs,
              child: Text(
                _t(ref, 'Tab Arab / Terjemah', 'Arabic / Translation tabs'),
              ),
            ),
            DropdownMenuItem(
              value: HadithTextMode.arabic,
              child: Text(_t(ref, 'Arab saja', 'Arabic only')),
            ),
            DropdownMenuItem(
              value: HadithTextMode.translation,
              child: Text(_t(ref, 'Terjemah saja', 'Translation only')),
            ),
            DropdownMenuItem(
              value: HadithTextMode.both,
              child: Text(
                _t(ref, 'Arab dan terjemah', 'Arabic and translation'),
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _mode = value);
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _font,
          decoration: InputDecoration(
            labelText: _t(ref, 'Font Arab', 'Arabic font'),
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final font in hadithFonts)
              DropdownMenuItem(value: font, child: Text(font)),
          ],
          onChanged: (font) {
            if (font != null) setState(() => _font = font);
          },
        ),
        const SizedBox(height: 20),
        Text(
          '${_t(ref, 'Ukuran Arab', 'Arabic size')}: ${_arabicSize.round()}',
        ),
        Slider(
          key: const ValueKey('hadith-arabic-size'),
          value: _arabicSize,
          min: 18,
          max: 60,
          divisions: 42,
          label: '${_arabicSize.round()}',
          onChanged: (size) => setState(() => _arabicSize = size),
        ),
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: _font,
            fontSize: _arabicSize,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${_t(ref, 'Ukuran terjemah', 'Translation size')}: ${_translationSize.round()}',
        ),
        Slider(
          key: const ValueKey('hadith-translation-size'),
          value: _translationSize,
          min: 12,
          max: 32,
          divisions: 20,
          label: '${_translationSize.round()}',
          onChanged: (size) => setState(() => _translationSize = size),
        ),
        Text(
          _t(
            ref,
            'Pratinjau teks terjemahan hadis.',
            'Hadith translation text preview.',
          ),
          style: TextStyle(fontSize: _translationSize),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _saving
                    ? null
                    : () async {
                      setState(() => _saving = true);
                      final message = _t(
                        ref,
                        'Setelan gagal disimpan. Coba lagi.',
                        'Unable to save settings. Please retry.',
                      );
                      try {
                        await ref
                            .read(hadithReaderProvider.notifier)
                            .setDisplay(
                              mode: _mode,
                              font: _font,
                              arabicSize: _arabicSize,
                              translationSize: _translationSize,
                            );
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
            child: Text(_t(ref, 'Terapkan', 'Apply')),
          ),
        ),
      ],
    ),
  );
}

String _number(WidgetRef ref, int value) => NumberFormat.decimalPattern(
  ref.watch(settingsProvider).language == 'id' ? 'id_ID' : 'en_US',
).format(value);

class _HadithLibraryHero extends ConsumerWidget {
  final List<HadithBook> books;
  const _HadithLibraryHero({required this.books});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final total = books.fold(0, (sum, b) => sum + b.count);
    final english = books.fold(0, (sum, b) => sum + b.englishCount);
    final graded = books.fold(0, (sum, b) => sum + b.gradedCount);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                color: colors.onPrimaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t(ref, 'KOLEKSI HADIS', 'HADITH LIBRARY'),
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              _InfoPill(label: 'Offline', icon: Icons.offline_pin_outlined),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _number(ref, total),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onPrimaryContainer,
            ),
          ),
          Text(
            _t(
              ref,
              'riwayat untuk dibaca dan dipelajari',
              'narrations to read and explore',
            ),
            style: TextStyle(color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoPill(
                label: '${books.length} ${_t(ref, 'kitab', 'collections')}',
                icon: Icons.library_books_outlined,
              ),
              _InfoPill(
                label: '${_number(ref, english)} English',
                icon: Icons.translate_rounded,
              ),
              _InfoPill(
                label:
                    '${_number(ref, graded)} ${_t(ref, 'dengan penilaian', 'with grading')}',
                icon: Icons.fact_check_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoPill({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ],
    ),
  );
}

class _HadithCollectionCard extends ConsumerWidget {
  final HadithBook book;
  const _HadithCollectionCard({required this.book});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder:
                    (_) => HadithListScreen(title: book.title, bookId: book.id),
              ),
            ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_number(ref, book.count)} ${_t(ref, 'hadis', 'hadiths')}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoPill(
                    label: '${book.chapterCount} ${_t(ref, 'bab', 'chapters')}',
                    icon: Icons.segment_rounded,
                  ),
                  _InfoPill(
                    label: '${_number(ref, book.englishCount)} EN',
                    icon: Icons.translate,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 5,
                  value: book.count == 0 ? 0 : book.mappedCount / book.count,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  ref,
                  '${_number(ref, book.mappedCount)} hadis memiliki informasi bab',
                  '${_number(ref, book.mappedCount)} narrations have chapter metadata',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HadithEntryBadges extends ConsumerWidget {
  final HadithEntry entry;
  const _HadithEntryBadges({required this.entry});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _InfoPill(
        label: _t(ref, 'Arab · Indonesia', 'Arabic · Indonesian'),
        icon: Icons.menu_book_outlined,
      ),
      if (entry.english?.isNotEmpty ?? false)
        const _InfoPill(label: 'English offline', icon: Icons.translate),
      if (entry.grades.isNotEmpty)
        _InfoPill(
          label: _t(
            ref,
            '${entry.grades.length} penilaian sumber',
            '${entry.grades.length} source gradings',
          ),
          icon: Icons.fact_check_outlined,
        ),
    ],
  );
}

class _HadithListCard extends ConsumerWidget {
  final HadithEntry entry;
  final VoidCallback onTap;
  const _HadithListCard({required this.entry, required this.onTap});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isEnglish = ref.watch(settingsProvider).language == 'en';
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.bookTitle} • No. ${entry.number}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _HadithBookmarkButton(entry: entry),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                entry.arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: ref.watch(hadithReaderProvider).font,
                  fontSize: 22,
                  height: 1.8,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isEnglish
                    ? entry.english ?? entry.translation
                    : entry.translation,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 14),
              _HadithEntryBadges(entry: entry),
              const SizedBox(height: 12),
              Text(
                _t(ref, 'Baca selengkapnya →', 'Read narration →'),
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showHadithSources(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _HadithSourcesSheet(),
);

class _HadithSourcesSheet extends ConsumerWidget {
  const _HadithSourcesSheet();
  @override
  Widget build(BuildContext context, WidgetRef ref) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t(ref, 'Tentang koleksi', 'About this library'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),
        _Notice(_t(ref, 'Teks utama', 'Primary text')),
        const SizedBox(height: 12),
        const Text('irsyadulibad/hadits-database • MIT'),
        Text(
          _t(
            ref,
            'Enam kitab dalam bahasa Arab dan Indonesia. Nomor utama selalu mengikuti dataset ini.',
            'Six Arabic–Indonesian collections. Primary narration numbers follow this dataset.',
          ),
        ),
        const SizedBox(height: 24),
        _Notice(_t(ref, 'Informasi tambahan', 'Additional information')),
        const SizedBox(height: 12),
        const Text('fawazahmed0/hadith-api • Unlicense'),
        Text(
          _t(
            ref,
            'Teks Inggris, bagian/bab, referensi dan penilaian dipadankan melalui kecocokan teks lengkap. '
                'Pasangan ambigu tidak ditambahkan. Penilaian ditampilkan sesuai nama penilainya.',
            'English text, sections, references and grading are linked by full-text matches. '
                'Ambiguous matches are excluded. Grading retains each evaluator’s name.',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _t(ref, 'Memahami informasi bab', 'Understanding chapters'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _t(
            ref,
            'Bab hanya mencakup riwayat yang sudah cocok. Judul sumber yang sama dikelompokkan lintas kitab; '
                'judul berbeda tidak otomatis dianggap satu tema. Nomor sumber tambahan dapat berbeda dari nomor utama.',
            'Chapters cover matched narrations only. Identical source titles group across collections; '
                'different titles are not automatically treated as one topic. Additional source numbers may differ from primary numbers.',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _t(ref, 'Bahasa & akses offline', 'Languages & offline access'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          _t(
            ref,
            'Arab dan Indonesia tersedia offline. Inggris memakai teks sumber lokal jika tersedia. '
                'Terjemahan tambahan melalui layanan mesin membutuhkan internet.',
            'Arabic and Indonesian are offline. English uses local source text when available. '
                'Additional machine translations require an internet connection.',
          ),
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

class HadithMetadataSheet extends ConsumerStatefulWidget {
  final HadithEntry entry;
  const HadithMetadataSheet({super.key, required this.entry});
  @override
  ConsumerState<HadithMetadataSheet> createState() =>
      _HadithMetadataSheetState();
}

class _HadithMetadataSheetState extends ConsumerState<HadithMetadataSheet> {
  late final Future<List<HadithChapter>> _chapters;
  @override
  void initState() {
    super.initState();
    _chapters = HadithRepository.instance.chaptersForEntry(
      widget.entry.bookId,
      widget.entry.number,
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final language = ref.watch(settingsProvider).language;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t(ref, 'Informasi hadis', 'Hadith information'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          _InfoPill(
            label: '${entry.bookTitle} • No. ${entry.number}',
            icon: Icons.menu_book_outlined,
          ),
          const SizedBox(height: 16),
          _HadithEntryBadges(entry: entry),
          const SizedBox(height: 24),
          Text(
            _t(ref, 'Bab terkait', 'Related chapters'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          FutureBuilder<List<HadithChapter>>(
            future: _chapters,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                  _t(
                    ref,
                    'Informasi bab belum berhasil dimuat.',
                    'Unable to load chapter information.',
                  ),
                );
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              if (snapshot.data!.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _t(
                      ref,
                      'Bab belum dipadankan untuk riwayat ini.',
                      'This narration has no matched chapter metadata yet.',
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final chapter in snapshot.data!)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.segment_rounded),
                      title: Text(hadithChapterLabel(chapter.title, language)),
                      subtitle:
                          language == 'id' &&
                                  hadithChapterLabel(chapter.title, language) !=
                                      chapter.title
                              ? Text(chapter.title)
                              : null,
                      trailing: const Icon(Icons.arrow_forward_rounded),
                      onTap: () {
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => HadithListScreen(
                                  title: hadithChapterLabel(
                                    chapter.title,
                                    language,
                                  ),
                                  chapterId: chapter.id,
                                ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            _t(ref, 'Referensi sumber', 'Source references'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.bookTitle} • ${entry.number}\nirsyadulibad/hadits-database',
          ),
          if (entry.sourceReference != null) ...[
            const SizedBox(height: 12),
            Text('${entry.sourceReference}\nfawazahmed0/hadith-api'),
            const SizedBox(height: 8),
            Text(
              _t(
                ref,
                'Nomor tambahan mengikuti penomoran sumber pengayaan.',
                'The additional number follows the enrichment source’s numbering.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          Text(
            _t(ref, 'Penilaian riwayat', 'Narration grading'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (entry.grades.isEmpty)
            Text(
              _t(
                ref,
                'Penilaian per riwayat belum tersedia dalam metadata ini.',
                'Per-narration grading is not available in this metadata.',
              ),
            ),
          for (final grade in entry.grades)
            Card(
              elevation: 0,
              child: ListTile(
                title: Text('${grade['grade']}'),
                subtitle: Text('${grade['name']}'),
                leading: const Icon(Icons.fact_check_outlined),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
