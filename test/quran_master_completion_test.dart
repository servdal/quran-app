import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/models/grammar_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  setUpAll(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(
      '${Directory.current.path}/assets/database/quran.db',
      options: OpenDatabaseOptions(readOnly: true),
    );
  });
  tearDownAll(() => db.close());

  test('all verse positions are present and Arabic text is nonempty', () async {
    expect(
      (await db.rawQuery(
        'SELECT COUNT(*) AS n FROM master_edited',
      )).single['n'],
      77430,
    );
    expect(
      (await db.rawQuery(
        'SELECT COUNT(*) AS n FROM (SELECT DISTINCT ChapterNo, VerseNo, WordNo FROM master_edited)',
      )).single['n'],
      77429,
    );
    expect(
      await db.rawQuery(
        'SELECT DISTINCT sura_id, aya_number FROM merged_aya EXCEPT SELECT ChapterNo, VerseNo FROM master_edited',
      ),
      isEmpty,
    );
    expect(
      (await db.rawQuery(
        "SELECT COUNT(*) AS n FROM master_edited WHERE WordAr IS NULL OR trim(WordAr) = '' OR WordAr LIKE '%??%'",
      )).single['n'],
      0,
    );
    expect(await db.getVersion(), 5);
    expect(await db.rawQuery('PRAGMA integrity_check'), [
      {'integrity_check': 'ok'},
    ]);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test(
    '2:5 has eight words and missing analysis remains unknown in the app model',
    () async {
      final rows = await db.rawQuery(
        'SELECT * FROM master_edited WHERE ChapterNo=2 AND VerseNo=5 ORDER BY WordNo',
      );
      expect(rows.map((r) => r['WordNo']), [1, 2, 3, 4, 5, 6, 7, 8]);
      final words =
          rows
              .map((row) => Grammar.fromDb(Map<String, dynamic>.from(row)))
              .toList();
      expect(words.first.rootWordId, 0);
      expect(words.first.type, GrammarType.unknown);
      expect(words.first.meaningId, isEmpty);
      expect(words.first.meaningEn, 'Those');
      expect(words[2].rootWordId, 522);
      expect(words[2].grammarDescEn, 'Noun');
    },
  );

  test(
    'original multi-root annotations remain and empty final word is repaired',
    () async {
      final roots = await db.rawQuery(
        'SELECT id,RootWordId FROM master_edited WHERE ChapterNo=20 AND VerseNo=94 AND WordNo=2 ORDER BY id',
      );
      expect(roots.map((r) => r['id']), [8178, 13219]);
      expect(roots.map((r) => r['RootWordId']), [114, 187]);
      final word =
          (await db.rawQuery(
            'SELECT WordAr FROM master_edited WHERE id=35711',
          )).single['WordAr'];
      expect(word, 'عَظِيمًۢا');
    },
  );

  test('added analysis and repaired fields retain provenance', () async {
    final rows = await db.rawQuery(
      'SELECT * FROM master_edited_completion_log WHERE surah=2 AND ayah=5 AND word_no=1',
    );
    expect(rows.single['method'], 'api_only');
    expect(rows.single['source_url'], 'https://ummahapi.com/api/quran/words/2');
    expect(rows.single['transliteration_en'], 'ulāika');
    expect(
      (await db.rawQuery(
        "SELECT COUNT(*) AS n FROM master_edited_completion_log WHERE original_values!='{}'",
      )).single['n'],
      26,
    );
  });
}
