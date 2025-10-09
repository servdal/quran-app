import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'database_native.dart' if (dart.library.html) 'database_web.dart';

part 'database.g.dart';

@DataClassName('Grammar')
class GrammarTable extends Table {
  @override
  String get tableName => 'grammar';

  // Kolom Primary Key (TIDAK BOLEH NULL)
  IntColumn get chapterNo => integer().named('ChapterNo')();
  IntColumn get verseNo => integer().named('VerseNo')();
  IntColumn get wordNo => integer().named('WordNo')();
  
  // --- SEMUA KOLOM LAIN DIJADIKAN NULLABLE ---
  // Ini akan membuat aplikasi lebih tahan terhadap data yang hilang/kosong
  TextColumn get rootAr => text().named('RootAr').nullable()();
  TextColumn get rootCode => text().named('RootCode').nullable()();
  TextColumn get rootEn => text().named('RootEn').nullable()();
  IntColumn get rootWordId => integer().named('RootWordId').nullable()();
  TextColumn get meaningEn => text().named('MeaningEn').nullable()();
  TextColumn get wordAr => text().named('WordAr').nullable()();
  TextColumn get grammarFormDesc => text().named('GrammarFormDesc').nullable()();
  TextColumn get meaningID => text().named('MeaningID').nullable()();
  TextColumn get grammarFormDescID => text().named('GrammarFormDescID').nullable()();

  @override
  Set<Column> get primaryKey => {chapterNo, verseNo, wordNo};
}

@DriftDatabase(tables: [GrammarTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        
        print("Database baru dibuat. Memulai proses seeding dari JSON...");
        
        final jsonString = await rootBundle.loadString('assets/database/grammar_final.json');
        final List<dynamic> jsonData = json.decode(jsonString);
        
        final List<GrammarTableCompanion> grammarEntries = [];
        for (var entry in jsonData) {
          grammarEntries.add(GrammarTableCompanion.insert(
            rootAr: entry['RootAr'] as String? ?? '',
            rootCode: entry['RootCode'] as String? ?? '',
            rootEn: entry['RootEn'] as String? ?? '',
            rootWordId: entry['RootWordId'] as int? ?? 0,
            chapterNo: entry['ChapterNo'] as int,
            meaningEn: entry['MeaningEn'] as String? ?? '',
            verseNo: entry['VerseNo'] as int,
            wordAr: entry['WordAr'] as String? ?? '',
            wordNo: entry['WordNo'] as int,
            grammarFormDesc: entry['GrammarFormDesc'] as String? ?? '',
            meaningID: entry['MeaningID'] as String? ?? '',
            grammarFormDescID: entry['GrammarFormDescID'] as String? ?? '',
          ));
        }

        await batch((batch) {
          batch.insertAll(grammarTable, grammarEntries);
        });
        
        print("Seeding selesai. ${grammarEntries.length} baris data telah dimasukkan.");
      },
    );
  }
  
  Future<List<Grammar>> getWordsForAyah(int chapter, int verse) async {
    return (select(grammarTable)
          ..where((tbl) => tbl.chapterNo.equals(chapter))
          ..where((tbl) => tbl.verseNo.equals(verse))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.wordNo)]))
        .get();
  }
}