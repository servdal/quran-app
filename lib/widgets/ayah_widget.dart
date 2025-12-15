import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/screens/download_manager_screen.dart';
import '../../models/ayah_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/tajweed_parser.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
  final audioIndexAsync = ref.read(audioIndexProvider);

  audioIndexAsync.when(
    data: (audioList) async {
      final match = audioList.firstWhere(
        (e) => (e['surah_ids'] as List).contains(widget.ayah.suraId),
        orElse: () => {},
      );

      if (match.isEmpty) {
        _showNoAudio();
        return;
      }

      final filename = match['file'];
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/audio/$filename';
      final file = File(path);

      if (!await file.exists()) {
        _showNeedDownload();
        return;
      }

      await _audioPlayer.play(DeviceFileSource(path));
    },
    loading: () => _snack('Memuat indeks audio...'),
    error: (e, _) => _snack('Gagal baca audio index'),
  );
}


  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
  }

  void _saveBookmark(WidgetRef ref, String name) {
    final newBookmark = Bookmark(
      type: widget.viewType.name,
      surahId: widget.ayah.suraId,
      surahName: widget.ayah.surah?.englishName ?? 'Surah ${widget.ayah.suraId}',
      ayahNumber: widget.ayah.ayaNumber,
      pageNumber: widget.ayah.pageNumber,
    );
    ref.read(bookmarkProvider.notifier).addOrUpdateBookmark(name, newBookmark);
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      SnackBar(content: Text('Ayat ditandai di "$name".')),
    );
  }

  Future<void> _copyRawData() async {
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

    await Clipboard.setData(ClipboardData(text: fullAyahText.trim()));
    ScaffoldMessenger.of(context as BuildContext).showSnackBar(
      const SnackBar(
        content: Text('Informasi lengkap ayat telah disalin ke clipboard.'),
      ),
    );
  }
  void _showBookmarkDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    final bookmarks = ref.read(bookmarkProvider);
    final existingNames = bookmarks.keys.toList();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Simpan Bookmark'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bookmark Baru',
                    hintText: 'Contoh: Hafalan Juz 30',
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Atau timpa yang sudah ada:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Divider(),
                if (existingNames.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: Text('Belum ada bookmark.')),
                  )
                else
                  // Membuat daftar bisa di-scroll jika itemnya banyak
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: existingNames.length,
                      itemBuilder: (context, index) {
                        final name = existingNames[index];
                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            _saveBookmark(ref, name);
                            Navigator.of(dialogContext).pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Simpan Baru'),
              onPressed: () {
                final newName = textController.text.trim();
                if (newName.isNotEmpty) {
                  _saveBookmark(ref, newName);
                  Navigator.of(dialogContext).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Nama bookmark tidak boleh kosong.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final arabicFontSize = settings.arabicFontSize;
    final bookmarkAsync = ref.watch(bookmarkProvider);

    
    final infoTextStyle = TextStyle(
      fontSize: 12,
      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
    );
    return Column(
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
            spacing: 8.0,
            runSpacing: 4.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Juz ${widget.ayah.juzId}', style: infoTextStyle),
              Text('Hal. ${widget.ayah.pageNumber}', style: infoTextStyle),
              Text('Surah Ke. ${widget.ayah.suraId}', style: infoTextStyle),
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
                icon: const Icon(Icons.bookmark_add_outlined),
                tooltip: 'Simpan Bookmark',
                onPressed: () => _showBookmarkDialog(context, ref),
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
    );
  }

  Widget _buildTextTab(double fontSize) {
    final baseTextStyle = TextStyle(
        fontFamily: 'LPMQ',
        fontSize: fontSize,
        height: 2.0,
        color: Theme.of(context as BuildContext).colorScheme.onSurface);
        
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
              color: Theme.of(context as BuildContext).textTheme.bodyMedium?.color?.withOpacity(0.7),
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
          const Text('KH Bahauddin Nursalim'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(_playerState == PlayerState.playing ? Icons.pause_circle_filled : Icons.play_circle_filled),
                iconSize: 50,
                color: Theme.of(context as BuildContext).primaryColor,
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

void _showNeedDownload() {
  ScaffoldMessenger.of(context as BuildContext).showSnackBar(
    SnackBar(
      content: const Text('Audio belum diunduh'),
      action: SnackBarAction(
        label: 'Unduh',
        onPressed: () {
          Navigator.push(
            context as BuildContext,
            MaterialPageRoute(
              builder: (_) => const DownloadManagerScreen(),
            ),
          );
        },
      ),
    ),
  );
}

void _showNoAudio() {
  _snack('Audio untuk surah ini belum tersedia');
}

void _snack(String msg) {
  ScaffoldMessenger.of(context as BuildContext)
      .showSnackBar(SnackBar(content: Text(msg)));
}

