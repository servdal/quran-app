import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  final double arabicFontSize;

  Settings({
    required this.arabicFontSize,
  });

  Settings copyWith({
    double? arabicFontSize,
  }) {
    return Settings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
    );
  }
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(Settings(arabicFontSize: 28.0)) {
    _loadSettings();
  }

  static const String _fontSizeKey = 'arabic_font_size';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_fontSizeKey) ?? 28.0;
    state = Settings(arabicFontSize: fontSize);
  }

  Future<void> setFontSize(double newSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, newSize);
    state = state.copyWith(arabicFontSize: newSize);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});
final arabicFontSizeProvider = Provider<double>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.arabicFontSize;
});

