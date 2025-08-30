import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 1. Model untuk menampung semua pengaturan aplikasi
class Settings {
  final double arabicFontSize;
  // Anda bisa menambahkan pengaturan lain di sini di masa depan, contoh:
  // final String qari;
  // final bool showTranslation;

  Settings({
    required this.arabicFontSize,
    // required this.qari,
    // required this.showTranslation,
  });

  // Fungsi untuk membuat salinan pengaturan dengan nilai baru
  Settings copyWith({
    double? arabicFontSize,
  }) {
    return Settings(
      arabicFontSize: arabicFontSize ?? this.arabicFontSize,
    );
  }
}

// 2. Notifier yang mengelola state dari objek Settings
class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(Settings(arabicFontSize: 28.0)) { // Nilai default
    _loadSettings();
  }

  static const String _fontSizeKey = 'arabic_font_size';

  // Memuat semua pengaturan saat aplikasi dimulai
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final fontSize = prefs.getDouble(_fontSizeKey) ?? 28.0;
    state = Settings(arabicFontSize: fontSize);
  }

  // Fungsi untuk mengubah ukuran font
  Future<void> setFontSize(double newSize) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, newSize);
    // Memperbarui state dengan membuat salinan objek Settings
    state = state.copyWith(arabicFontSize: newSize);
  }
  
  // Anda bisa menambahkan fungsi lain untuk mengubah pengaturan lain di sini
  // Future<void> setQari(String newQari) async { ... }
}

// 3. Provider utama yang akan digunakan di seluruh aplikasi
final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});


// #### PROVIDER YANG HILANG DIKEMBALIKAN DI SINI ####
// 4. Provider turunan (derived provider) khusus untuk ukuran font Arab.
// Ini memungkinkan widget untuk hanya "mendengarkan" perubahan pada ukuran font,
// dan mengembalikan nama provider yang dicari oleh file lain.
final arabicFontSizeProvider = Provider<double>((ref) {
  // "Mendengarkan" provider utama
  final settings = ref.watch(settingsProvider);
  // Mengembalikan hanya properti arabicFontSize dari objek Settings
  return settings.arabicFontSize;
});

