import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:quran_app/screens/permission_gate_screen.dart';
import 'package:quran_app/theme/app_theme.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'screens/language_selector_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On desktop, sqflite needs ffi factory initialization before openDatabase.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  if (!kIsWeb && Platform.isMacOS) {
    await WakelockPlus.enable();
  }
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('selected_language');
  final keepScreenAwake =
      prefs.getBool('keep_screen_awake') ?? (!kIsWeb && Platform.isMacOS);
  if (!kIsWeb && Platform.isMacOS && keepScreenAwake) {
    await WakelockPlus.enable();
  }
  runApp(ProviderScope(child: MyApp(initialLang: lang)));
}

class MyApp extends ConsumerWidget {
  final String? initialLang;
  const MyApp({super.key, required this.initialLang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    ThemeData theme;
    switch (settings.theme) {
      case AppThemeType.dark:
        theme = AppTheme.darkTheme;
        break;
      case AppThemeType.pink:
        theme = AppTheme.pinkTheme;
        break;
      default:
        theme = AppTheme.lightTheme;
    }
    return MaterialApp(
      title: 'Mushaf',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: PermissionGateScreen(
        next:
            initialLang == null
                ? const LanguageSelectorScreen()
                : const SplashScreen(),
      ),
    );
  }
}
