import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/utils/tajweed_parser.dart';
import 'package:flutter/services.dart';

class AyahWidget extends ConsumerStatefulWidget {
  final Ayah ayah;
  final BookmarkViewType viewType;

  const AyahWidget({super.key, required this.ayah, required this.viewType});

  @override
  ConsumerState<AyahWidget> createState() => _AyahWidgetState();
}

class _AyahWidgetState extends ConsumerState<AyahWidget> {
  late final AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    final audioUrl = 'https://cdn.alquran.cloud/media/audio/ayah/ar.alafasy/${widget.ayah.ayaId}';
    await _audioPlayer.play(UrlSource(audioUrl));
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  Future<void> _setBookmark() async {
    final newBookmark = Bookmark(
      type: widget.viewType == BookmarkViewType.page ? 'page' : 'surah',
      surahId: widget.ayah.suraId,
      surahName: widget.ayah.surah?.englishName ?? 'Surah',
      ayahNumber: widget.ayah.ayaNumber,
      pageNumber: widget.ayah.pageNumber,
    );
    await ref.read(bookmarkProvider.notifier).setBookmark(newBookmark);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bookmark disimpan di Surah ${widget.ayah.suraId}, Ayat ${widget.ayah.ayaNumber}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
  Future<void> _copyRawData() async {
    // Mengambil data tajweedText, atau teks biasa jika tidak ada
    final rawText = widget.ayah.tajweedText ?? widget.ayah.ayaText;
    await Clipboard.setData(ClipboardData(text: rawText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data mentah tajwid telah disalin ke clipboard.'),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final arabicFontSize = settings.arabicFontSize;
    final bookmarkAsync = ref.watch(bookmarkProvider);

    // Cek apakah ayat ini adalah yang sedang di-bookmark
    final bool isBookmarked = bookmarkAsync.when(
      data: (bookmark) =>
          bookmark != null &&
          bookmark.surahId == widget.ayah.suraId &&
          bookmark.ayahNumber == widget.ayah.ayaNumber,
      loading: () => false,
      error: (e, s) => false,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Text(
                  widget.ayah.ayaNumber.toString(),
                  style: TextStyle(color: Theme.of(context).primaryColor),
                ),
              ),
              title: widget.ayah.sajda
                  ? const Row(children: [Text("Ayat Sajdah ۩")])
                  : null,
              
              // #### PERUBAHAN IKON DAN FUNGSI TOMBOL DI SINI ####
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.content_copy_outlined),
                    tooltip: 'Salin Data Mentah',
                    onPressed: _copyRawData,
                  ),
                  IconButton(
                    icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined),
                    color: isBookmarked ? Theme.of(context).primaryColor : null,
                    tooltip: isBookmarked ? 'Ini adalah bookmark Anda' : 'Simpan Bookmark',
                    onPressed: isBookmarked ? null : _setBookmark,
                  ),
                ],
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
                      Tab(text: 'Arti'),
                      Tab(text: 'Tafsir'),
                      Tab(text: 'Audio'),
                    ],
                  ),
                  SizedBox(
                    height: 280,
                    child: TabBarView(
                      children: [
                        _buildTextTab(arabicFontSize),
                        _buildTranslationTab(),
                        _buildTafsirTab(),
                        _buildAudioTab(),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextTab(double fontSize) {
    final baseTextStyle = TextStyle(fontFamily: 'LPMQ', fontSize: fontSize, height: 2.0, color: Colors.white);
    final textToParse = widget.ayah.tajweedText;
    final textSpans = TajweedParser.parse(textToParse, baseTextStyle);
  
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            text: TextSpan(
              style: baseTextStyle,
              children: textSpans, // Daftar TextSpan berwarna dimasukkan di sini
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            widget.ayah.transliteration,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: fontSize * 0.6,
              fontStyle: FontStyle.italic,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(widget.ayah.translationAyaText, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildTafsirTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(widget.ayah.tafsirJalalayn, style: const TextStyle(fontSize: 16)),
    );
  }
  
  Widget _buildAudioTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Mishary Rashid Alafasy'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                iconSize: 50,
                color: Theme.of(context).primaryColor,
                onPressed: _playerState == PlayerState.playing ? _pauseAudio : _playAudio,
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined),
                iconSize: 50,
                onPressed: _stopAudio,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

