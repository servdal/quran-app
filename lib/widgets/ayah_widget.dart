import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/ayah_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/audio_provider.dart';
import '../../screens/download_manager_screen.dart';
import '../../utils/tajweed_parser.dart';
import '../../utils/auto_tajweed_parser.dart';

class AyahWidget extends ConsumerStatefulWidget {
  final Ayah ayah;
  final BookmarkViewType viewType;

  const AyahWidget({
    super.key,
    required this.ayah,
    required this.viewType,
  });

  @override
  ConsumerState<AyahWidget> createState() => _AyahWidgetState();
}

class _AyahWidgetState extends ConsumerState<AyahWidget> {
  late final AudioPlayer _player;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  /* =========================
   * AUDIO
   * ========================= */

  Future<void> _playAudio() async {
    final audioIndexAsync = ref.read(audioIndexProvider);

    audioIndexAsync.when(
      data: (audioList) async {
        final match = audioList.cast<Map<String, dynamic>>().firstWhere(
          (e) {
            final surahs = List<int>.from(e['surah_ids'] ?? []);
            return surahs.contains(widget.ayah.id);
          },
          orElse: () => {},
        );

        if (match.isEmpty) {
          _snack('Audio tidak tersedia');
          return;
        }

        final filename = match['file'];
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/audio/$filename');

        if (!await file.exists()) {
          _needDownload();
          return;
        }

        await _player.play(DeviceFileSource(file.path));
      },
      loading: () => _snack('Memuat audio...'),
      error: (_, __) => _snack('Gagal memuat audio'),
    );
  }

  Future<void> _pauseAudio() => _player.pause();
  Future<void> _stopAudio() => _player.stop();

  /* =========================
   * BOOKMARK
   * ========================= */

  void _saveBookmark(String name) {
    final bookmark = Bookmark(
      type: widget.viewType,
      surahId: widget.ayah.surahId,
      surahName: widget.ayah.surahName,
      ayahNumber: widget.ayah.number,
      pageNumber: widget.ayah.page,
    );
    ref.read(bookmarkProvider.notifier).addOrUpdateBookmark(name, bookmark);
    _snack('Disimpan di "$name"');
  }

  void _bookmarkDialog() {
    final controller = TextEditingController();
    final existing = ref.read(bookmarkProvider).keys.toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Simpan Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: controller),
            const SizedBox(height: 8),
            ...existing.map(
              (e) => ListTile(
                title: Text(e),
                onTap: () {
                  _saveBookmark(e);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveBookmark(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  /* =========================
   * UI
   * ========================= */

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    final baseArabicStyle = TextStyle(
      fontFamily: 'LPMQ',
      fontSize: settings.arabicFontSize,
      height: 2.2,
      color: theme.colorScheme.onSurface,
    );

    final isId = settings.language == 'id';

    final spans = isId
        ? AutoTajweedParser.parse(widget.ayah.arabicText, baseArabicStyle)
        : TajweedParser.parse(widget.ayah.tajweedText, baseArabicStyle);

    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(child: Text(widget.ayah.number.toString())),
          title: Text('Juz ${widget.ayah.juz} page ${widget.ayah.page}'),
          trailing: IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _bookmarkDialog,
          ),
        ),

        DefaultTabController(
          length: 4,
          child: Column(
            children: [
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Teks'),
                  Tab(text: 'Terjemah'),
                  Tab(text: 'Tafsir'),
                  Tab(text: 'Audio'),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    _tabText(spans),
                    _tabTranslation(),
                    _tabTafsir(),
                    _tabAudio(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /* =========================
   * TAB CONTENT
   * ========================= */

  Widget _tabText(List<InlineSpan> spans) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: RichText(
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        text: TextSpan(children: spans),
      ),
    );
  }

  Widget _tabTranslation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(widget.ayah.translation),
    );
  }

  Widget _tabTafsir() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Text(widget.ayah.tafsir),
    );
  }

  Widget _tabAudio() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('KH Bahauddin Nursalim'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 48,
              icon: Icon(
                _playerState == PlayerState.playing
                    ? Icons.pause_circle
                    : Icons.play_circle,
              ),
              onPressed:
                  _playerState == PlayerState.playing ? _pauseAudio : _playAudio,
            ),
            IconButton(
              iconSize: 48,
              icon: const Icon(Icons.stop_circle),
              onPressed: _stopAudio,
            ),
          ],
        ),
      ],
    );
  }

  /* =========================
   * HELPERS
   * ========================= */

  void _needDownload() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Audio belum diunduh'),
        action: SnackBarAction(
          label: 'Unduh',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DownloadManagerScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
