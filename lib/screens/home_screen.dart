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
import 'package:quran_app/screens/tafsir_view_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'package:quran_app/screens/page_list_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/screens/deresan_view_screen.dart';
import 'package:quran_app/screens/dzikir_screen.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:quran_app/screens/doa_screen.dart';
import 'package:quran_app/screens/aqidah_screen.dart';
import 'package:quran_app/screens/download_manager_screen.dart';
import 'package:quran_app/screens/tafsir_surah_list_screen.dart';
import 'package:quran_app/screens/qibla_screen.dart';

Map<String, dynamic> _processPrayerData(String jsonData) {
  final data = jsonDecode(jsonData);

  if (data['data'] == null || data['data']['timings'] == null) {
    throw Exception("Struktur data API tidak valid.");
  }
  final hijriData = data["data"]["date"]["hijri"];
  final hijriDateString = "${hijriData['day']} ${hijriData['month']['en']} ${hijriData['year']}";

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
    "hijriDate": hijriDateString,
    "closestPrayer": nextPrayerName,
    "closestTime": nextPrayerTime,
    "closestDiff": closestDiff,
    "location": data["data"]["meta"]["timezone"],
    "isOffline": false,
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
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('last_prayer_data', response.body);
      return _processPrayerData(response.body);
    } else {
      throw Exception("Gagal terhubung ke server waktu sholat.");
    }
  } on SocketException {
    final prefs = await SharedPreferences.getInstance();
    final offlineData = prefs.getString('last_prayer_data');
    if (offlineData != null) {
      final processedData = _processPrayerData(offlineData);
      processedData['isOffline'] = true;
      return processedData;
    } else {
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
  void initState() {
    super.initState();
  }
  @override
  void dispose() {
    _debounce?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  void _startCountdown(DateTime prayerTime) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final diff = prayerTime.difference(now);

      if (diff.isNegative) {
        timer.cancel();
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

  void _handleQiblaTap() {
    if (kIsWeb || Platform.isWindows || Platform.isMacOS) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Fitur Tidak Tersedia"),
          content: const Text("Petunjuk arah kiblat hanya tersedia di perangkat Android dan iOS."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const QiblaScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    ref.listen<AsyncValue<Map<String, dynamic>>>(prayerProvider, (_, next) {
      next.whenData((prayerData) {
        final DateTime? closestTime = prayerData['closestTime'];
        final String? closestPrayer = prayerData['closestPrayer'];

        if (closestTime != null && closestPrayer != null) {
          _startCountdown(closestTime);
          NotificationService().cancelAllNotifications();
          NotificationService().scheduleAdzanNotification(
            id: 0,
            prayerName: closestPrayer,
            scheduledTime: closestTime,
          );
        }
      });
    });

    final prayerAsync = ref.watch(prayerProvider);
    final bookmarks = ref.watch(bookmarkProvider);
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("Al Quran Digital"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Arah Kiblat',
            onPressed: _handleQiblaTap,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Tafsir Jalalayn dengan Audio Gus Baha',
                applicationVersion: '3.0.4',
                applicationIcon: const Icon(Icons.mosque_rounded, size: 48),
                applicationLegalese: '© 2025 Duidev Software House',
                children: <Widget>[
                  const SizedBox(height: 24),
                  const Text(
                    'Aplikasi ini menyediakan tafsir Al-Quran (Jalalayn) dengan audio oleh KH. Bahauddin Nursalim (Gus Baha) beserta teks Al-Quran dan terjemahannya. Malang, 4 Oktober 2025',
                    textAlign: TextAlign.justify,
                  ),
                  RichText(
                    textAlign: TextAlign.right,
                    text: TextSpan(
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontFamily: 'LPMQ',
                        fontSize: 14,
                      ),
                      text: 'االسبت , ١٢ رَبيع الثاني ١٤٤٧ هـ\n',
                    ),
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
                                Text("Jadwal Sholat (${prayer["hijriDate"]})",
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
                if (bookmarks.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanda Baca Tersimpan',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...bookmarks.entries.map((entry) {
                        return _buildBookmarkCard(
                            context, ref, theme, entry.key, entry.value);
                      }).toList(),
                      const SizedBox(height: 24),
                    ],
                  ),

              
                _buildMenuGrid(context),
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
  Widget _buildBookmarkCard(BuildContext context, WidgetRef ref, ThemeData theme,
      String name, Bookmark bookmark) {
    final cardColor = theme.brightness == Brightness.light
        ? theme.primaryColor
        : theme.colorScheme.surface;
    final onCardColor = theme.brightness == Brightness.light
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: ListTile(
        leading: Icon(Icons.bookmark, color: onCardColor, size: 30),
        title: Text(name,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: onCardColor)),
        subtitle: Text('Ayah ${bookmark.ayahNumber} | ${bookmark.surahName} ',
            style: TextStyle(color: onCardColor.withOpacity(0.8))),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: onCardColor),
          tooltip: 'Hapus Bookmark',
          onPressed: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Hapus Bookmark?'),
                content: Text('Anda yakin ingin menghapus bookmark "$name"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(bookmarkProvider.notifier).removeBookmark(name);
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Bookmark "$name" telah dihapus.')),
                      );
                    },
                    child: const Text('Hapus'),
                  ),
                ],
              ),
            );
          },
        ),
        onTap: () {
          if (bookmark.type == BookmarkViewType.surah.name) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurahDetailScreen(
                    surahId: bookmark.surahId,
                    initialScrollIndex: bookmark.ayahNumber - 1,
                  ),
                ));
          } else if (bookmark.type == BookmarkViewType.page.name &&
              bookmark.pageNumber != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PageViewScreen(initialPage: bookmark.pageNumber!),
                ));
          } else if (bookmark.type == BookmarkViewType.tafsir.name) {
             Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TafsirViewScreen(surahId: bookmark.surahId),
                ));
          } else if (bookmark.type == BookmarkViewType.deresan.name &&
              bookmark.pageNumber != null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DeresanViewScreen(initialPage: bookmark.pageNumber!),
                ));
          }
        },
      ),
    );
  }
  Widget _buildMenuGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, 
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _MenuTile(
          icon: Icons.list_alt_rounded,
          title: 'Lihat per Surah',
          color: Colors.teal.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SurahListScreen()));
          },
        ),
        _MenuTile(
          icon: Icons.auto_stories_rounded,
          title: 'Lihat per Halaman',
          color: Colors.blue.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PageListScreen()));
          },
        ),
        _MenuTile(
          icon: Icons.menu_book,
          title: 'Tafsir dan Terjemah Perkata',
          color: Colors.brown.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const TafsirSurahListScreen()));
          },
        ),
        _MenuTile(
          icon: Icons.menu_book_rounded,
          title: 'AlQuran Klasik',
          color: Colors.indigo.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const PageListScreen(mode: PageListViewMode.deresan)));
          },
        ),
        _MenuTile(
          icon: Icons.color_lens_outlined,
          title: 'Glosarium Tajwid',
          color: Colors.purple.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GlossaryScreen()));
          },
        ),
        _MenuTile(
          icon: Icons.wb_sunny_outlined,
          title: 'Dzikir Pagi',
          color: Colors.orange.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DzikirScreen(type: DzikrType.pagi)));
          },
        ),
        _MenuTile(
          icon: Icons.nights_stay_outlined,
          title: 'Dzikir Petang',
          color: Colors.deepPurple.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DzikirScreen(type: DzikrType.petang)));
          },
        ),
        _MenuTile(
          icon: Icons.volunteer_activism_rounded,
          title: 'Kumpulan Doa',
          color: Colors.green.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DoaScreen()));
          },
        ),
        _MenuTile(
          icon: Icons.favorite,
          title: 'Aqidatul Awam',
          color: Colors.brown.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AqidahScreen()));
          },
        ),
        _MenuTile(
          icon: Icons.cloud_download_outlined,
          title: 'Unduh Audio',
          color: Colors.blueGrey.shade400,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const DownloadManagerScreen()));
          },
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

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: color,
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glosarium Tajwid'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
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
        ),
      ),
    );
  }
}