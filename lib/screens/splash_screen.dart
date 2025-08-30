// lib/screens/splash_screen.dart
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

  @override
  void initState() {
    super.initState();
    _loadAndNavigate();
  }

  Future<void> _loadAndNavigate() async {
    final quranService = ref.read(quranDataServiceProvider);
    
    // Muat semua data surah (ini akan memakan sedikit waktu)
    await quranService.loadAllSurahData();
    
    // Setelah data dimuat, ambil ayat acak
    setState(() {
      _randomAyah = quranService.getRandomAyah();
    });

    // Tunggu sebentar (opsional, untuk memastikan ayat acak terlihat)
    await Future.delayed(const Duration(seconds: 3));

    // Navigasi ke HomeScreen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor, // Warna primary theme Anda
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Aplikasi (opsional, dari assets/images/splash_logo.png)
              Image.asset('assets/images/splash_logo.png', height: 120),
              const SizedBox(height: 30),

              _randomAyah == null
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      children: [
                        Text(
                          _randomAyah!.ayaText,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'LPMQ', // Font Arab
                            fontSize: 28,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _randomAyah!.translationAyaText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins', // Font Latin
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "QS. ${_randomAyah!.surah!.englishName} (${_randomAyah!.suraId}) : ${_randomAyah!.ayaNumber}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 40),
              const Text(
                'Membuka Cahaya Al-Quran',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const CircularProgressIndicator(color: Colors.white), // Indikator loading
            ],
          ),
        ),
      ),
    );
  }
}