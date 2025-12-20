import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/screens/home_screen.dart';
import 'package:quran_app/services/quran_data_service.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}
class HybridLottieLogo extends StatelessWidget {
  final double size;

  const HybridLottieLogo({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final glowColor = theme.brightness == Brightness.dark
        ? AppTheme.tajweedColors['jalalah']!.withOpacity(0.6)
        : theme.colorScheme.primary;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// Glow animation
          Lottie.asset(
            'assets/lottie/glow_pulse_theme.json',
            width: size,
            height: size,
            repeat: true,
            delegates: LottieDelegates(
              values: [
                ValueDelegate.color(
                  const ['Glow', 'Glow Fill', 'Color'],
                  value: glowColor,
                ),
              ],
            ),
          ),

          /// Robot + Mushaf PNG
          Image.asset(
            'assets/mascot.png',
            width: size * 0.72,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Ayah? _randomAyah;
  List<double> lottieColor(Color c) =>
    [c.red / 255, c.green / 255, c.blue / 255, c.opacity];
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

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      await NotificationService().init();
      tz.initializeTimeZones();
    }
    await _requestAllPermissions();
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
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
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: 
          Column(
            children: [
              HybridLottieLogo(
                size: 220,
              ),
              const SizedBox(height: 16),
              Text(
                'Mushaf',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 24),
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

