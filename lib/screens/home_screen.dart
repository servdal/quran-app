// home_screen.dart (REVISI FINAL)

import 'dart:async';
import 'dart:convert';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/screens/page_view_screen.dart';
import 'package:quran_app/screens/surah_detail_screen.dart';
import 'package:quran_app/screens/surah_list_screen.dart';
import 'package:quran_app/screens/search_result_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'package:quran_app/screens/page_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


// Fungsi helper untuk memproses data jadwal sholat, agar bisa digunakan kembali
Map<String, dynamic> _processPrayerData(String jsonData) {
  final data = jsonDecode(jsonData);

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
      DateTime prayerTime = DateFormat("HH:mm").parse(timeString);
      prayerTime = DateTime(now.year, now.month, now.day, prayerTime.hour, prayerTime.minute);

      if (prayerTime.isAfter(now)) {
        nextPrayerName = prayer;
        nextPrayerTime = prayerTime;
        break;
      }
    }
  }

  if (nextPrayerName == null) {
    nextPrayerName = 'Fajr';
    final timeString = timings['Fajr'];
    DateTime fajrTime = DateFormat("HH:mm").parse(timeString);
    nextPrayerTime = DateTime(now.year, now.month, now.day + 1, fajrTime.hour, fajrTime.minute);
  }

  final closestDiff = nextPrayerTime?.difference(now);

  return {
    "date": data["data"]["date"]["readable"],
    "method": data["data"]["meta"]["method"]["name"],
    "timings": timings,
    "closestPrayer": nextPrayerName,
    "closestTime": nextPrayerTime,
    "closestDiff": closestDiff, // Mengembalikan Duration, bukan menit
    "location": data["data"]["meta"]["timezone"],
    "isOffline": false, // Menandakan data ini dari online
  };
}


final prayerProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    throw Exception("Layanan lokasi (GPS) tidak aktif. Harap aktifkan untuk melihat jadwal sholat.");
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception("Izin lokasi ditolak oleh pengguna.");
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception("Izin lokasi ditolak secara permanen. Harap aktifkan dari pengaturan sistem.");
  }

  try {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final lat = position.latitude;
    final lng = position.longitude;
    final response = await http.get(Uri.parse("http://api.aladhan.com/v1/timings?latitude=$lat&longitude=$lng"));

    if (response.statusCode == 200) {
      // Jika berhasil, simpan data ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_prayer_data', response.body);
      return _processPrayerData(response.body);
    } else {
      throw Exception("Gagal terhubung ke server waktu sholat.");
    }
  } on SocketException {
    // === PERUBAHAN: Logika Fallback ke data offline ===
    final prefs = await SharedPreferences.getInstance();
    final offlineData = prefs.getString('last_prayer_data');
    if (offlineData != null) {
      final processedData = _processPrayerData(offlineData);
      processedData['isOffline'] = true; // Tandai bahwa data ini offline
      return processedData;
    } else {
      // Jika tidak ada koneksi dan tidak ada data offline, baru lempar error
      throw Exception("Tidak ada koneksi internet dan tidak ada data tersimpan.");
    }
  }
});


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _debounce;
  Timer? _countdownTimer;
  Duration? _timeUntilPrayer;

  @override
  void dispose() {
    _debounce?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  void _startCountdown(DateTime prayerTime) {
    _countdownTimer?.cancel(); // Batalkan timer lama jika ada
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = prayerTime.difference(now);

      if (diff.isNegative) {
        timer.cancel();
        // Reload provider untuk mendapatkan jadwal sholat berikutnya
        ref.invalidate(prayerProvider);
      } else {
        if (mounted) {
          setState(() {
            _timeUntilPrayer = diff;
          });
        }
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitHours = twoDigits(duration.inHours);
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
  }


  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().length > 2) {
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
    final theme = Theme.of(context);

    // Dengar perubahan provider untuk memulai countdown
    ref.listen<AsyncValue<Map<String, dynamic>>>(prayerProvider, (_, next) {
      next.whenData((prayerData) {
        final DateTime? closestTime = prayerData['closestTime'];
        if (closestTime != null) {
          _startCountdown(closestTime);
        }
      });
    });

    final prayerAsync = ref.watch(prayerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("Tafsir Jalalayn Audio KH. Bahauddin Nursalim"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Tafsir Jalalayn Audio',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.mosque_rounded, size: 48),
                applicationLegalese: '© 2025 Duidev Software House',
                children: <Widget>[
                  const SizedBox(height: 24),
                  const Text(
                    'Aplikasi ini menyediakan tafsir audio Al-Quran (Jalalayn) oleh KH. Bahauddin Nursalim (Gus Baha) beserta teks Al-Quran dan terjemahannya.',
                    textAlign: TextAlign.justify,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, theme),
                const SizedBox(height: 24),
                _buildSearchBar(context, theme),
                const SizedBox(height: 16),
                
                prayerAsync.when(
                  data: (prayer) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Jadwal Sholat (${prayer["date"]})",
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                if (prayer['isOffline'] == true)
                                  const Tooltip(
                                    message: 'Data offline',
                                    child: Icon(Icons.cloud_off, size: 18, color: Colors.grey),
                                  ),
                              ],
                            ),
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
                            if (prayer["closestPrayer"] != null && _timeUntilPrayer != null)
                              Center(
                                child: Text(
                                  "Waktu ${prayer["closestPrayer"]} dalam: ${_formatDuration(_timeUntilPrayer!)}",
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
                const SizedBox(height: 32),
                _buildDeveloperInfo(context),
              ],
            ),
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
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AppTheme.tajweedRules.length,
            itemBuilder: (context, index) {
              final rule = AppTheme.tajweedRules[index];
              return ExpansionTile(
                leading: CircleAvatar(backgroundColor: rule.color, radius: 12),
                title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: <Widget>[
                  Text(
                    rule.description,
                    textAlign: TextAlign.justify,
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
  Widget _buildDeveloperInfo(BuildContext context) {
    final Uri githubUrl = Uri.parse('https://github.com/servdal/quran-app');

    Future<void> _launchUrl() async {
      if (!await launchUrl(githubUrl, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak dapat membuka link: $githubUrl')),
          );
        }
      }
    }

    return Column(
      children: [
        Text(
          'Dikembangkan dengan ❤️ oleh Duidev Software House',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _launchUrl,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Text(
              'Bantu kembangkan di https://github.com/servdal/quran-app',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                decoration: TextDecoration.underline,
                decorationColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

