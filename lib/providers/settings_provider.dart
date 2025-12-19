import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  final double arabicFontSize;
  final String language;
  Settings({
    required this.arabicFontSize,
    required this.language,
  });
  Settings copyWith({
    double? arabicFontSize,
    String? language,
  }) {
    return Settings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      language: language ?? this.language,
    );
  }
}
class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(Settings(
            arabicFontSize: 28,
            language: 'id',
          )
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
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('selected_language') ?? 'id';
    state = state.copyWith(language: lang);
  }
}
final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});
final arabicFontSizeProvider = Provider<double>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.arabicFontSize;
});

