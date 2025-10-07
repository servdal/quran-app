import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// Ini akan menghasilkan file bernama 'database.g.dart'
part 'database_service.g.dart';
// 1. Definisikan Tabel
// Nama kelas (Grammar) akan menjadi representasi satu baris data
// Nama tabel di database adalah 'grammar'
@DataClassName('Grammar')
class GrammarTable extends Table {
  // Tentukan kolom-kolomnya
  TextColumn get rootAr => text().named('RootAr')();
  TextColumn get rootEn => text().named('RootEn')();
  TextColumn get meaningEn => text().named('MeaningEn')();
  TextColumn get meaningID => text().named('MeaningID').nullable()();
  TextColumn get wordAr => text().named('WordAr')();
  TextColumn get grammarFormDesc => text().named('GrammarFormDesc')();
  IntColumn get chapterNo => integer().named('ChapterNo')();
  IntColumn get verseNo => integer().named('VerseNo')();
  IntColumn get wordNo => integer().named('WordNo')();

  // Kita perlu mendefinisikan primary key jika ada, jika tidak Drift akan membuatnya
  // Jika tidak ada kolom ID unik, kita bisa membuat komposit key
  @override
  Set<Column> get primaryKey => {chapterNo, verseNo, wordNo};
}

// 2. Definisikan Kelas Database
@DriftDatabase(tables: [GrammarTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase({required LazyDatabase connection}) : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Query untuk mendapatkan semua kata dari sebuah ayat
  Future<List<Grammar>> getWordsForAyah(int chapter, int verse) {
    return (select(grammarTable)
          ..where((tbl) => tbl.chapterNo.equals(chapter))
          ..where((tbl) => tbl.verseNo.equals(verse))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.wordNo)]))
        .get();
  }
}

// 3. Logika Koneksi Database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    // Dapatkan folder untuk menyimpan database
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'database/grammar.db'));

    // Salin dari assets jika belum ada
    if (!await file.exists()) {
      final data = await rootBundle.load('assets/database/grammar.db');
      await file.writeAsBytes(data.buffer.asUint8List());
    }

    return NativeDatabase(file);
  });
}
