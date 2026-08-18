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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(downloadServiceProvider.notifier).loadDownloadedFiles();
    });
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
            else ...[
              const Text(
                "🎵 Atur Kontrol Daftar Putar (Playlist)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pilih Qari / Syaikh:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedReciter,
                            isExpanded: true,
                            hint: const Text(
                              "Belum ada Syaikh terunduh",
                              style: TextStyle(fontSize: 13),
                            ),
                            items:
                                availableReciters.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                            onChanged:
                                (newValue) =>
                                    setState(() => _selectedReciter = newValue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _startSurahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Mulai Surah",
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _startAyahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Mulai Ayat",
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _endSurahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Sampai Surah",
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _endAyahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Sampai Ayat",
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Ulangi (Repeat):",
                                style: TextStyle(fontSize: 13),
                              ),
                              Switch(
                                value: _isRepeat,
                                onChanged:
                                    (val) => setState(() => _isRepeat = val),
                              ),
                              Text(
                                _isRepeat ? "YES" : "NO",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _isRepeat ? Colors.green : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            onPressed:
                                _selectedReciter == null
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Daftar putar berhasil disimpan!",
                                          ),
                                        ),
                                      );
                                    },
                            child: const Text("Simpan"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                "📋 Playlist Aktif Tersimpan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Expanded(
                flex: 2,
                child:
                    downloader.playlists.isEmpty
                        ? const Center(
                          child: Text(
                            "Belum ada playlist diatur.",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                        : ListView.builder(
                          itemCount: downloader.playlists.length,
                          itemBuilder: (context, index) {
                            final p = downloader.playlists[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.playlist_play,
                                  color: Colors.teal,
                                ),
                                title: Text(
                                  "Surah ${p.startSurah}:${p.startAyah} s/d Surah ${p.endSurah}:${p.endAyah}",
                                ),
                                subtitle: Text(
                                  "Repeat: ${p.isRepeat ? 'YES' : 'NO'} | Qari: ${p.reciterName}",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.play_arrow,
                                        color: Colors.green,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(
                                              playerServiceProvider.notifier,
                                            )
                                            .playPlaylist(p);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => ref
                                              .read(
                                                downloadServiceProvider
                                                    .notifier,
                                              )
                                              .deletePlaylistItem(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
              const Divider(),
              const Text(
                "📁 Daftar Qari / Syaikh Terunduh (Lokal)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Expanded(
                flex: 1,
                child:
                    availableReciters.isEmpty
                        ? const Center(
                          child: Text(
                            "Kosong. Silakan tambah Syaikh baru.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.builder(
                          itemCount: availableReciters.length,
                          itemBuilder: (context, index) {
                            final folderSyaikh = availableReciters.elementAt(
                              index,
                            );
                            final jumlahAyat =
                                downloader.localAudioFiles
                                    .where(
                                      (file) =>
                                          file.startsWith('$folderSyaikh/'),
                                    )
                                    .length;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                dense: true,
                                leading: const Icon(
                                  Icons.folder,
                                  size: 24,
                                  color: Colors.amber,
                                ),
                                title: Text(
                                  folderSyaikh
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                subtitle: Text(
                                  "$jumlahAyat berkas audio ayat tersimpan",
                                  style: const TextStyle(fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.teal,
                                      ),
                                      tooltip: "Pilih Qari ini",
                                      onPressed: () {
                                        setState(
                                          () => _selectedReciter = folderSyaikh,
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.folder_delete,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: "Hapus Syaikh ini dari device",
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  "Hapus Qari?",
                                                ),
                                                content: Text(
                                                  "Apakah Anda yakin ingin menghapus seluruh file audio dari Syaikh $folderSyaikh?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Navigator.pop(
                                                          context,
                                                        ),
                                                    child: const Text("Batal"),
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
                                                        setState(
                                                          () =>
                                                              _selectedReciter =
                                                                  null,
                                                        );
                                                      }
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text(
                                                      "Hapus",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),

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
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "Qari: ${player.subtitle}",
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Tambah Qari / Syaikh Lain (Online)'),
                  onPressed:
                      downloader.isDownloading
                          ? null
                          : () => ref
                              .read(downloadServiceProvider.notifier)
                              .toggleDownloaderMode(true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
