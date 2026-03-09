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
  final List<({String code, String label})> _otherLanguageOptions = const [
    (code: 'af', label: 'Afrikaans'),
    (code: 'sq', label: 'Albanian'),
    (code: 'am', label: 'Amharic'),
    (code: 'ar', label: 'Arabic'),
    (code: 'hy', label: 'Armenian'),
    (code: 'az', label: 'Azerbaijani'),
    (code: 'eu', label: 'Basque'),
    (code: 'be', label: 'Belarusian'),
    (code: 'bn', label: 'Bengali'),
    (code: 'bs', label: 'Bosnian'),
    (code: 'bg', label: 'Bulgarian'),
    (code: 'ca', label: 'Catalan'),
    (code: 'ceb', label: 'Cebuano'),
    (code: 'zh-CN', label: 'Chinese (Simplified)'),
    (code: 'zh-TW', label: 'Chinese (Traditional)'),
    (code: 'hr', label: 'Croatian'),
    (code: 'cs', label: 'Czech'),
    (code: 'da', label: 'Danish'),
    (code: 'nl', label: 'Dutch'),
    (code: 'eo', label: 'Esperanto'),
    (code: 'et', label: 'Estonian'),
    (code: 'fi', label: 'Finnish'),
    (code: 'fr', label: 'French'),
    (code: 'gl', label: 'Galician'),
    (code: 'ka', label: 'Georgian'),
    (code: 'de', label: 'German'),
    (code: 'el', label: 'Greek'),
    (code: 'gu', label: 'Gujarati'),
    (code: 'ht', label: 'Haitian Creole'),
    (code: 'ha', label: 'Hausa'),
    (code: 'he', label: 'Hebrew'),
    (code: 'hi', label: 'Hindi'),
    (code: 'hu', label: 'Hungarian'),
    (code: 'is', label: 'Icelandic'),
    (code: 'ig', label: 'Igbo'),
    (code: 'ga', label: 'Irish'),
    (code: 'it', label: 'Italian'),
    (code: 'ja', label: 'Japanese'),
    (code: 'jv', label: 'Javanese'),
    (code: 'kn', label: 'Kannada'),
    (code: 'kk', label: 'Kazakh'),
    (code: 'km', label: 'Khmer'),
    (code: 'ko', label: 'Korean'),
    (code: 'ku', label: 'Kurdish'),
    (code: 'ky', label: 'Kyrgyz'),
    (code: 'lo', label: 'Lao'),
    (code: 'la', label: 'Latin'),
    (code: 'lv', label: 'Latvian'),
    (code: 'lt', label: 'Lithuanian'),
    (code: 'mk', label: 'Macedonian'),
    (code: 'ms', label: 'Malay'),
    (code: 'ml', label: 'Malayalam'),
    (code: 'mt', label: 'Maltese'),
    (code: 'mr', label: 'Marathi'),
    (code: 'mn', label: 'Mongolian'),
    (code: 'my', label: 'Myanmar (Burmese)'),
    (code: 'ne', label: 'Nepali'),
    (code: 'no', label: 'Norwegian'),
    (code: 'fa', label: 'Persian'),
    (code: 'pl', label: 'Polish'),
    (code: 'pt', label: 'Portuguese'),
    (code: 'pa', label: 'Punjabi'),
    (code: 'ro', label: 'Romanian'),
    (code: 'ru', label: 'Russian'),
    (code: 'sr', label: 'Serbian'),
    (code: 'si', label: 'Sinhala'),
    (code: 'sk', label: 'Slovak'),
    (code: 'sl', label: 'Slovenian'),
    (code: 'so', label: 'Somali'),
    (code: 'es', label: 'Spanish'),
    (code: 'sw', label: 'Swahili'),
    (code: 'sv', label: 'Swedish'),
    (code: 'tl', label: 'Tagalog'),
    (code: 'ta', label: 'Tamil'),
    (code: 'te', label: 'Telugu'),
    (code: 'th', label: 'Thai'),
    (code: 'tr', label: 'Turkish'),
    (code: 'uk', label: 'Ukrainian'),
    (code: 'ur', label: 'Urdu'),
    (code: 'uz', label: 'Uzbek'),
    (code: 'vi', label: 'Vietnamese'),
    (code: 'cy', label: 'Welsh'),
    (code: 'xh', label: 'Xhosa'),
    (code: 'yi', label: 'Yiddish'),
    (code: 'yo', label: 'Yoruba'),
    (code: 'zu', label: 'Zulu'),
  ];

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
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _primaryLanguageButton(
                            label: 'Indonesia',
                            code: 'id',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _primaryLanguageButton(
                            label: 'English',
                            code: 'en',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value:
                          (_language != 'id' && _language != 'en')
                              ? _language
                              : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Bahasa Lain (API)',
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Pilih bahasa selain Indonesia/English'),
                      items:
                          _otherLanguageOptions
                              .map(
                                (option) => DropdownMenuItem<String>(
                                  value: option.code,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _language = value);
                      },
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
                      onChanged: (v) => setState(() => _arabicSource = v),
                    ),
                    _radio(
                      title: "KEMENAG RI",
                      subtitle: "Standar Mushaf Indonesia",
                      value: ArabicSource.kemenag,
                      group: _arabicSource,
                      onChanged: (v) => setState(() => _arabicSource = v),
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

  Widget _sectionCard({required String title, required Widget child}) {
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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

  Widget _primaryLanguageButton({required String label, required String code}) {
    final selected = _language == code;

    return ElevatedButton(
      onPressed: () => setState(() => _language = code),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: selected ? Theme.of(context).primaryColor : null,
        foregroundColor: selected ? Colors.white : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) ...[
            const Icon(Icons.check_circle, size: 18),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
