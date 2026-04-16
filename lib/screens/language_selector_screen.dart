import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/providers/settings_provider.dart'; // Pastikan import ini ada
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:quran_app/services/prayer_widget_service.dart';
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
  late bool _adzanSoundEnabled;
  late AdzanSoundMode _adzanSoundMode;
  late String _adzanSoundName;
  late bool _keepScreenAwake;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _language = settings.language;
    _theme = settings.theme;
    _arabicSource = settings.arabicSource;
    _adzanSoundEnabled = settings.adzanSoundEnabled;
    _adzanSoundMode = settings.adzanSoundMode;
    _adzanSoundName = settings.adzanSoundName;
    _keepScreenAwake = settings.keepScreenAwake;
  }

  Future<void> _applySettings() async {
    final notifier = ref.read(settingsProvider.notifier);

    await notifier.setLanguage(_language);
    await notifier.setTheme(_theme);
    await notifier.setArabicSource(_arabicSource);
    await notifier.setAdzanSoundEnabled(_adzanSoundEnabled);
    await notifier.setAdzanSoundMode(_adzanSoundMode);
    await notifier.setAdzanSoundName(_adzanSoundName);
    await notifier.setKeepScreenAwake(_keepScreenAwake);

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(theme),
              const SizedBox(height: 24),

              _sectionCard(
                icon: Icons.translate_rounded,
                title: "Bahasa",
                subtitle: "Pilih bahasa utama aplikasi dan bahasa terjemahan.",
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
                icon: Icons.palette_outlined,
                title: "Tema Tampilan",
                subtitle: "Sesuaikan nuansa visual aplikasi.",
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
                icon: Icons.menu_book_outlined,
                title: "Sumber Teks Arab",
                subtitle:
                    "Pilih sumber mushaf yang paling sesuai dengan preferensi Anda.",
                child: Column(
                  children: [
                    _radio(
                      title: "Quran Cloud Tajweed",
                      subtitle: "Tajwid dari `tajweed_text` dengan parser khusus",
                      value: ArabicSource.quranCloudTajweed,
                      group: _arabicSource,
                      onChanged: (v) => setState(() => _arabicSource = v),
                    ),
                    _radio(
                      title: "KEMENAG RI Tajweed",
                      subtitle: "Teks Kemenag dengan AutoTajweedParser",
                      value: ArabicSource.kemenagTajweed,
                      group: _arabicSource,
                      onChanged: (v) => setState(() => _arabicSource = v),
                    ),
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

              _sectionCard(
                icon: Icons.notifications_active_outlined,
                title: "Suara Adzan",
                subtitle: "Atur perilaku suara saat notifikasi adzan aktif.",
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Aktifkan suara"),
                      subtitle: const Text(
                        "Jika nonaktif, notifikasi adzan tetap muncul tanpa suara.",
                      ),
                      value: _adzanSoundEnabled,
                      onChanged: (v) => setState(() => _adzanSoundEnabled = v),
                    ),
                    const Divider(),
                    RadioListTile<AdzanSoundMode>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Suara bawaan perangkat"),
                      value: AdzanSoundMode.native,
                      groupValue: _adzanSoundMode,
                      onChanged:
                          (v) => setState(
                            () => _adzanSoundMode = v ?? _adzanSoundMode,
                          ),
                    ),
                    RadioListTile<AdzanSoundMode>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Suara adzan"),
                      subtitle: Text(
                        (!kIsWeb && Platform.isAndroid)
                            ? "Tersedia di Android."
                            : "Tidak didukung di perangkat ini (akan memakai suara bawaan).",
                      ),
                      value: AdzanSoundMode.adzan,
                      groupValue: _adzanSoundMode,
                      onChanged:
                          (!kIsWeb && Platform.isAndroid)
                              ? (v) => setState(
                                () => _adzanSoundMode = v ?? _adzanSoundMode,
                              )
                              : null,
                    ),
                    if (!kIsWeb &&
                        Platform.isAndroid &&
                        _adzanSoundMode == AdzanSoundMode.adzan) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _adzanSoundName,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Pilih suara adzan',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            _adzanSoundOptions
                                .map(
                                  (o) => DropdownMenuItem<String>(
                                    value: o.value,
                                    child: Text(o.label),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _adzanSoundName = v);
                        },
                      ),
                    ],
                  ],
                ),
              ),

              if (!kIsWeb && Platform.isMacOS)
                _sectionCard(
                  icon: Icons.desktop_mac_outlined,
                  title: "Layar Tetap Menyala",
                  subtitle:
                      "Cegah layar macOS meredup atau mati saat aplikasi sedang digunakan.",
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Aktifkan penjaga layar"),
                    subtitle: const Text(
                      "Cocok saat membaca mushaf lebih lama tanpa menyentuh trackpad atau keyboard.",
                    ),
                    value: _keepScreenAwake,
                    onChanged:
                        (value) => setState(() => _keepScreenAwake = value),
                  ),
                ),

              if (!kIsWeb)
                _sectionCard(
                  icon: Icons.widgets_outlined,
                  title: "Widget",
                  subtitle:
                      "Tambahkan akses cepat jadwal sholat dari layar utama.",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Tambahkan widget jadwal sholat ke Home Screen (jika didukung perangkat).",
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed:
                            (!kIsWeb && Platform.isAndroid)
                                ? () async {
                                  final ok =
                                      await PrayerWidgetService.requestPinWidget();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        ok
                                            ? "Widget ditambahkan."
                                            : "Perangkat tidak mendukung pin widget otomatis. Tambahkan lewat menu Widget di Home Screen.",
                                      ),
                                    ),
                                  );
                                }
                                : null,
                        icon: const Icon(Icons.widgets_outlined),
                        label: const Text("Add Widget"),
                      ),
                      if (!kIsWeb && !Platform.isAndroid) ...[
                        const SizedBox(height: 8),
                        Text(
                          "Saat ini tombol Add Widget otomatis hanya tersedia di Android.",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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

  Widget _buildHero(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.16),
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.9),
          ],
        ),
        border: Border.all(color: theme.primaryColor.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.tune_rounded,
              color: theme.primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Pengaturan Awal",
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Atur bahasa, tema, sumber mushaf, suara adzan, dan preferensi membaca sebelum mulai menggunakan aplikasi.",
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: theme.primaryColor, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.45,
                            color: theme.textTheme.bodySmall?.color
                                ?.withOpacity(0.82),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Theme(
              data: theme.copyWith(
                listTileTheme: theme.listTileTheme.copyWith(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              child: child,
            ),
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

class _SoundOption {
  final String value;
  final String label;
  const _SoundOption(this.value, this.label);
}

const List<_SoundOption> _adzanSoundOptions = [
  _SoundOption('azan1', 'Azan 1'),
  _SoundOption('azan2', 'Azan 2'),
  _SoundOption('azan3', 'Azan 3'),
  _SoundOption('azan4', 'Azan 4'),
  _SoundOption('azan5', 'Azan 5'),
  _SoundOption('azan6', 'Azan 6'),
  _SoundOption('azan7', 'Azan 7'),
  _SoundOption('azan8', 'Azan 8'),
  _SoundOption('azan9', 'Azan 9'),
  _SoundOption('azan10', 'Azan 10'),
  _SoundOption('azan11', 'Azan 11'),
  _SoundOption('azan12', 'Azan 12'),
  _SoundOption('azan13', 'Azan 13'),
  _SoundOption('azan14', 'Azan 14'),
  _SoundOption('azan15', 'Azan 15'),
  _SoundOption('azan16', 'Azan 16'),
  _SoundOption('azan17', 'Azan 17'),
  _SoundOption('azan18', 'Azan 18'),
  _SoundOption('azan19', 'Azan 19'),
  _SoundOption('azan20', 'Azan 20'),
  _SoundOption('azan21', 'Azan 21'),
];
