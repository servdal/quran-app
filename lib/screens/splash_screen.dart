import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/screens/home_screen.dart';
import 'package:quran_app/services/quran_data_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Ayah? _randomAyah;
  final String _loadingMessage = 'Mempersiapkan aplikasi...'; // Pesan loading sederhana

  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    final quranService = ref.read(quranDataServiceProvider);

    // PANGGIL FUNGSI BARU YANG CEPAT
    final ayah = await quranService.loadRandomAyahForSplash();
    
    if (mounted) {
      setState(() {
        _randomAyah = ayah;
      });
    }

    // Tunggu sebentar agar pengguna bisa melihat splash screen
    await Future.delayed(const Duration(seconds: 5));

    // Navigasi ke HomeScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  // ... (sisa kode build() dan _buildFeatureItem() tetap sama) ...
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              // Bagian Atas: Logo Aplikasi dan Judul
              Image.asset('assets/images/main_logo.png', height: screenSize.height * 0.15),
              const SizedBox(height: 16),
              Text(
                'Al-Quran Digital',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: 32,
                      color: Theme.of(context).primaryColor,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 0),
                          blurRadius: 15.0,
                          color: Theme.of(context).primaryColor.withOpacity(0.7),
                        ),
                      ],
                    ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/splash_logo.png', height: screenSize.height * 0.18),
                    const SizedBox(height: 30),
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),
                    _buildFeatureItem(context, 'Baca Al-Quran per Surah & Halaman'),
                    _buildFeatureItem(context, 'Terjemahan & Tafsir Jalalayn'),
                    _buildFeatureItem(context, 'Penanda Ayat Sajdah'),
                  ],
                ),
              ),
              if (_randomAyah != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _randomAyah!.ayaText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'LPMQ',
                          fontSize: 24,
                          color: Colors.white,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _randomAyah!.translationAyaText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}
