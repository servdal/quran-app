import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart'; // <-- IMPORT YANG HILANG DITAMBAHKAN DI SINI

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

  @override
  Widget build(BuildContext context) {
    final arabicFontSize = ref.watch(arabicFontSizeProvider);

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
              trailing: IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: _setBookmark,
                tooltip: 'Simpan Bookmark',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.ayah.ayaText,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'LPMQ', fontSize: fontSize, height: 2.0),
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

