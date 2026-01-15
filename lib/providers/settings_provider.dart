import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType { light, dark, pink }
enum ArabicSource {
  quranCloud,
  kemenag,
}

class Settings {
  final double arabicFontSize;
  final String language;
  final AppThemeType theme;
  final ArabicSource arabicSource;
  Settings({
    required this.arabicFontSize,
    required this.language,
    required this.theme,
    required this.arabicSource,
  });
  Settings copyWith({
    double? arabicFontSize,
    String? language,
    AppThemeType? theme,
    ArabicSource? arabicSource,
  }) {
    return Settings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      arabicSource: arabicSource ?? this.arabicSource,
    );
  }
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier()
    : super(
        Settings(arabicFontSize: 28, language: 'id', theme: AppThemeType.light, arabicSource: ArabicSource.quranCloud),
      ) {
    _loadSettings();
  }
  void setFontSize(double size) {
    state = state.copyWith(arabicFontSize: size);
  }

  Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', lang);
    state = state.copyWith(language: lang);
  }

  Future<void> setTheme(AppThemeType theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme', theme.index);
    state = state.copyWith(theme: theme);
  }
  Future<void> setArabicSource(ArabicSource source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('arabic_source', source.index);
    state = state.copyWith(arabicSource: source);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('selected_language') ?? 'id';
    final arabicIndex = prefs.getInt('arabic_source') ?? 0;
    state = state.copyWith(language: lang);
    final themeIndex = prefs.getInt('theme') ?? 0;
    state = state.copyWith(
      language: lang,
      theme: AppThemeType.values[themeIndex],
      arabicSource: ArabicSource.values[arabicIndex],
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((
  ref,
) {
  return SettingsNotifier();
});
final arabicFontSizeProvider = Provider<double>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.arabicFontSize;
});
