import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/settings_provider.dart'; // Pastikan import ini ada
import 'home_screen.dart';

// 1. Ubah menjadi ConsumerWidget
class LanguageSelectorScreen extends ConsumerWidget {
  const LanguageSelectorScreen({super.key});

  Future<void> _setLanguage(BuildContext context, WidgetRef ref, String lang) async {
    // 2. Panggil fungsi di provider untuk update State & SharedPreferences sekaligus
    // (Asumsi provider Anda memiliki method setLanguage, lihat poin 2 di bawah)
    await ref.read(settingsProvider.notifier).setLanguage(lang);

    // 3. Navigasi balik (gunakan pushReplacement atau pop)
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) { // Tambahkan parameter ref
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pilih Bahasa",
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Kirim ref ke fungsi
              _buildLangButton(context, ref, "Bahasa Indonesia", "id"),
              const SizedBox(height: 16),

              _buildLangButton(context, ref, "English", "en"),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangButton(BuildContext context, WidgetRef ref, String label, String code) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _setLanguage(context, ref, code),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}