import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/settings_provider.dart'; // Pastikan import ini ada
import 'home_screen.dart';

class LanguageSelectorScreen extends ConsumerWidget {
  const LanguageSelectorScreen({super.key});

  Future<void> _setLanguage(
    BuildContext context,
    WidgetRef ref,
    String lang,
  ) async {
    await ref.read(settingsProvider.notifier).setLanguage(lang);
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Pengaturan Awal",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              /// 🌍 Language
              _buildLangButton(context, ref, "Bahasa Indonesia", "id"),
              const SizedBox(height: 12),
              _buildLangButton(context, ref, "English", "en"),

              const SizedBox(height: 32),

              /// 🎨 Theme Selector
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Pilih Tema",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildThemeTile(
                ref,
                title: "Light",
                value: AppThemeType.light,
                groupValue: settings.theme,
              ),
              _buildThemeTile(
                ref,
                title: "Dark",
                value: AppThemeType.dark,
                groupValue: settings.theme,
              ),
              _buildThemeTile(
                ref,
                title: "Pink",
                value: AppThemeType.pink,
                groupValue: settings.theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    WidgetRef ref, {
    required String title,
    required AppThemeType value,
    required AppThemeType groupValue,
  }) {
    return RadioListTile<AppThemeType>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (val) {
        if (val != null) {
          ref.read(settingsProvider.notifier).setTheme(val);
        }
      },
    );
  }

  Widget _buildLangButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    String code,
  ) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _setLanguage(context, ref, code),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
