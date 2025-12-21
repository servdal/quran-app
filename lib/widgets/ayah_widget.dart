
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/ayah_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
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
  
  @override
  void dispose() {
    super.dispose();
  }

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
    final settings = ref.watch(settingsProvider);
    final isId = settings.language == 'id';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isId ? 'Simpan Bookmark' : 'Save Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: isId ? 'Beri nama...' : 'Enter name...',
              ),
            ),
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
            child: Text(isId ? 'Batal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveBookmark(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(isId ? 'Simpan' : 'Save'),
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
    final lang = ref.watch(settingsProvider).language;
    final spans = lang == 'id'
    ? AutoTajweedParser.parse(
        widget.ayah.arabicText, 
        baseArabicStyle,
        lang: lang,             // Parameter bahasa yang baru ditambahkan
        context: context,      // Diperlukan agar BottomSheet bisa muncul
        learningMode: true,    // Aktifkan agar bisa diklik
      )
    : TajweedParser.parse(
        widget.ayah.tajweedText, 
        baseArabicStyle,
      );
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(child: Text(widget.ayah.number.toString())),
          title: Text(
            isId 
             ? 'Juz ${widget.ayah.juz} | Hal ${widget.ayah.page}'
             : 'Juz ${widget.ayah.juz} | Page ${widget.ayah.page}'
          ),
          trailing: IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: _bookmarkDialog,
          ),
        ),

        DefaultTabController(
          length: 4,
          child: Column(
            children: [
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: isId ? 'Teks' : 'Text'),
                  Tab(text: isId ? 'Terjemah' : 'Translation'),
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
                    _tabAudio(isId),
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
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    
    // Pilih transliteration berdasarkan bahasa
    // (saat ini field-nya sama, tapi logika sudah siap)
    final String transliterationText =
        widget.ayah.transliteration.trim();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== TEKS ARAB =====
          RichText(
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            text: TextSpan(children: spans),
          ),

          // ===== TRANSLITERATION =====
          if (transliterationText.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(
              color: theme.dividerColor.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              transliterationText,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: settings.arabicFontSize * 0.6,
                fontStyle: FontStyle.italic,
                fontFamily: 'Roboto',
                height: 1.6,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
              ),
            ),
          ],
        ],
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

  Widget _tabAudio(bool isId) {
    
    final videoId = YoutubePlayer.convertUrlToId(
      'https://www.youtube.com/watch?v=fM7BQNV6koc&list=PLdfZWRI2eOVYYEkjAqrGm7AgWuPn_26jk',
    );

    if (videoId == null) {
      return const Center(child: Text('Video tidak valid'));
    }

    return YoutubeAudioTab(videoId: videoId, isId: isId);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
  
}

class YoutubeAudioTab extends StatefulWidget {
  final String videoId;
  final bool isId;

  const YoutubeAudioTab({
    super.key,
    required this.videoId,
    this.isId = true,
  });

  @override
  State<YoutubeAudioTab> createState() => _YoutubeAudioTabState();
}

class _YoutubeAudioTabState extends State<YoutubeAudioTab> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        disableDragSeek: false,
        loop: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.isId ? 'Audio via YouTube' : 'Audio via YouTube',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}

