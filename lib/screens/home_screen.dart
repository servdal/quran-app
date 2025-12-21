import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/screens/deresan_view_screen.dart';
import 'package:quran_app/screens/language_selector_screen.dart';
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
import 'package:quran_app/screens/dzikir_screen.dart';
import 'package:quran_app/screens/doa_screen.dart';
import 'package:quran_app/screens/aqidah_screen.dart';
import 'package:quran_app/screens/tafsir_surah_list_screen.dart';
import 'package:quran_app/screens/qibla_screen.dart';

// --- PROVIDER & LOGIC ---
final prayerProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final response = await http.get(Uri.parse("http://api.aladhan.com/v1/timings?latitude=${position.latitude}&longitude=${position.longitude}"));

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_prayer_data', response.body);
      final data = _processPrayerData(response.body);
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          String? city = p.locality;
          String? subAdmin = p.subAdministrativeArea;
          String? admin = p.administrativeArea;
          String shortAddress = [
            city,
            if (city == null || city.isEmpty) subAdmin,
            admin,
          ].where((e) => e != null && e.isNotEmpty).map((e) => e!).toList().join(', ');

          if (shortAddress.isEmpty) {
            shortAddress = "Koordinat (${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)})";
          }

          data["location"] = shortAddress;
        }
      } catch (_) {}
      return data;
    } else { throw Exception("Gagal muat"); }
  } catch (e) {
    final prefs = await SharedPreferences.getInstance();
    final offlineData = prefs.getString('last_prayer_data');
    if (offlineData != null) return _processPrayerData(offlineData);
    rethrow;
  }
});

Map<String, dynamic> _processPrayerData(String jsonData) {
  final data = jsonDecode(jsonData);
  final timings = data["data"]["timings"];
  final prayerOrder = ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  final now = DateTime.now();

  String? nextName; DateTime? nextTime; DateTime? prevTime;
  final hijriData = data["data"]["date"]["hijri"];
  final hijriDateString = "${hijriData['day']} ${hijriData['month']['en']} ${hijriData['year']}";
  for (int i = 0; i < prayerOrder.length; i++) {
    DateTime pTime = DateFormat("HH:mm").parse(timings[prayerOrder[i]]);
    pTime = DateTime(now.year, now.month, now.day, pTime.hour, pTime.minute);
    if (pTime.isAfter(now)) {
      nextName = prayerOrder[i]; nextTime = pTime;
      prevTime = (i > 0) ? DateTime(now.year, now.month, now.day, DateFormat("HH:mm").parse(timings[prayerOrder[i-1]]).hour, DateFormat("HH:mm").parse(timings[prayerOrder[i-1]]).minute) : now.subtract(const Duration(hours: 4));
      break;
    }
  }

  if (nextName == null) {
    nextName = 'Fajr';
    DateTime fajr = DateFormat("HH:mm").parse(timings['Fajr']);
    nextTime = DateTime(now.year, now.month, now.day + 1, fajr.hour, fajr.minute);
    DateTime isha = DateFormat("HH:mm").parse(timings['Isha']);
    prevTime = DateTime(now.year, now.month, now.day, isha.hour, isha.minute);
  }

  return {
    "location": data["data"]["meta"]["timezone"],
    "hijriDate": hijriDateString,
    "timings": timings,
    "closestPrayer": nextName,
    "closestTime": nextTime,
    "prevTime": prevTime,
  };
}

// --- MAIN SCREEN ---
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _countdownTimer;
  Duration? _timeUntilPrayer;
  double _progress = 0.0;

  void _startCountdown(DateTime target, DateTime prev) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      final diff = target.difference(now);
      if (diff.isNegative) {
        timer.cancel();
        ref.invalidate(prayerProvider);
      } else {
        final totalRange = target.difference(prev).inSeconds;
        setState(() {
          _timeUntilPrayer = diff;
          _progress = (diff.inSeconds / totalRange).clamp(0.0, 1.0);
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isId = ref.watch(settingsProvider).language == 'id';
    final prayerAsync = ref.watch(prayerProvider);
    final bookmarks = ref.watch(bookmarkProvider);
    ref.listen<AsyncValue<Map<String, dynamic>>>(prayerProvider, (_, next) {
      next.whenData((data) => _startCountdown(data['closestTime'], data['prevTime']));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mushaf", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.explore_outlined), onPressed: () {
            if (kIsWeb) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kompas tidak tersedia di Web")));
            } else {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblaScreen()));
            }
          })
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: isId ? 'Cari Surah...' : 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                onSubmitted: (v) => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchResultScreen(query: v))),
              ),
              const SizedBox(height: 20),

              // Prayer Card
              prayerAsync.when(
                data: (prayer) => _buildPrayerCard(prayer, theme, isId),
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                error: (err, _) => Center(child: Text("Gagal memuat jadwal")),
              ),

              const SizedBox(height: 25),
              Text(isId ? "Lanjutkan:" : "Bookmark", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (bookmarks.isEmpty)
                _buildEmptyBookmark(isId)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    String name = bookmarks.keys.elementAt(index);
                    Bookmark bookmark = bookmarks.values.elementAt(index);

                    return _buildBookmarkCard(
                      context, 
                      ref, 
                      theme, 
                      name, 
                      bookmark, 
                      isId
                    );
                  },
                ),
              const SizedBox(height: 15),
              Text(isId ? "Menu Utama" : "Main Menu", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              
              _buildMenuGrid(context, isId, ThemeData()),
              
              const SizedBox(height: 40),
              _buildDeveloperInfo(context, isId)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerCard(Map<String, dynamic> prayer, ThemeData theme, bool isId) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)]),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(prayer["location"], style: TextStyle(color: cs.onPrimary, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(prayer["hijriDate"], style: TextStyle(color: cs.onPrimary.withOpacity(0.8), fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.location_on, color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Countdown Circle
              if (_timeUntilPrayer != null) ...[
                _buildTimerCircle(cs, isId, prayer["closestPrayer"]),
                const SizedBox(width: 15),
              ],
              // Times List
              Expanded(
                child: Column(
                  children: (prayer["timings"] as Map).entries
                      .where((e) => ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'].contains(e.key))
                      .map((e) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: TextStyle(color: e.key == prayer["closestPrayer"] ? Colors.yellow : Colors.white, fontSize: 13)),
                          Text(e.value, style: TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      )).toList(),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimerCircle(ColorScheme cs, bool isId, String nextName) {
    final hours = _timeUntilPrayer!.inHours.toString().padLeft(2, '0');
    final mins = (_timeUntilPrayer!.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (_timeUntilPrayer!.inSeconds % 60).toString().padLeft(2, '0');
    
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 100, height: 100,
          child: CircularProgressIndicator(value: _progress, color: Colors.white, backgroundColor: Colors.white12, strokeWidth: 5, strokeCap: StrokeCap.round),
        ),
        Column(
          children: [
            Text("$hours:$mins:$secs", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(isId ? "Ke $nextName" : "To $nextName", style: const TextStyle(color: Colors.white70, fontSize: 8)),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuGrid(BuildContext context, bool isId, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Wrap(
        spacing: 12.0,
        runSpacing: 16.0,
        children: [
          _menuItem(
            context,
            name: isId ? 'Per Surah' : 'By Surah',
            icon: Icons.menu_book_rounded,
            color: colorScheme.primary,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SurahListScreen())),
            theme: theme,
          ),
          _menuItem(
            context,
            name: isId ? 'Per Halaman' : 'By Page',
            icon: Icons.auto_stories_rounded,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PageListScreen())),
            theme: theme,
          ),
          _menuItem(
            context,
            name: "Nahwu",
            icon: Icons.menu_book,
            color: Colors.brown,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TafsirSurahListScreen())),
            theme: theme,
          ),
          _menuItem(
            context,
            name: isId ? "Klasik" : "Classic",
            icon: Icons.history_edu,
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PageListScreen(mode: PageListViewMode.deresan))),
            theme: theme,
          ),
          _menuItem(
            context,
            name: isId ? "Tajwid" : "Tajweed",
            icon: Icons.color_lens_rounded,
            color: Colors.purple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlossaryScreen())),
            theme: theme,
          ),
          _menuItem(
            context,
            name: isId ? "Dzikir Pagi" : "Morning Dhikr",
            icon: Icons.wb_sunny_rounded,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DzikirScreen(type: DzikrType.pagi))),
            theme: theme,
          ),
          _menuItem(
            context,
            name: isId ? "Dzikir Petang" : "Evening Dhikr",
            icon: Icons.nights_stay,
            color: Colors.deepPurple,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DzikirScreen(type: DzikrType.petang))),
            theme: theme,
          ),
          _menuItem(
            context,
            name: isId ? "Doa" : "Dua",
            icon: Icons.volunteer_activism_rounded,
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoaScreen())),
            theme: theme,
          ),
          _menuItem(
            context,
            name: "Aqidah",
            icon: Icons.favorite_rounded,
            color: Colors.redAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AqidahScreen())),
            theme: theme,
          ),
          _menuItem(
            context,
            name: isId ? "Setelan" : "Settings",
            icon: Icons.settings_rounded,
            color: Colors.blueGrey,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageSelectorScreen())),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required String name,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required ThemeData theme,
    bool available = true,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: available ? 1 : 0.3,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.28, // Responsif: lebar sekitar 1/3 layar
          height: 120,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            // Warna background adaptif: Abu-abu sangat terang (light) atau Abu-abu gelap (dark)
            color: isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.2) : const Color(0xFFF4F4F4),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 2),
                blurRadius: 6,
                color: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Indikator Status (seperti di referensi SMART ROOM)
              Align(
                alignment: Alignment.topRight,
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: color, // Menggunakan warna kategori sebagai status
                ),
              ),
              const Spacer(),
              // Icon Tengah
              Icon(
                icon,
                size: 32,
                color: isDark ? theme.colorScheme.onSurface : color,
              ),
              const Spacer(),
              // Label Teks
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurface : Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, WidgetRef ref, ThemeData theme,
    String name, Bookmark bookmark, bool isId) {
    final primaryColor = theme.primaryColor;
    final isDarkMode = theme.brightness == Brightness.dark;
  String getSubtitle() {
      if (bookmark.type == BookmarkViewType.deresan || bookmark.type == BookmarkViewType.page) {
        return isId 
            ? 'Halaman ${bookmark.pageNumber} | ${bookmark.surahName}'
            : 'Page ${bookmark.pageNumber} | ${bookmark.surahName}';
      }
      return isId
          ? 'Ayat ${bookmark.ayahNumber} | ${bookmark.surahName}'
          : 'Ayah ${bookmark.ayahNumber} | ${bookmark.surahName}';
    }
    String getTypeName() {
      switch (bookmark.type) {
        case BookmarkViewType.deresan: return 'Deresan';
        case BookmarkViewType.tafsir: return 'Tafsir';
        case BookmarkViewType.page: return isId ? 'Halaman' : 'Page';
        default: return 'Surah';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isDarkMode 
            ? [theme.colorScheme.surface, theme.colorScheme.surface.withOpacity(0.8)]
            : [primaryColor.withOpacity(0.9), primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 28),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.white,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                getTypeName(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            getSubtitle(),
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white70),
          onPressed: () => _confirmDelete(context, ref, name, isId),
        ),
        onTap: () {
          _handleNavigation(context, bookmark);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String name, bool isId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 10),
            Text(isId ? 'Hapus Bookmark?' : 'Delete Bookmark?'),
          ],
        ),
        content: Text(
          isId
              ? 'Apakah Anda yakin ingin menghapus "$name" dari daftar simpanan?'
              : 'Are you sure you want to remove "$name" from your bookmarks?',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              isId ? 'Batal' : 'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              ref.read(bookmarkProvider.notifier).removeBookmark(name);
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isId 
                      ? 'Bookmark "$name" telah dihapus' 
                      : 'Bookmark "$name" deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: Colors.grey.shade800,
                ),
              );
            },
            child: Text(isId ? 'Hapus' : 'Delete'),
          ),
        ],
      ),
    );
  }
  void _handleNavigation(BuildContext context, Bookmark bookmark) {
    switch (bookmark.type) {
      case BookmarkViewType.deresan:
        if (bookmark.pageNumber != null) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DeresanViewScreen(initialPage: bookmark.pageNumber!),
          ));
        }
        break;
      case BookmarkViewType.surah:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => SurahDetailScreen(
            surahId: bookmark.surahId,
            initialScrollIndex: bookmark.ayahNumber != null ? bookmark.ayahNumber! - 1 : null,
          ),
        ));
        break;
      case BookmarkViewType.page:
        if (bookmark.pageNumber != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => PageViewScreen(initialPage: bookmark.pageNumber!)));
        }
        break;
      case BookmarkViewType.tafsir:
        Navigator.push(context, MaterialPageRoute(builder: (_) => TafsirViewScreen(surahId: bookmark.surahId)));
        break;
    }
  }
  Widget _buildDeveloperInfo(BuildContext context, bool isId) {
    return Column(
      children: [
        const Text('Developed with ❤️ by Duidev Software House', style: TextStyle(fontSize: 10)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => launchUrl(Uri.parse('https://github.com/servdal/quran-app')),
          child: const Text('Contribute at GitHub', style: TextStyle(fontSize: 10, decoration: TextDecoration.underline, color: Colors.blue)),
        ),
      ],
    );
  }
  Widget _buildEmptyBookmark(bool isId) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.bookmark_border, size: 50, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 8),
          Text(
            isId ? 'Belum ada bookmark' : 'No bookmarks yet',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    ),
  );
}
}


class GlossaryScreen extends ConsumerWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Baca bahasa dari provider
    final lang = ref.watch(settingsProvider).language;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == 'en' ? "Tajweed Glossary" : "Glosarium Tajwid"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: AppTheme.tajweedRules.length,
        itemBuilder: (context, index) {
          final rule = AppTheme.tajweedRules[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ExpansionTile(
                // Menghilangkan garis default ExpansionTile
                shape: const Border(),
                collapsedShape: const Border(),
                // Indikator Warna di samping (Vertical Line)
                leading: Container(
                  width: 6,
                  height: 30,
                  decoration: BoxDecoration(
                    color: rule.color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                title: Text(
                  rule.getName(lang), // BILINGUAL NAME
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  lang == 'en' ? "Tap to see details" : "Ketuk untuk detail",
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          rule.getDescription(lang), // BILINGUAL DESCRIPTION
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Badge kecil untuk menunjukkan Key (opsional)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Chip(
                            label: Text(
                              "Code: ${rule.key.toUpperCase()}",
                              style: const TextStyle(fontSize: 10, color: Colors.white),
                            ),
                            backgroundColor: rule.color.withOpacity(0.8),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}