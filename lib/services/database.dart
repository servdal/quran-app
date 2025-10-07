import 'package:drift/drift.dart';
import 'database_native.dart' if (dart.library.html) 'database_web.dart';
part 'database.g.dart';

// Tabel tetap sama
@DataClassName('Grammar')
class GrammarTable extends Table {
  TextColumn get rootAr => text().named('RootAr')();
  TextColumn get rootEn => text().named('RootEn')();
  TextColumn get meaningEn => text().named('MeaningEn')();
  TextColumn get meaningID => text().named('MeaningID')();
  TextColumn get wordAr => text().named('WordAr')();
  TextColumn get grammarFormDesc => text().named('GrammarFormDesc')();
  IntColumn get chapterNo => integer().named('ChapterNo')();
  IntColumn get verseNo => integer().named('VerseNo')();
  IntColumn get wordNo => integer().named('WordNo')();
  @override
  Set<Column> get primaryKey => {chapterNo, verseNo, wordNo};
}

@DriftDatabase(tables: [GrammarTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;

  Future<List<Grammar>> getWordsForAyah(int chapter, int verse) {
    return (select(grammarTable)
          ..where((tbl) => tbl.chapterNo.equals(chapter))
          ..where((tbl) => tbl.verseNo.equals(verse))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.wordNo)]))
        .get();
  }
}