import 'dart:async';
import 'dart:io' show Platform;

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
import 'screens/language_selector_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _configureDatabaseFactory();
  runApp(const ProviderScope(child: MyApp()));
  unawaited(_initializeStartupServices());
}

void _configureDatabaseFactory() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

Future<void> _initializeStartupServices() async {
  try {
    await notificationService.init();
  } catch (e, stackTrace) {
    debugPrint('Notification init error (ignored): $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    if (!kIsWeb && Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      final keepScreenAwake = prefs.getBool('keep_screen_awake') ?? true;
      if (keepScreenAwake) {
        await WakelockPlus.enable();
      }
    }
  } catch (e, stackTrace) {
    debugPrint('Wakelock init error (ignored): $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

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
      home: const PermissionGateScreen(next: _LaunchScreen()),
    );
  }
}

class _LaunchScreen extends StatefulWidget {
  const _LaunchScreen();

  @override
  State<_LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<_LaunchScreen> {
  Widget? _next;

  @override
  void initState() {
    super.initState();
    unawaited(_loadInitialScreen());
  }

  Future<void> _loadInitialScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('selected_language');
      _setNext(
        lang == null ? const LanguageSelectorScreen() : const SplashScreen(),
      );
    } catch (e, stackTrace) {
      debugPrint('Launch preference error (ignored): $e');
      debugPrintStack(stackTrace: stackTrace);
      _setNext(const SplashScreen());
    }
  }

  void _setNext(Widget next) {
    if (!mounted) return;
    setState(() => _next = next);
  }

  @override
  Widget build(BuildContext context) {
    return _next ?? const SplashScreen();
  }
}
