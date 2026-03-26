import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../models/ayah_model.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/tajweed_parser.dart';
import '../../utils/auto_tajweed_parser.dart';

class AyahWidget extends ConsumerStatefulWidget {
  final Ayah ayah;
  final BookmarkViewType viewType;

  const AyahWidget({super.key, required this.ayah, required this.viewType});

  @override
  ConsumerState<AyahWidget> createState() => _AyahWidgetState();
}

class _AyahWidgetState extends ConsumerState<AyahWidget>
    with SingleTickerProviderStateMixin {
  static final Map<String, _RemoteAyahText> _remoteTextCache = {};

  final ScreenshotController _screenshotController = ScreenshotController();
  late final TabController _tabController;
  Future<_RemoteAyahText?>? _remoteTextFuture;
  String? _remoteFutureLang;
  bool _translationRequested = false;
  bool _tafsirRequested = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_tabController.index == 1 && !_translationRequested) {
      setState(() => _translationRequested = true);
      _ensureRemoteTextLoaded();
      return;
    }
    if (_tabController.index == 2 && !_tafsirRequested) {
      setState(() => _tafsirRequested = true);
      _ensureRemoteTextLoaded();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AyahWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ayah.id == widget.ayah.id) return;

    _translationRequested = false;
    _tafsirRequested = false;
    _remoteTextFuture = null;
    _remoteFutureLang = null;
    _tabController.index = 0;
  }

  void _resetRemoteFutureIfLanguageChanged(String lang) {
    if (_remoteFutureLang == lang) return;
    _remoteFutureLang = lang;
    _remoteTextFuture = null;
  }

  void _ensureRemoteTextLoaded() {
    final lang = ref.read(settingsProvider).language;
    if (lang == 'id' || lang == 'en') return;

    _resetRemoteFutureIfLanguageChanged(lang);
    if (_remoteTextFuture != null) return;

    final cacheKey = '${widget.ayah.id}:$lang';
    if (_remoteTextCache.containsKey(cacheKey)) {
      _remoteTextFuture = Future.value(_remoteTextCache[cacheKey]);
      return;
    }

    _remoteTextFuture = _RemoteTranslationService.translateAyah(
      ayah: widget.ayah,
      targetLang: lang,
    ).then((value) {
      if (value != null) {
        _remoteTextCache[cacheKey] = value;
      }
      return value;
    });
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
      builder:
          (_) => AlertDialog(
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

  Future<void> _shareAyahImage() async {
    final settings = ref.read(settingsProvider);
    final isId = settings.language == 'id';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final media = MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.noScaling);
      final bytes = await _screenshotController.captureFromWidget(
        MediaQuery(data: media, child: _buildShareImageWidget(isId)),
        context: context,
        delay: const Duration(milliseconds: 30),
        pixelRatio: MediaQuery.of(context).devicePixelRatio * 1.7,
      );

      final tempDir = await getTemporaryDirectory();
      final filename =
          'ayah_${widget.ayah.surahId}_${widget.ayah.number}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject:
              isId
                  ? 'QS ${widget.ayah.surahName} : ${widget.ayah.number}'
                  : 'Quran ${widget.ayah.surahName} : ${widget.ayah.number}',
          text:
              isId
                  ? 'QS ${widget.ayah.surahName} ayat ${widget.ayah.number}'
                  : 'Quran ${widget.ayah.surahName} ayah ${widget.ayah.number}',
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _snack(
        isId ? 'Gagal membuat gambar share' : 'Failed to generate share image',
      );
    }
  }

  Widget _buildShareImageWidget(bool isId) {
    final tafsir = widget.ayah.tafsir.trim();
    final translation = widget.ayah.translation.trim();

    return Material(
      color: Colors.transparent,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / 1080).clamp(0.2, 1.0);
            double s(double value) => value * scale;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0A2A43),
                    Color(0xFF123E60),
                    Color(0xFFF7F2E9),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -s(140),
                    right: -s(100),
                    child: Container(
                      width: s(340),
                      height: s(340),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -s(120),
                    left: -s(80),
                    child: Container(
                      width: s(300),
                      height: s(300),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(s(44), s(44), s(44), s(40)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildShareHeader(isId, scale),
                        SizedBox(height: s(14)),
                        Expanded(
                          flex: 4,
                          child: _buildShareSection(
                            title: isId ? 'Teks Arab' : 'Arabic Text',
                            scale: scale,
                            child: Text(
                              widget.ayah.arabicText,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              maxLines: 8,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'LPMQ',
                                fontSize: s(64),
                                height: 1.9,
                                color: const Color(0xFF112A45),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: s(12)),
                        Expanded(
                          flex: 3,
                          child: _buildShareSection(
                            title: isId ? 'Terjemah' : 'Translation',
                            scale: scale,
                            child: Text(
                              translation.isEmpty ? '-' : translation,
                              maxLines: 8,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: s(31),
                                height: 1.5,
                                fontFamily: 'Poppins',
                                color: const Color(0xFF23364A),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: s(12)),
                        Expanded(
                          flex: 5,
                          child: _buildShareSection(
                            title: 'Tafsir',
                            scale: scale,
                            child: Text(
                              tafsir.isEmpty ? '-' : tafsir,
                              maxLines: 16,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: s(26),
                                height: 1.5,
                                fontFamily: 'Poppins',
                                color: const Color(0xFF29415A),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: s(8)),
                        Text(
                          'Quran App • ${widget.ayah.surahName} ${isId ? 'ayat' : 'ayah'} ${widget.ayah.number}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w600,
                            fontSize: s(22),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShareHeader(bool isId, double scale) {
    double s(double value) => value * scale;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: s(20), vertical: s(16)),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(s(20)),
        border: Border.all(
          color: Colors.white.withOpacity(0.28),
          width: s(1.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            widget.ayah.surahName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: s(40),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: s(8)),
          Text(
            isId
                ? 'Juz ${widget.ayah.juz} • Halaman ${widget.ayah.page} • Ayat ${widget.ayah.number}'
                : 'Juz ${widget.ayah.juz} • Page ${widget.ayah.page} • Ayah ${widget.ayah.number}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: s(21),
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildShareSection({
    required String title,
    required Widget child,
    required double scale,
  }) {
    double s(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(s(18), s(14), s(18), s(14)),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFDF8),
        borderRadius: BorderRadius.circular(s(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: s(18),
            offset: Offset(0, s(8)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: s(22),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F3556),
            ),
          ),
          SizedBox(height: s(8)),
          Expanded(child: child),
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
    final panelFontSize = settings.ayahPanelFontSize;
    final bookmarksMap = ref.watch(bookmarkProvider);
    final matchingBookmarkCount =
        bookmarksMap.values
            .where(
              (bookmark) =>
                  bookmark.surahId == widget.ayah.surahId &&
                  bookmark.ayahNumber == widget.ayah.number,
            )
            .length;
    final isBookmarked = matchingBookmarkCount > 0;

    final baseArabicStyle = TextStyle(
      fontFamily: 'LPMQ',
      fontSize: panelFontSize,
      height: 2.2,
      color: theme.colorScheme.onSurface,
    );

    final isId = settings.language == 'id';
    final sumber = settings.arabicSource;
    final lang = settings.language;
    _resetRemoteFutureIfLanguageChanged(lang);
    final spans =
        sumber == ArabicSource.kemenag
            ? AutoTajweedParser.parse(
              widget.ayah.arabicText,
              baseArabicStyle,
              lang: lang,
              context: context,
              learningMode: true,
            )
            : TajweedParser.parse(
              widget.ayah.tajweedText,
              baseArabicStyle,
              lang: lang,
              context: context,
              learningMode: true,
            );
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            child: Text(
              widget.ayah.number.toString(),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          title: Text(
            isId
                ? 'Juz ${widget.ayah.juz} | Hal ${widget.ayah.page}'
                : 'Juz ${widget.ayah.juz} | Page ${widget.ayah.page}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: isId ? 'Bagikan ayat' : 'Share ayah',
                icon: const Icon(Icons.ios_share_rounded),
                onPressed: _shareAyahImage,
              ),
              IconButton(
                tooltip:
                    isBookmarked
                        ? (isId
                            ? 'Tersimpan di $matchingBookmarkCount bookmark'
                            : 'Saved in $matchingBookmarkCount bookmark(s)')
                        : (isId ? 'Simpan bookmark' : 'Save bookmark'),
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
                  color: isBookmarked ? theme.colorScheme.primary : null,
                ),
                onPressed: _bookmarkDialog,
              ),
            ],
          ),
        ),

        Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                Tab(text: isId ? 'Teks' : 'Text'),
                Tab(text: isId ? 'Terjemah' : 'Translation'),
                const Tab(text: 'Tafsir'),
                const Tab(text: 'Audio'),
              ],
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _tabText(spans),
                  _tabTranslation(lang),
                  _tabTafsir(lang),
                  _tabAudio(isId),
                ],
              ),
            ),
          ],
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
    final panelFontSize = settings.ayahPanelFontSize;

    final String transliterationText =
        settings.language == 'id'
            ? widget.ayah.transliterationKemenag.trim()
            : widget.ayah.transliteration.trim();

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
            Divider(color: theme.dividerColor.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              transliterationText,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: panelFontSize * 0.6,
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

  Widget _tabTranslation(String lang) {
    final panelFontSize = ref.watch(settingsProvider).ayahPanelFontSize;
    if (lang == 'id' || lang == 'en') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.ayah.translation,
          style: TextStyle(fontSize: panelFontSize * 0.6),
        ),
      );
    }

    if (!_translationRequested) {
      return const Center(child: CircularProgressIndicator());
    }

    _ensureRemoteTextLoaded();
    return FutureBuilder<_RemoteAyahText?>(
      future: _remoteTextFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildTranslateLoading(isId: lang == 'id');
        }
        final text = snapshot.data?.translation ?? widget.ayah.translation;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(text, style: TextStyle(fontSize: panelFontSize)),
        );
      },
    );
  }

  Widget _tabTafsir(String lang) {
    final panelFontSize = ref.watch(settingsProvider).ayahPanelFontSize;
    if (lang == 'id' || lang == 'en') {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.ayah.tafsir,
          style: TextStyle(fontSize: panelFontSize * 0.6),
        ),
      );
    }

    if (!_tafsirRequested) {
      return const Center(child: CircularProgressIndicator());
    }

    _ensureRemoteTextLoaded();
    return FutureBuilder<_RemoteAyahText?>(
      future: _remoteTextFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildTranslateLoading(isId: lang == 'id');
        }
        final text = snapshot.data?.tafsir ?? widget.ayah.tafsir;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(text, style: TextStyle(fontSize: panelFontSize)),
        );
      },
    );
  }

  Widget _buildTranslateLoading({required bool isId}) {
    final color = Theme.of(context).primaryColor;
    final panelFontSize = ref.watch(settingsProvider).ayahPanelFontSize;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3.2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isId ? 'Memuat terjemahan...' : 'Loading translation...',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: panelFontSize * 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabAudio(bool isId) {
    final panelFontSize = ref.watch(settingsProvider).ayahPanelFontSize;
    final videoId = YoutubePlayer.convertUrlToId(
      'https://www.youtube.com/watch?v=fM7BQNV6koc&list=PLdfZWRI2eOVYYEkjAqrGm7AgWuPn_26jk',
    );

    if (videoId == null) {
      return Center(
        child: Text(
          'Video tidak valid',
          style: TextStyle(fontSize: panelFontSize),
        ),
      );
    }

    return YoutubeAudioTab(videoId: videoId, isId: isId);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _RemoteAyahText {
  final String? translation;
  final String? tafsir;

  const _RemoteAyahText({this.translation, this.tafsir});
}

class _RemoteTranslationService {
  static const String _apiKey = String.fromEnvironment(
    'CORE_TRANSLATE_API_KEY',
    defaultValue: '',
  );

  static const List<String> _endpoints = [
    'https://duidev.com/api/translate/ayahs',
    'http://duidev.com/api/translate/ayahs',
  ];

  static Future<_RemoteAyahText?> translateAyah({
    required Ayah ayah,
    required String targetLang,
  }) async {
    if (targetLang == 'id' || targetLang == 'en') {
      return null;
    }

    for (final endpoint in _endpoints) {
      try {
        final response = await http
            .post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                if (_apiKey.isNotEmpty) 'X-API-Key': _apiKey,
              },
              body: jsonEncode({
                'target_lang': targetLang,
                'items': [
                  {
                    'ayah_id': ayah.id,
                    'surah_id': ayah.surahId,
                    'ayah_number': ayah.number,
                    'translation': ayah.translation,
                    'tafsir': ayah.tafsir,
                  },
                ],
              }),
            )
            .timeout(const Duration(seconds: 12));

        if (response.statusCode < 200 || response.statusCode >= 300) {
          continue;
        }

        final decoded = jsonDecode(response.body);
        final rows = _extractRows(decoded);
        if (rows.isEmpty) {
          continue;
        }

        final row = rows.firstWhere(
          (item) => item is Map<String, dynamic>,
          orElse: () => const {},
        );

        if (row is! Map<String, dynamic>) {
          continue;
        }

        final translation = _toNullableString(
          row['translation'] ?? row['translated_translation'],
        );
        final tafsir = _toNullableString(
          row['tafsir'] ?? row['translated_tafsir'],
        );

        if (translation == null && tafsir == null) {
          continue;
        }

        return _RemoteAyahText(translation: translation, tafsir: tafsir);
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  static List<dynamic> _extractRows(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
      final items = decoded['items'];
      if (items is List) return items;
      final results = decoded['results'];
      if (results is List) return results;
    }
    return const [];
  }

  static String? _toNullableString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return str;
  }
}

class YoutubeAudioTab extends StatefulWidget {
  final String videoId;
  final bool isId;

  const YoutubeAudioTab({super.key, required this.videoId, this.isId = true});

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
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: YoutubePlayer(
                controller: _controller,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
