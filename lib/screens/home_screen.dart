import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/screens/page_view_screen.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/screens/surah_list_screen.dart';
import 'package:quran_app/screens/search_result_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'package:quran_app/screens/page_list_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}
final prayerProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // 1. Cek status izin lokasi
  LocationPermission permission = await Geolocator.checkPermission();
  
  // 2. Jika izin ditolak, minta izin
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Pengguna secara eksplisit menolak izin
      throw Exception("Izin lokasi ditolak oleh pengguna.");
    }
  }
  
  // 3. Jika izin ditolak permanen, beri pesan yang jelas
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
        "Izin lokasi ditolak secara permanen. Harap aktifkan dari pengaturan sistem.");
  } 

  // 4. Jika izin diberikan, lanjutkan untuk mendapatkan lokasi
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);

  final lat = position.latitude;
  final lng = position.longitude;
  final response = await http.get(Uri.parse(
      "http://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lng"));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data['data'] == null || data['data']['timings'] == null) {
      throw Exception("Struktur data API tidak valid.");
    }

    final timings = data["data"]["timings"];
    
    final prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final now = DateTime.now();
    String? nextPrayerName;
    DateTime? nextPrayerTime;

    for (String prayer in prayerOrder) {
      if (timings.containsKey(prayer)) {
        final timeString = timings[prayer];
        // Parse waktu sebagai waktu lokal, bukan UTC
        DateTime prayerTime = DateFormat("HH:mm").parse(timeString);
        prayerTime = DateTime(now.year, now.month, now.day, prayerTime.hour, prayerTime.minute);

        if (prayerTime.isAfter(now)) {
          nextPrayerName = prayer;
          nextPrayerTime = prayerTime;
          break; // Keluar dari loop setelah menemukan waktu sholat berikutnya
        }
      }
    }

    // Jika tidak ada waktu sholat berikutnya hari ini (misal, setelah isya),
    // maka waktu sholat berikutnya adalah subuh keesokan harinya.
    if (nextPrayerName == null) {
      nextPrayerName = 'Fajr';
      final timeString = timings['Fajr'];
      DateTime fajrTime = DateFormat("HH:mm").parse(timeString);
      // Atur ke hari berikutnya
      nextPrayerTime = DateTime(now.year, now.month, now.day + 1, fajrTime.hour, fajrTime.minute);
    }
    
    final closestDiff = nextPrayerTime?.difference(now);

    return {
      "date": data["data"]["date"]["readable"],
      "method": data["data"]["meta"]["method"]["name"],
      "timings": timings,
      "closestPrayer": nextPrayerName,
      "closestTime": nextPrayerTime,
      "closestDiff": closestDiff?.inMinutes,
      "location": data["data"]["meta"]["timezone"],
    };
  } else {
    throw Exception("Gagal terhubung ke server waktu sholat.");
  }
});
class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  // Fungsi untuk menangani pencarian dengan jeda (debouncing)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      // Aksi ini akan dijalankan 500ms setelah pengguna berhenti mengetik
      if (query.trim().length > 2) {
        // Menggunakan context dari widget
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultScreen(query: query.trim()),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkAsync = ref.watch(bookmarkProvider);
    final theme = Theme.of(context); // Mengambil data tema saat ini

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown, // mengecilkan teks kalau terlalu panjang
          child: Text("Tafsir Jalalayn Audio KH. Bahauddin Nursalim"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Tafsir Jalalayn Audio KH. Bahauddin Nursalim',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.mosque_rounded, size: 48),
                applicationLegalese: '© 2025 Duidev Software House',
                children: <Widget>[
                  const SizedBox(height: 24),
                  const Text(
                    'Aplikasi ini menyediakan tafsir Al-Quran (Jalalayn) dilengkapi dengan audio dari KH. Bahauddin Nursalim (Gus Baha) beserta teks Al-Quran dan terjemahannya. Dikembangkan dengan ❤️ kami mengajak semua untuk bergabung dalam pengembangan lebih lanjut di GitHub. https://github.com/servdal/quran-app',
                    textAlign: TextAlign.justify,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, theme),
              const SizedBox(height: 24),
              _buildSearchBar(context, theme),
              const SizedBox(height: 16), // Memberi sedikit jarak              
              ref.watch(prayerProvider).when(
                data: (prayer) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Jadwal Sholat (${prayer["date"]})",
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "Lokasi: ${prayer["location"]}",
                            style: theme.textTheme.bodySmall,
                          ),
                          const Divider(height: 16),
                          ...prayer["timings"].entries.where((e) => 
                            !["Midnight", "Firstthird", "Lastthird", "Imsak", "Sunset"].contains(e.key)
                          ).map<Widget>((e) =>
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(e.key, style: theme.textTheme.bodyMedium),
                                    Text(e.value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              )
                          ).toList(),
                          const Divider(height: 24),
                          if (prayer["closestPrayer"] != null && prayer["closestTime"] != null)
                            Center(
                              child: Text(
                                "Waktu ${prayer["closestPrayer"]} sekitar ${prayer["closestDiff"]} menit lagi.",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Gagal memuat jadwal sholat:\n${error.toString().replaceAll("Exception: ", "")}", 
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  )
                ),
              ),
              const SizedBox(height: 24),
              bookmarkAsync.when(
                data: (bookmark) {
                  if (bookmark == null) return const SizedBox.shrink();
                  return _buildBookmarkCard(context, ref, theme, bookmark);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, s) => const SizedBox.shrink(),
              ),

              _buildNavigationCard(context, theme,
                icon: Icons.list_alt_rounded,
                title: 'Lihat per Surah',
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const SurahListScreen()));
                },
              ),
              const SizedBox(height: 12),
              _buildNavigationCard(context, theme,
                icon: Icons.auto_stories_rounded,
                title: 'Lihat per Halaman',
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => const PageListScreen()));
                },
              ),
              const SizedBox(height: 24),
              _buildGlossary(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assalamualaikum Warohmatullahi Wabarokatuh.', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18)),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Cari surah atau terjemahan...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: _onSearchChanged,
    );
  }

  Widget _buildBookmarkCard(BuildContext context, WidgetRef ref, ThemeData theme, Bookmark bookmark) {
    // Warna untuk kartu bookmark disesuaikan agar kontras
    final cardColor = theme.brightness == Brightness.light ? theme.primaryColor : theme.colorScheme.surface;
    final onCardColor = theme.brightness == Brightness.light ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    return Column(
      children: [
        Card(
          color: cardColor,
          child: ListTile(
            leading: Icon(Icons.bookmark, color: onCardColor, size: 30),
            title: Text('Lanjutkan Membaca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onCardColor)),
            subtitle: Text('Ayah ${bookmark.ayahNumber} | ${bookmark.surahName} ', style: TextStyle(color: onCardColor.withOpacity(0.8))),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: onCardColor),
              tooltip: 'Hapus Bookmark',
              onPressed: () async {
                await ref.read(bookmarkProvider.notifier).removeBookmark();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bookmark telah dihapus.')),
                );
              },
            ),
            onTap: () {
              if (bookmark.type == 'surah') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SurahDetailScreen(
                    surahId: bookmark.surahId,
                    initialScrollIndex: bookmark.ayahNumber - 1,
                  ),
                ));
              } else if (bookmark.type == 'page' && bookmark.pageNumber != null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => PageViewScreen(initialPage: bookmark.pageNumber!),
                ));
              }
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNavigationCard(BuildContext context, ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, color: theme.primaryColor, size: 30),
              const SizedBox(width: 16),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.withOpacity(0.7), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlossary(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Glosarium Tajwid',
          style: theme.textTheme.headlineLarge?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias, // Agar konten di dalam card mengikuti corner radius
          margin: EdgeInsets.zero, // Hapus margin default dari Card
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppTheme.tajweedRules.length,
            itemBuilder: (context, index) {
              final rule = AppTheme.tajweedRules[index];
              return ExpansionTile(
                // **Leading:** Ikon lingkaran berwarna
                leading: CircleAvatar(backgroundColor: rule.color, radius: 12),
                
                // **Title:** Nama hukum tajwid yang selalu terlihat
                title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                
                // **Children:** Konten yang muncul saat di-klik (expanded)
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: <Widget>[
                  Text(
                    rule.description,
                    textAlign: TextAlign.justify, // Tambahkan ini agar teks rata kanan-kiri
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
  
}