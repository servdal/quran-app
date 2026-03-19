import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:wakelock_plus/wakelock_plus.dart';

enum AppThemeType { light, dark, pink }

enum ArabicSource { quranCloud, kemenag }

enum AdzanSoundMode { native, adzan }

class Settings {
  final double arabicFontSize;
  final double ayahPanelFontSize;
  final bool keepScreenAwake;
  final String language;
  final AppThemeType theme;
  final ArabicSource arabicSource;
  final bool adzanSoundEnabled;
  final AdzanSoundMode adzanSoundMode;

  /// Android only (res/raw name without extension), e.g. `azan1`
  final String adzanSoundName;
  Settings({
    required this.arabicFontSize,
    required this.ayahPanelFontSize,
    required this.keepScreenAwake,
    required this.language,
    required this.theme,
    required this.arabicSource,
    required this.adzanSoundEnabled,
    required this.adzanSoundMode,
    required this.adzanSoundName,
  });
  Settings copyWith({
    double? arabicFontSize,
    double? ayahPanelFontSize,
    bool? keepScreenAwake,
    String? language,
    AppThemeType? theme,
    ArabicSource? arabicSource,
    bool? adzanSoundEnabled,
    AdzanSoundMode? adzanSoundMode,
    String? adzanSoundName,
  }) {
    return Settings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
      ayahPanelFontSize: ayahPanelFontSize ?? this.ayahPanelFontSize,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      arabicSource: arabicSource ?? this.arabicSource,
      adzanSoundEnabled: adzanSoundEnabled ?? this.adzanSoundEnabled,
      adzanSoundMode: adzanSoundMode ?? this.adzanSoundMode,
      adzanSoundName: adzanSoundName ?? this.adzanSoundName,
    );
  }
}

class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier()
    : super(
        Settings(
          arabicFontSize: 28,
          ayahPanelFontSize: 16,
          keepScreenAwake: !kIsWeb && Platform.isMacOS,
          language: 'id',
          theme: AppThemeType.light,
          arabicSource: ArabicSource.quranCloud,
          adzanSoundEnabled: true,
          adzanSoundMode: AdzanSoundMode.native,
          adzanSoundName: 'azan1',
        ),
      ) {
    _loadSettings();
  }
  void setFontSize(double size) {
    state = state.copyWith(arabicFontSize: size);
  }

  Future<void> setAyahPanelFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ayah_panel_font_size', size);
    state = state.copyWith(ayahPanelFontSize: size);
  }

  Future<void> setKeepScreenAwake(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keep_screen_awake', enabled);
    state = state.copyWith(keepScreenAwake: enabled);
    await _applyKeepScreenAwake(enabled);
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

  Future<void> setAdzanSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adzan_sound_enabled', enabled);
    state = state.copyWith(adzanSoundEnabled: enabled);
  }

  Future<void> setAdzanSoundMode(AdzanSoundMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('adzan_sound_mode', mode.index);
    state = state.copyWith(adzanSoundMode: mode);
  }

  Future<void> setAdzanSoundName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('adzan_sound_name', name);
    state = state.copyWith(adzanSoundName: name);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('selected_language') ?? 'id';
    final arabicIndex = prefs.getInt('arabic_source') ?? 0;
    final themeIndex = prefs.getInt('theme') ?? 0;
    final adzanSoundEnabled = prefs.getBool('adzan_sound_enabled') ?? true;
    final adzanSoundModeIndex = prefs.getInt('adzan_sound_mode') ?? 0;
    final adzanSoundName = prefs.getString('adzan_sound_name') ?? 'azan1';
    final ayahPanelFontSize = prefs.getDouble('ayah_panel_font_size') ?? 16;
    final keepScreenAwake =
        prefs.getBool('keep_screen_awake') ?? (!kIsWeb && Platform.isMacOS);
    state = state.copyWith(
      ayahPanelFontSize: ayahPanelFontSize,
      keepScreenAwake: keepScreenAwake,
      language: lang,
      theme: AppThemeType.values[themeIndex],
      arabicSource: ArabicSource.values[arabicIndex],
      adzanSoundEnabled: adzanSoundEnabled,
      adzanSoundMode: AdzanSoundMode.values[adzanSoundModeIndex],
      adzanSoundName: adzanSoundName,
    );
    await _applyKeepScreenAwake(keepScreenAwake);
  }

  Future<void> _applyKeepScreenAwake(bool enabled) async {
    if (kIsWeb || !Platform.isMacOS) return;
    if (enabled) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
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
