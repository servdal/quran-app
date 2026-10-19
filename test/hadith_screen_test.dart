import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/repository/hadith_repository.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:quran_app/providers/hadith_reader_provider.dart';
import 'package:quran_app/screens/hadith_screen.dart';
import 'package:quran_app/services/hadith_translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporary;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    temporary = await Directory.systemTemp.createTemp('mushaf-hadith-test-');
    await databaseFactory.setDatabasesPath(temporary.path);
    SharedPreferences.setMockInitialValues({});
    await HadithRepository.instance.database;
  });

  tearDownAll(() async {
    await (await HadithRepository.instance.database).close();
    await temporary.delete(recursive: true);
  });

  Future<void> settleData(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('book selection opens list and bilingual detail', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HadithScreen())),
    );
    await settleData(tester);
    expect(find.text('Shahih Bukhari'), findsOneWidget);
    await tester.tap(find.text('Shahih Bukhari'));
    await settleData(tester);
    expect(find.text('Shahih Bukhari • No. 1'), findsOneWidget);
    await tester.tap(find.text('Shahih Bukhari • No. 1'));
    await settleData(tester);
    expect(find.text('Hadis No. 1'), findsOneWidget);
    await tester.tap(find.text('Terjemah'));
    await settleData(tester);
    expect(find.text('Terjemahan Indonesia'), findsOneWidget);
    expect(find.byType(SelectionArea), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chapter tab searches and opens matched narrations', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HadithScreen())),
    );
    await settleData(tester);
    await tester.tap(find.text('Bab'));
    await settleData(tester);
    expect(find.text('Cari judul bab'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'The Book of Fasting');
    await settleData(tester);
    await tester.tap(find.text('Kitab Puasa'));
    await settleData(tester);
    expect(find.text('Kitab Puasa'), findsOneWidget);
    expect(find.byType(Card), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('language settings update labels and use local English', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        hadithTranslationServiceProvider.overrideWithValue(
          HadithTranslationService(endpoint: ''),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HadithScreen()),
      ),
    );
    await settleData(tester);
    container.read(settingsProvider.notifier).setLanguage('en');
    await settleData(tester);
    expect(find.text('Hadith'), findsOneWidget);
    expect(find.text('Collections'), findsOneWidget);
    await tester.tap(find.text('Shahih Bukhari'));
    await settleData(tester);
    expect(find.byTooltip('Clear search'), findsOneWidget);
    await tester.tap(find.text('Shahih Bukhari • No. 1'));
    await settleData(tester);
    await tester.tap(find.text('Translation'));
    await settleData(tester);
    expect(find.text('English • fawazahmed0/hadith-api'), findsOneWidget);
    expect(find.textContaining('Showing the Indonesian text.'), findsNothing);
  });
  testWidgets(
    'translation is lazy and follows language changes on the open tab',
    (tester) async {
      var requests = 0;
      final service = HadithTranslationService(
        endpoint: 'https://example.com/hadiths',
        client: MockClient((request) async {
          requests++;
          final language = (jsonDecode(request.body) as Map)['target_lang'];
          return http.Response(
            jsonEncode({
              'data': [
                {'translation': 'Result $language'},
              ],
            }),
            200,
          );
        }),
      );
      final container = ProviderContainer(
        overrides: [
          hadithTranslationServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      final entry = HadithEntry.fromRow({
        'book_id': 'bukhari',
        'book_title': 'Bukhari',
        'number': 1,
        'arabic': 'ع',
        'translation': 'Satu',
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: HadithDetailScreen(entry: entry)),
        ),
      );
      await settleData(tester);
      await container.read(settingsProvider.notifier).setLanguage('en');
      await settleData(tester);
      expect(requests, 0);
      await tester.tap(find.text('Translation'));
      await settleData(tester);
      expect(find.text('Result en'), findsOneWidget);
      await container.read(settingsProvider.notifier).setLanguage('fr');
      await settleData(tester);
      expect(find.text('Result fr'), findsOneWidget);
      expect(requests, 2);
    },
  );
  testWidgets('bookmark opens the exact collection and number from its tab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(hadithReaderProvider.notifier).ready;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HadithScreen()),
      ),
    );
    await settleData(tester);
    await tester.tap(find.text('Shahih Bukhari'));
    await settleData(tester);
    await tester.tap(find.text('Shahih Bukhari • No. 1'));
    await settleData(tester);
    await tester.tap(find.byTooltip('Simpan bookmark'));
    await settleData(tester);
    expect(
      container.read(hadithReaderProvider).isBookmarked('bukhari', 1),
      isTrue,
    );
    await tester.pageBack();
    await settleData(tester);
    await tester.pageBack();
    await settleData(tester);
    await tester.tap(find.text('Bookmark'));
    await settleData(tester);
    await tester.tap(find.text('Shahih Bukhari • No. 1'));
    await settleData(tester);
    expect(find.text('Hadis No. 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Hapus bookmark'));
    await settleData(tester);
    expect(container.read(hadithReaderProvider).bookmarks, isEmpty);
  });

  testWidgets('appearance sheet applies font, sizes and combined text', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(hadithReaderProvider.notifier).ready;
    final entry = HadithEntry.fromRow({
      'book_id': 'bukhari',
      'book_title': 'Bukhari',
      'number': 1,
      'arabic': 'نص الحديث',
      'translation': 'Contoh hadis',
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: HadithDetailScreen(entry: entry)),
      ),
    );
    await settleData(tester);
    await tester.tap(find.byTooltip('Tampilan teks'));
    await settleData(tester);
    await tester.tap(find.text('Tab Arab / Terjemah'));
    await settleData(tester);
    await tester.tap(find.text('Arab dan terjemah').last);
    await settleData(tester);
    await tester.tap(find.text('LPMQ'));
    await settleData(tester);
    await tester.tap(find.text('KFGQPC').last);
    await settleData(tester);
    await tester.drag(
      find.byKey(const ValueKey('hadith-arabic-size')),
      const Offset(60, 0),
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Terapkan'));
    await tester.tap(find.text('Terapkan'));
    await settleData(tester);
    expect(container.read(hadithReaderProvider).mode, HadithTextMode.both);
    final arabic = tester.widget<Text>(
      find.byKey(const ValueKey('hadith-arabic-text')),
    );
    expect(arabic.style!.fontFamily, 'KFGQPC');
    expect(arabic.style!.fontSize, greaterThan(28));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hadith-translation-text')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Contoh hadis'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'modern library fits mobile and desktop in light and dark themes',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [360.0, 1100.0]) {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: Colors.teal,
                    brightness: brightness,
                  ),
                ),
                home: const HadithScreen(),
              ),
            ),
          );
          await settleData(tester);
          expect(find.text('KOLEKSI HADIS'), findsOneWidget);
          expect(find.text('30.845'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );

  testWidgets(
    'metadata shows source references, attributed grades, and a chapter link',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final entry = await tester.runAsync(
        () => HadithRepository.instance.entry('abu-daud', 1),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: HadithDetailScreen(entry: entry!)),
        ),
      );
      await settleData(tester);
      await tester.tap(find.byTooltip('Informasi hadis'));
      await settleData(tester);
      expect(find.text('Bab terkait'), findsOneWidget);
      expect(find.textContaining('abudawud:'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Penilaian riwayat'),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Penilaian riwayat'), findsOneWidget);
      expect(find.text('Al-Albani'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional library design preview', (tester) async {
    final directory = Platform.environment['HADITH_SCREENSHOT_DIR'];
    if (directory == null) return;
    for (final font in ['Poppins', 'LPMQ']) {
      final loader = FontLoader(font)..addFont(
        rootBundle.load(
          'assets/fonts/${font == 'Poppins' ? 'Poppins-Regular.ttf' : 'LPMQ.ttf'}',
        ),
      );
      await tester.runAsync(() => loader.load());
    }
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await tester.runAsync(() => iconLoader.load());
    tester.view.physicalSize = const Size(420, 940);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const key = ValueKey('design-preview');
    await tester.pumpWidget(
      ProviderScope(
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            theme: ThemeData(
              fontFamily: 'Poppins',
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff126658),
              ),
            ),
            home: const HadithScreen(),
          ),
        ),
      ),
    );
    await settleData(tester);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/hadith-library.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  });
}
