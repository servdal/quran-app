import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/download_provider.dart';
import 'package:quran_app/providers/player_provider.dart';
import 'package:quran_app/screens/murottal_player_screen.dart';

class DownloadManagerScreen extends ConsumerStatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  ConsumerState<DownloadManagerScreen> createState() =>
      _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends ConsumerState<DownloadManagerScreen> {
  static const List<int> _ayahCountsBySurah = [
    0,
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3,
    5,
    4,
    5,
    6,
  ];

  final _startSurahCtrl = TextEditingController(text: "1");
  final _startAyahCtrl = TextEditingController(text: "1");
  final _endSurahCtrl = TextEditingController(text: "1");
  final _endAyahCtrl = TextEditingController(text: "7");
  bool _isRepeat = false;
  String? _selectedReciter;
  bool _showPlaylistForm = true;
  bool _showSavedPlaylists = false;
  bool _showDownloadedReciters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadServiceProvider.notifier).loadDownloadedFiles();
    });
  }

  @override
  void dispose() {
    _startSurahCtrl.dispose();
    _startAyahCtrl.dispose();
    _endSurahCtrl.dispose();
    _endAyahCtrl.dispose();
    super.dispose();
  }

  String? _validatePlaylistRange({
    required int? startSurah,
    required int? startAyah,
    required int? endSurah,
    required int? endAyah,
  }) {
    if (startSurah == null ||
        startAyah == null ||
        endSurah == null ||
        endAyah == null) {
      return "Surah dan ayat harus diisi dengan angka.";
    }

    final startError = _validateAyahPosition(startSurah, startAyah, "Mulai");
    if (startError != null) return startError;

    final endError = _validateAyahPosition(endSurah, endAyah, "Sampai");
    if (endError != null) return endError;

    if (startSurah > endSurah ||
        (startSurah == endSurah && startAyah > endAyah)) {
      return "Rentang playlist tidak valid. Posisi mulai harus sebelum posisi sampai.";
    }

    return null;
  }

  String? _validateAyahPosition(int surah, int ayah, String label) {
    if (surah < 1 || surah >= _ayahCountsBySurah.length) {
      return "$label surah harus antara 1 sampai 114.";
    }

    final maxAyah = _ayahCountsBySurah[surah];
    if (ayah < 1 || ayah > maxAyah) {
      return "$label ayat tidak valid. Surah $surah hanya memiliki $maxAyah ayat.";
    }

    return null;
  }


  Future<void> _offerMurottalMode() async {
    final player = ref.read(playerServiceProvider);

    if (!player.isPlaying) return;

    final switchMode = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mode Murottal'),
        content: const Text(
          'Audio sedang diputar. Beralih ke tampilan Murottal Player landscape?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap di sini'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.fullscreen_rounded),
            label: const Text('Buka Player'),
          ),
        ],
      ),
    );

    if (switchMode != true || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MurottalPlayerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final downloader = ref.watch(downloadServiceProvider);
    final player = ref.watch(playerServiceProvider);

    final Set<String> availableReciters = {};
    for (var fileData in downloader.localAudioFiles) {
      if (fileData.contains('/')) {
        availableReciters.add(fileData.split('/').first);
      }
    }

    if (_selectedReciter == null && availableReciters.isNotEmpty) {
      _selectedReciter = availableReciters.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          downloader.showDownloaderList
              ? 'Unduh Syaikh Baru'
              : 'Manajer Audio Murottal',
        ),
        leading:
            downloader.showDownloaderList
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed:
                      () => ref
                          .read(downloadServiceProvider.notifier)
                          .toggleDownloaderMode(false),
                )
                : null,
        actions: [
          if (!downloader.showDownloaderList &&
              (downloader.localAudioFiles.isNotEmpty ||
                  downloader.playlists.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: "Reset / Hapus Semua Data",
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Reset Semua Data Audio?"),
                        content: const Text(
                          "Tindakan ini akan menghapus seluruh folder Syaikh yang sudah diunduh beserta semua daftar putar (playlist) Anda. Data tidak dapat dikembalikan.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(downloadServiceProvider.notifier)
                                  .resetAllData();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Seluruh storage murottal dibersihkan!",
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              "Ya, Hapus Semua",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (downloader.isDownloading) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      downloader.statusMessage,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Berkas: ${downloader.currentFile}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value:
                          downloader.progress > 0 ? downloader.progress : null,
                      backgroundColor: Colors.blue.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${(downloader.progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        if (downloader.downloadSpeed.isNotEmpty &&
                            downloader.downloadSpeed != "0 KB/s")
                          Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 14,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                downloader.downloadSpeed,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Sisa: ${downloader.remainingTime}",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (player.title.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Sedang Memutar: ${player.title}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "Qari: ${player.subtitle}",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Shortcut kecil ke mode Murottal landscape.
                    if (player.isPlaying)
                      IconButton(
                        icon: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.cyanAccent,
                        ),
                        tooltip: 'Buka Mode Murottal',
                        onPressed: _offerMurottalMode,
                      ),

                    // Tombol Pause / Play
                    IconButton(
                      icon: Icon(
                        player.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed:
                          () =>
                              ref
                                  .read(playerServiceProvider.notifier)
                                  .togglePausePlay(),
                    ),
                    // Tombol Stop
                    IconButton(
                      icon: const Icon(Icons.stop, color: Colors.white),
                      onPressed:
                          () =>
                              ref.read(playerServiceProvider.notifier).stop(),
                    ),
                  ],
                ),
              ),


            if (downloader.showDownloaderList)
              Expanded(
                child:
                    downloader.zipLinks.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          itemCount: downloader.zipLinks.length,
                          itemBuilder: (context, index) {
                            final reciter = downloader.zipLinks[index];
                            return ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.teal,
                              ),
                              title: Text(
                                reciter.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: FutureBuilder<bool>(
                                future: ref
                                    .read(downloadServiceProvider.notifier)
                                    .isZipDownloaded(
                                      reciter.zipUrl,
                                      reciter.name,
                                    ),
                                builder: (context, snap) {
                                  if (snap.data == true) {
                                    return const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    );
                                  }
                                  return IconButton(
                                    icon: const Icon(
                                      Icons.cloud_download,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        downloader.isDownloading
                                            ? null
                                            : () => ref
                                                .read(
                                                  downloadServiceProvider
                                                      .notifier,
                                                )
                                                .downloadAndExtractZip(
                                                  reciter.zipUrl,
                                                  reciter.name,
                                                ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
              )
            else
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    _ExpandableSection(
                      title: 'Buat Playlist',
                      subtitle: 'Atur rentang ayat dan Qari',
                      icon: Icons.queue_music_rounded,
                      expanded: _showPlaylistForm,
                      onTap: () {
                        setState(() {
                          _showPlaylistForm = !_showPlaylistForm;
                        });
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pilih Qari / Syaikh',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedReciter,
                                isExpanded: true,
                                hint: const Text(
                                  'Belum ada Syaikh terunduh',
                                  style: TextStyle(fontSize: 13),
                                ),
                                items: availableReciters.map((value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value.replaceAll('_', ' ').toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() => _selectedReciter = newValue);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _startSurahCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Mulai Surah',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _startAyahCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Mulai Ayat',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _endSurahCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Sampai Surah',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _endAyahCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Sampai Ayat',
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Switch.adaptive(
                                      value: _isRepeat,
                                      onChanged: (value) {
                                        setState(() => _isRepeat = value);
                                      },
                                    ),
                                    Flexible(
                                      child: Text(
                                        _isRepeat ? 'Repeat aktif' : 'Tanpa repeat',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _selectedReciter == null
                                    ? null
                                    : () {
                                        final startSurah = int.tryParse(
                                          _startSurahCtrl.text,
                                        );
                                        final startAyah = int.tryParse(
                                          _startAyahCtrl.text,
                                        );
                                        final endSurah = int.tryParse(
                                          _endSurahCtrl.text,
                                        );
                                        final endAyah = int.tryParse(
                                          _endAyahCtrl.text,
                                        );
                                        final validationMessage =
                                            _validatePlaylistRange(
                                          startSurah: startSurah,
                                          startAyah: startAyah,
                                          endSurah: endSurah,
                                          endAyah: endAyah,
                                        );

                                        if (validationMessage != null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(validationMessage),
                                            ),
                                          );
                                          return;
                                        }

                                        ref
                                            .read(
                                              downloadServiceProvider.notifier,
                                            )
                                            .addPlaylistItem(
                                              reciterName: _selectedReciter!,
                                              startSurah: startSurah!,
                                              startAyah: startAyah!,
                                              endSurah: endSurah!,
                                              endAyah: endAyah!,
                                              isRepeat: _isRepeat,
                                            );
                                        setState(() {
                                          _showSavedPlaylists = true;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Daftar putar berhasil disimpan!',
                                            ),
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.save_rounded, size: 18),
                                label: const Text('Simpan'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _ExpandableSection(
                      title: 'Playlist Tersimpan',
                      subtitle: downloader.playlists.isEmpty
                          ? 'Belum ada playlist'
                          : '${downloader.playlists.length} playlist tersedia',
                      badge: '${downloader.playlists.length}',
                      icon: Icons.playlist_play_rounded,
                      expanded: _showSavedPlaylists,
                      onTap: () {
                        setState(() {
                          _showSavedPlaylists = !_showSavedPlaylists;
                        });
                      },
                      child: downloader.playlists.isEmpty
                          ? const _EmptySection(
                              icon: Icons.playlist_remove_rounded,
                              message: 'Belum ada playlist diatur.',
                            )
                          : Column(
                              children: List.generate(
                                downloader.playlists.length,
                                (index) {
                                  final p = downloader.playlists[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index ==
                                              downloader.playlists.length - 1
                                          ? 0
                                          : 8,
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                      title: Text(
                                        'Surah ${p.startSurah}:${p.startAyah} → '
                                        '${p.endSurah}:${p.endAyah}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${p.reciterName.replaceAll('_', ' ')} • '
                                        '${p.isRepeat ? 'Repeat' : 'Sekali putar'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'play') {
                                            ref
                                                .read(
                                                  playerServiceProvider.notifier,
                                                )
                                                .playPlaylist(p);
                                          } else if (value == 'delete') {
                                            ref
                                                .read(
                                                  downloadServiceProvider
                                                      .notifier,
                                                )
                                                .deletePlaylistItem(index);
                                          }
                                        },
                                        itemBuilder: (context) => const [
                                          PopupMenuItem(
                                            value: 'play',
                                            child: ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: Icon(
                                                Icons.play_arrow_rounded,
                                              ),
                                              title: Text('Putar'),
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              leading: Icon(
                                                Icons.delete_outline_rounded,
                                                color: Colors.redAccent,
                                              ),
                                              title: Text('Hapus'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                    _ExpandableSection(
                      title: 'Qari Terunduh',
                      subtitle: availableReciters.isEmpty
                          ? 'Belum ada Qari lokal'
                          : '${availableReciters.length} Qari tersedia',
                      badge: '${availableReciters.length}',
                      icon: Icons.library_music_rounded,
                      expanded: _showDownloadedReciters,
                      onTap: () {
                        setState(() {
                          _showDownloadedReciters =
                              !_showDownloadedReciters;
                        });
                      },
                      child: Column(
                        children: [
                          if (availableReciters.isEmpty)
                            const _EmptySection(
                              icon: Icons.cloud_download_outlined,
                              message: 'Belum ada Qari yang diunduh.',
                            )
                          else
                            ...availableReciters.map((folderSyaikh) {
                              final jumlahAyat = downloader.localAudioFiles
                                  .where(
                                    (file) =>
                                        file.startsWith('$folderSyaikh/'),
                                  )
                                  .length;
                              final selected =
                                  _selectedReciter == folderSyaikh;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  tileColor: selected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: .45)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest
                                          .withValues(alpha: .45),
                                  leading: Icon(
                                    selected
                                        ? Icons.check_circle_rounded
                                        : Icons.folder_rounded,
                                    color: selected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.amber.shade700,
                                  ),
                                  title: Text(
                                    folderSyaikh
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '$jumlahAyat berkas audio tersimpan',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedReciter = folderSyaikh;
                                    });
                                  },
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'select') {
                                        setState(() {
                                          _selectedReciter = folderSyaikh;
                                        });
                                      } else if (value == 'delete') {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Hapus Qari?'),
                                            content: Text(
                                              'Hapus seluruh file audio dari '
                                              '$folderSyaikh?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Batal'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                        downloadServiceProvider
                                                            .notifier,
                                                      )
                                                      .deleteReciterFolder(
                                                        folderSyaikh,
                                                      );
                                                  if (_selectedReciter ==
                                                      folderSyaikh) {
                                                    setState(() {
                                                      _selectedReciter = null;
                                                    });
                                                  }
                                                  Navigator.pop(context);
                                                },
                                                child: const Text(
                                                  'Hapus',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'select',
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.check_circle_outline_rounded,
                                          ),
                                          title: Text('Pilih Qari'),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                          ),
                                          title: Text('Hapus dari device'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text(
                                'Tambah Qari / Syaikh Lain',
                              ),
                              onPressed: downloader.isDownloading
                                  ? null
                                  : () => ref
                                      .read(
                                        downloadServiceProvider.notifier,
                                      )
                                      .toggleDownloaderMode(true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final String? badge;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: expanded ? 1 : 0,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: .65),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (badge != null) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 28),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSecondaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: expanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                    child: child,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Icon(
            icon,
            size: 34,
            color: scheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
