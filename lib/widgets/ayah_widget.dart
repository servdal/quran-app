import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/utils/tajweed_parser.dart';
import 'package:quran_app/services/quran_data_service.dart';

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
    final audioMapAsyncValue = ref.read(audioPathsProvider);
    audioMapAsyncValue.when(
      data: (audioMap) async {
        final audioPath = audioMap[widget.ayah.ayaId];
        if (audioPath != null) {
          await _audioPlayer.play(AssetSource(audioPath.replaceFirst('assets/', '')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File audio untuk ayat ini tidak ditemukan.')),
          );
        }
      },
      loading: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memuat data audio...')),
      ),
      error: (e, s) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data audio: $e')),
      ),
    );
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  void _bookmarkAyah(WidgetRef ref) {
    ref.read(bookmarkProvider.notifier).setBookmark(
          surahId: widget.ayah.suraId,
          surahName: widget.ayah.surah?.englishName ?? widget.ayah.suraId.toString(),
          ayahNumber: widget.ayah.ayaId,
          pageNumber: widget.ayah.pageNumber,
          viewType: widget.viewType,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ayat telah ditandai.')),
    );
  }

  Future<void> _copyRawData() async {
    // Membuat string multi-baris yang terformat
    final String fullAyahText = """
    Surah ${widget.ayah.surah?.englishName ?? widget.ayah.suraId} Ayat ${widget.ayah.ayaNumber}

    Teks Arab:
    ${widget.ayah.ayaText}

    Transliterasi:
    ${widget.ayah.transliteration}

    Terjemahan:
    ${widget.ayah.translationAyaText}

    Tafsir Jalalayn:
    ${widget.ayah.tafsirJalalayn}
    """;

    // Menyalin string yang sudah diformat ke clipboard
    await Clipboard.setData(ClipboardData(text: fullAyahText.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Informasi lengkap ayat telah disalin ke clipboard.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final arabicFontSize = settings.arabicFontSize;
    final bookmarkAsync = ref.watch(bookmarkProvider);

    final bool isBookmarked = bookmarkAsync.when(
      data: (bookmark) =>
          bookmark != null &&
          bookmark.surahId == widget.ayah.suraId &&
          bookmark.ayahNumber == widget.ayah.ayaNumber,
      loading: () => false,
      error: (e, s) => false,
    );
    final infoTextStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
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
              title: Wrap(
                spacing: 8.0, // Jarak horizontal antar item
                runSpacing: 4.0, // Jarak vertikal jika item turun baris
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Juz ${widget.ayah.juzId}', style: infoTextStyle),
                  Text('Hal. ${widget.ayah.pageNumber}', style: infoTextStyle),
                  Text('Surah Ke. ${widget.ayah.suraId}', style: infoTextStyle),
                  // Menampilkan penanda Ayat Sajdah jika ada
                  if (widget.ayah.sajda)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        "۩ Ayat Sajdah",
                        style: infoTextStyle.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
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
                    onPressed: isBookmarked ? null : () => _bookmarkAyah(ref),
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
    // #### PERBAIKAN DI SINI ####
    // Warna teks dasar sekarang diambil dari tema (onSurface color)
    // yang akan menjadi hitam di tema terang dan putih di tema gelap.
    final baseTextStyle = TextStyle(
        fontFamily: 'LPMQ',
        fontSize: fontSize,
        height: 2.0,
        color: Theme.of(context).colorScheme.onSurface);
        
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
              children: textSpans,
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
              // Warna teks latin juga mengambil dari tema agar lebih konsisten
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
          const Text('KH Bahaudin Nursalim'),
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

