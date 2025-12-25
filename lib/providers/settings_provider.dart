import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType { light, dark, pink }

class Settings {
  final double arabicFontSize;
  final String language;
  final AppThemeType theme;
  Settings({
    required this.arabicFontSize,
    required this.language,
    required this.theme,
  });
  Settings copyWith({
    double? arabicFontSize,
    String? language,
    AppThemeType? theme,
  }) {
    return Settings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      language: language ?? this.language,
      theme: theme ?? this.theme,
    );
  }
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier()
    : super(
        Settings(arabicFontSize: 28, language: 'id', theme: AppThemeType.light),
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('selected_language') ?? 'id';
    state = state.copyWith(language: lang);
    final themeIndex = prefs.getInt('theme') ?? 0;
    state = state.copyWith(
      language: lang,
      theme: AppThemeType.values[themeIndex],
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
