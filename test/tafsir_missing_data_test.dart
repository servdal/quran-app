import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/models/ayah_model.dart';
import 'package:quran_app/models/grammar_model.dart' as model;
import 'package:quran_app/models/surah_detail_data.dart';
import 'package:quran_app/screens/tafsir_view_screen.dart';
import 'package:quran_app/services/quran_data_service.dart' as service;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final ayah = Ayah.fromDb({
    'aya_id': 12,
    'aya_number': 5,
    'sura_id': 2,
    'sura_name': 'Al-Baqarah',
    'aya_text': 'هُدًى',
  });
  final missing = model.Grammar.fromDb({
    'id': '1',
    'ChapterNo': '2',
    'VerseNo': '5',
    'WordNo': '1',
    'WordAr': 'هُدًى',
    'MeaningEn': 'Guidance',
  });

  Future<void> showScreen(
    WidgetTester tester,
    List<model.Grammar> words, {
    String language = 'id',
  }) async {
    SharedPreferences.setMockInitialValues({'selected_language': language});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          service
              .surahDetailProvider(2)
              .overrideWith(
                (ref) async => SurahDetailData(
                  surahName: 'Al-Baqarah',
                  surahTranslation: '',
                  revelationType: '',
                  ayahs: [ayah],
                ),
              ),
          ayahWordsProvider((
            surahId: 2,
            ayahNumber: 5,
          )).overrideWith((ref) async => words),
        ],
        child: const MaterialApp(home: TafsirViewScreen(surahId: 2)),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('nullable database fields and numeric strings are safe', () {
    expect(missing.rootWordId, 0);
    expect(missing.hasRoot, isFalse);
    expect(missing.meaningId, isEmpty);
    expect(missing.surahId, 2);
    expect(model.Grammar.fromDb({}).wordAr, isEmpty);
  });

  testWidgets('empty analysis and tafsir show an Indonesian empty state', (
    tester,
  ) async {
    await showScreen(tester, []);
    expect(find.text('Analisis kata belum tersedia.'), findsOneWidget);
    await tester.ensureVisible(find.text('Tafsir'));
    await tester.tap(find.text('Tafsir'));
    await tester.pumpAndSettle();
    expect(find.text('Tafsir belum tersedia.'), findsOneWidget);
    expect(find.text('QS 2:5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'partial words support learning, highlighting, popup and empty filters',
    (tester) async {
      await showScreen(tester, [missing]);
      expect(find.text('—'), findsOneWidget);
      await tester.tap(find.text('Pilihan belajar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mode Belajar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sorot Akar Kata'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('word-2-5-1')));
      await tester.tap(find.byKey(const ValueKey('word-2-5-1')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.textContaining('Arti belum tersedia', findRichText: true),
        findsWidgets,
      );
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Fi’il'));
      await tester.tap(find.text('Fi’il'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada kata dalam kategori ini.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('empty states follow English settings', (tester) async {
    await showScreen(tester, [], language: 'en');
    expect(find.text('Word analysis is not available yet.'), findsOneWidget);
    await tester.ensureVisible(find.text('Tafsir'));
    await tester.tap(find.text('Tafsir'));
    await tester.pumpAndSettle();
    expect(find.text('Tafsir is not available yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('word tiles read right to left on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final second = model.Grammar.fromDb({
      'id': 2,
      'ChapterNo': 2,
      'VerseNo': 5,
      'WordNo': 2,
      'WordAr': 'عَلَىٰ',
      'MeaningId': 'di atas',
    });
    await showScreen(tester, [second, missing]);
    expect(
      tester.getCenter(find.byKey(const ValueKey('word-2-5-1'))).dx,
      greaterThan(
        tester.getCenter(find.byKey(const ValueKey('word-2-5-2'))).dx,
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'font controls resize Arabic and meanings and persist preferences',
    (tester) async {
      await showScreen(tester, [missing]);
      await tester.tap(find.byTooltip('Ukuran teks'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Teks Arab +'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Arti dan tafsir +'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('arabic_font_size'), 30);
      expect(prefs.getDouble('ayah_panel_font_size'), 18);
      final tile = find.byKey(const ValueKey('word-2-5-1'));
      final arabic = tester.widget<Text>(
        find.descendant(of: tile, matching: find.text('هُدًى')),
      );
      expect(arabic.style?.fontSize, 30);
      await tester.tap(find.text('Kembalikan ukuran awal'));
      await tester.pumpAndSettle();
      expect(prefs.getDouble('arabic_font_size'), 28);
      expect(prefs.getDouble('ayah_panel_font_size'), 16);
      expect(tester.takeException(), isNull);
    },
  );
}
