import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PermissionGateScreen extends StatefulWidget {
  final Widget next;
  const PermissionGateScreen({super.key, required this.next});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('initial_permissions_done') ?? false;
      if (done) {
        if (!mounted) return;
        _goNext();
        return;
      }

      await notificationService.requestPermissions();

      if (!kIsWeb) {
        // Location permission (used for prayer time).
        await Geolocator.requestPermission();

        // Microphone & speech recognition permission (used for hafalan/search).
        final speech = stt.SpeechToText();
        await speech.initialize();

        // Android 12+ exact alarms permission is requested in NotificationService.init(),
        // and may open a system dialog/settings screen.
        if (Platform.isAndroid) {
          // no-op: keep for future platform-specific permissions.
        }
      }

      await prefs.setBool('initial_permissions_done', true);
      if (!mounted) return;
      _goNext();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _goNext() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Meminta izin perangkat…',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Lokasi, mikrofon, dan notifikasi diperlukan agar fitur berjalan normal.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Izin Diperlukan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aplikasi membutuhkan beberapa izin agar fitur berjalan normal:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            const _PermItem(
              icon: Icons.location_on_outlined,
              title: 'Lokasi',
              subtitle: 'Untuk jadwal sholat sesuai posisi.',
            ),
            const _PermItem(
              icon: Icons.mic_none_outlined,
              title: 'Mikrofon & Pengenalan Suara',
              subtitle: 'Untuk fitur hafalan/pencarian suara.',
            ),
            const _PermItem(
              icon: Icons.notifications_none_outlined,
              title: 'Notifikasi',
              subtitle: 'Untuk pengingat adzan & istima.',
            ),
            const Spacer(),
            if (_error != null)
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _run();
              },
              child: const Text('Minta Izin Sekarang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PermItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

