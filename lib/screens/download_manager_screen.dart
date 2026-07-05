import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/download_provider.dart';
import 'package:quran_app/providers/player_provider.dart';

class DownloadManagerScreen extends ConsumerStatefulWidget {
  const DownloadManagerScreen({super.key});

  @override
  ConsumerState<DownloadManagerScreen> createState() => _DownloadManagerScreenState();
}

class _DownloadManagerScreenState extends ConsumerState<DownloadManagerScreen> {
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

  @override
  Widget build(BuildContext context) {
    final downloader = ref.watch(downloadServiceProvider);
    final player = ref.watch(playerServiceProvider); // 🎧 Dengarkan state audio player

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
        title: Text(downloader.showDownloaderList ? 'Unduh Syaikh Baru' : 'Manajer Audio Murottal'),
        leading: downloader.showDownloaderList
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => ref.read(downloadServiceProvider.notifier).toggleDownloaderMode(false),
              )
            : null,
        actions: [
          if (!downloader.showDownloaderList && (downloader.localAudioFiles.isNotEmpty || downloader.playlists.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              tooltip: "Reset / Hapus Semua Data",
              onPressed: () {
                // Tampilkan dialog konfirmasi sebelum menghapus total
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Reset Semua Data Audio?"),
                    content: const Text("Tindakan ini akan menghapus seluruh folder Syaikh yang sudah diunduh beserta semua daftar putar (playlist) Anda. Data tidak dapat dikembalikan."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(downloadServiceProvider.notifier).resetAllData();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Seluruh storage murottal dibersihkan!"))
                          );
                        },
                        child: const Text("Ya, Hapus Semua", style: TextStyle(color: Colors.red)),
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
              LinearProgressIndicator(value: downloader.progress > 0 ? downloader.progress : null),
              const SizedBox(height: 4),
              Text("Memproses: ${downloader.currentFile}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
            ],

            if (downloader.showDownloaderList)
              Expanded(
                child: downloader.zipLinks.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: downloader.zipLinks.length,
                        itemBuilder: (context, index) {
                          final reciter = downloader.zipLinks[index];
                          return ListTile(
                            leading: const Icon(Icons.person, color: Colors.teal),
                            title: Text(reciter.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: FutureBuilder<bool>(
                              future: ref.read(downloadServiceProvider.notifier).isZipDownloaded(reciter.zipUrl),
                              builder: (context, snap) {
                                if (snap.data == true) return const Icon(Icons.check_circle, color: Colors.green);
                                return IconButton(
                                  icon: const Icon(Icons.cloud_download, color: Colors.blue),
                                  onPressed: downloader.isDownloading ? null : () => ref.read(downloadServiceProvider.notifier).downloadAndExtractZip(reciter.zipUrl),
                                );
                              },
                            ),
                          );
                        },
                      ),
              )
            else ...[
              const Text("🎵 Atur Kontrol Daftar Putar (Playlist)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Pilih Qari / Syaikh:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.teal)),
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
                            hint: const Text("Belum ada Syaikh terunduh", style: TextStyle(fontSize: 13)),
                            items: availableReciters.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (newValue) => setState(() => _selectedReciter = newValue),
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
                              decoration: const InputDecoration(labelText: "Mulai Surah", isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _startAyahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Mulai Ayat", isDense: true),
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
                              decoration: const InputDecoration(labelText: "Sampai Surah", isDense: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _endAyahCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Sampai Ayat", isDense: true),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text("Ulangi (Repeat):", style: TextStyle(fontSize: 13)),
                              Switch(
                                value: _isRepeat,
                                onChanged: (val) => setState(() => _isRepeat = val),
                              ),
                              Text(_isRepeat ? "YES" : "NO", style: TextStyle(fontWeight: FontWeight.bold, color: _isRepeat ? Colors.green : Colors.red)),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            onPressed: _selectedReciter == null 
                            ? null 
                            : () {
                              ref.read(downloadServiceProvider.notifier).addPlaylistItem(
                                reciterName: _selectedReciter!,
                                startSurah: int.tryParse(_startSurahCtrl.text) ?? 1,
                                startAyah: int.tryParse(_startAyahCtrl.text) ?? 1,
                                endSurah: int.tryParse(_endSurahCtrl.text) ?? 1,
                                endAyah: int.tryParse(_endAyahCtrl.text) ?? 1,
                                isRepeat: _isRepeat,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Daftar putar berhasil disimpan!")));
                            },
                            child: const Text("Simpan"),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text("📋 Playlist Aktif Tersimpan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Expanded(
                flex: 2,
                child: downloader.playlists.isEmpty
                    ? const Center(child: Text("Belum ada playlist diatur.", style: TextStyle(color: Colors.grey, fontSize: 12)))
                    : ListView.builder(
                        itemCount: downloader.playlists.length,
                        itemBuilder: (context, index) {
                          final p = downloader.playlists[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: const Icon(Icons.playlist_play, color: Colors.teal),
                              title: Text("Surah ${p.startSurah}:${p.startAyah} s/d Surah ${p.endSurah}:${p.endAyah}"),
                              subtitle: Text("Repeat: ${p.isRepeat ? 'YES' : 'NO'} | Qari: ${p.reciterName}", style: const TextStyle(fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 🌟 TOMBOL PUTAR (KINI BERFUNGSI NYATA)
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                                    onPressed: () {
                                      ref.read(playerServiceProvider.notifier).playPlaylist(p);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => ref.read(downloadServiceProvider.notifier).deletePlaylistItem(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),

              // --- SECTION C: STRUKTUR BERKAS LOKAL AUDIO DEVICE ---
              const Text("📁 Daftar Qari / Syaikh Terunduh (Lokal)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Expanded(
                flex: 1,
                child: availableReciters.isEmpty
                    ? const Center(child: Text("Kosong. Silakan tambah Syaikh baru.", style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: availableReciters.length,
                        itemBuilder: (context, index) {
                          final folderSyaikh = availableReciters.elementAt(index);

                          // Hitung berapa jumlah file ayat milik Syaikh ini di local list
                          final jumlahAyat = downloader.localAudioFiles.where((file) => file.startsWith('$folderSyaikh/')).length;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: true,
                              leading: const Icon(Icons.folder, size: 24, color: Colors.amber),
                              title: Text(
                                folderSyaikh.replaceAll('_', ' ').toUpperCase(), 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              subtitle: Text("$jumlahAyat berkas audio ayat tersimpan", style: const TextStyle(fontSize: 11)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Klik folder untuk memilih syaikh ini ke form playlist di atas
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.teal),
                                    tooltip: "Pilih Qari ini",
                                    onPressed: () {
                                      setState(() => _selectedReciter = folderSyaikh);
                                    },
                                  ),
                                  // 🌟 TOMBOL HAPUS FOLDER SYAIKH TERTENTU
                                  IconButton(
                                    icon: const Icon(Icons.folder_delete, color: Colors.redAccent),
                                    tooltip: "Hapus Syaikh ini dari device",
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Hapus Qari?"),
                                          content: Text("Apakah Anda yakin ingin menghapus seluruh file audio dari Syaikh $folderSyaikh?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text("Batal"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                ref.read(downloadServiceProvider.notifier).deleteReciterFolder(folderSyaikh);
                                                // Reset dropdown select jika syaikh yang dihapus kebetulan sedang terpilih
                                                if (_selectedReciter == folderSyaikh) {
                                                  setState(() => _selectedReciter = null);
                                                }
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Hapus", style: TextStyle(color: Colors.red)),
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
                              // 🔄 GANTI DI SINI: Langsung tampilkan teks dinamis dari background service
                              "Sedang Memutar: ${player.title}",
                              style: const TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              // 🔄 GANTI DI SINI: Menampilkan nama Syaikh/Qari yang dikirim background service
                              "Qari: ${player.subtitle}",
                              style: const TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Pause / Play
                      IconButton(
                        icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: () => ref.read(playerServiceProvider.notifier).togglePausePlay(),
                      ),
                      // Tombol Stop
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white),
                        onPressed: () => ref.read(playerServiceProvider.notifier).stop(),
                      ),
                    ],
                  ),
                ),  

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Tambah Qari / Syaikh Lain (Online)'),
                  onPressed: downloader.isDownloading ? null : () => ref.read(downloadServiceProvider.notifier).toggleDownloaderMode(true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}