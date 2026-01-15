import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/settings_provider.dart'; // Pastikan import ini ada
import 'home_screen.dart';

class LanguageSelectorScreen extends ConsumerStatefulWidget {
  const LanguageSelectorScreen({super.key});

  @override
  ConsumerState<LanguageSelectorScreen> createState() =>
      _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState
    extends ConsumerState<LanguageSelectorScreen> {
  late String _language;
  late AppThemeType _theme;
  late ArabicSource _arabicSource;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _language = settings.language;
    _theme = settings.theme;
    _arabicSource = settings.arabicSource;
  }

  Future<void> _applySettings() async {
    final notifier = ref.read(settingsProvider.notifier);

    await notifier.setLanguage(_language);
    await notifier.setTheme(_theme);
    await notifier.setArabicSource(_arabicSource);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pengaturan Awal",
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Atur preferensi aplikasi Anda",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              _sectionCard(
                title: "Bahasa",
                child: Column(
                  children: [
                    _radio(
                      title: "Bahasa Indonesia",
                      value: "id",
                      group: _language,
                      onChanged: (v) => setState(() => _language = v),
                    ),
                    _radio(
                      title: "English",
                      value: "en",
                      group: _language,
                      onChanged: (v) => setState(() => _language = v),
                    ),
                  ],
                ),
              ),

              _sectionCard(
                title: "Tema Tampilan",
                child: Column(
                  children: [
                    _radio(
                      title: "Light",
                      value: AppThemeType.light,
                      group: _theme,
                      onChanged: (v) => setState(() => _theme = v),
                    ),
                    _radio(
                      title: "Dark",
                      value: AppThemeType.dark,
                      group: _theme,
                      onChanged: (v) => setState(() => _theme = v),
                    ),
                    _radio(
                      title: "Pink",
                      value: AppThemeType.pink,
                      group: _theme,
                      onChanged: (v) => setState(() => _theme = v),
                    ),
                  ],
                ),
              ),

              _sectionCard(
                title: "Sumber Teks Arab",
                child: Column(
                  children: [
                    _radio(
                      title: "Quran Cloud",
                      subtitle: "Standar internasional (Uthmani)",
                      value: ArabicSource.quranCloud,
                      group: _arabicSource,
                      onChanged: (v) =>
                          setState(() => _arabicSource = v),
                    ),
                    _radio(
                      title: "KEMENAG RI",
                      subtitle: "Standar Mushaf Indonesia",
                      value: ArabicSource.kemenag,
                      group: _arabicSource,
                      onChanged: (v) =>
                          setState(() => _arabicSource = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _applySettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    "Terapkan Pengaturan",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ---------- Helper Widgets ----------

  Widget _sectionCard({
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _radio<T>({
    required String title,
    String? subtitle,
    required T value,
    required T group,
    required ValueChanged<T> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      groupValue: group,
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
