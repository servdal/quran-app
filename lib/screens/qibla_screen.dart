// lib/screens/qibla_screen.dart

import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  final _locationStream = FlutterQiblah.qiblahStream;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arah Kiblat'),
      ),
      body: StreamBuilder(
        stream: _locationStream,
        builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ===== BAGIAN YANG DIPERBARUI ADA DI SINI =====
          if (snapshot.hasError) {
            String errorMessage = "Gagal mendapatkan arah kiblat.";
            
            // Check the runtimeType of the error to determine the cause
            if (snapshot.error.runtimeType == LocationServiceDisabledException) {
              errorMessage = "Layanan lokasi (GPS) tidak aktif. Harap aktifkan.";
            } else {
              // For other errors, like permission denied, we show a general message.
              // The geolocator package handles the permission request dialog internally.
              errorMessage = "Pastikan izin lokasi telah diberikan untuk aplikasi ini.";
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.location_off, size: 60, color: Colors.grey),
                     const SizedBox(height: 16),
                     Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
          // ===============================================
          
          final qiblahDirection = snapshot.data;

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  "Arah Kiblat",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  "${qiblahDirection!.direction.toStringAsFixed(2)}°",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Transform.rotate(
                        angle: (qiblahDirection.qiblah * (pi / 180) * -1),
                        child: SvgPicture.asset(
                          'assets/qibla_compass.svg',
                           height: 300,
                        ),
                      ),
                       Transform.rotate(
                        angle: (qiblahDirection.offset * (pi / 180) * -1),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/qibla_needle.svg',
                          height: 250,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).primaryColor, 
                            BlendMode.srcIn
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                 Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 24.0),
                   child: Text(
                     "Posisikan bagian atas ponsel Anda ke arah jarum untuk menghadap Kiblat.",
                     textAlign: TextAlign.center,
                     style: Theme.of(context).textTheme.bodyLarge,
                   ),
                 ),
              ],
            ),
          );
        },
      ),
    );
  }
}