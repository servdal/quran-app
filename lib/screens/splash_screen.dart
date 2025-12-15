import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;
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
  final String _loadingMessage = 'Mempersiapkan aplikasi...';

  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    final quranService = ref.read(quranDataServiceProvider);
    final ayah = await quranService.loadRandomAyahForSplash();
    
    if (mounted) {
      setState(() {
        _randomAyah = ayah;
      });
    }

    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      await NotificationService().init();
      tz.initializeTimeZones();
    }
    await _requestAllPermissions();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
  Future<void> _requestAllPermissions() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
        await NotificationService().requestPermissions();
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
    } catch (e) {
      throw Exception("Gagal meminta izin lokasi di splash screen: $e");
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              Image.asset('assets/images/mascot.png', height: screenSize.height * 0.15),
              const SizedBox(height: 16),
              
              Text(
                'Al-Quran Digital',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 32,
                  color: theme.primaryColor,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 0),
                      blurRadius: 15.0,
                      color: theme.primaryColor.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: theme.primaryColor,
                      strokeWidth: 4,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                    ),
                  ],
                ),
              ),

              if (_randomAyah != null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: theme.brightness == Brightness.light 
                               ? Colors.black.withOpacity(0.1)
                               : Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _randomAyah!.arabicText,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'LPMQ',
                          fontSize: 24,
                          color: theme.colorScheme.onSurface,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _randomAyah!.translation,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
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
}

