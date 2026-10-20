import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/repository/hadith_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late HadithRepository repository;

  setUpAll(() async {
    sqfliteFfiInit();
    db = await databaseFactoryFfi.openDatabase(
      '${Directory.current.path}/assets/database/hadith.db',
      options: OpenDatabaseOptions(readOnly: true),
    );
    repository = HadithRepository(database: db);
  });

  tearDownAll(() async => db.close());

  test('six collections contain 30,845 bilingual entries', () async {
    final books = await repository.books();
    expect(books.map((b) => b.count), [7008, 5362, 4590, 4332, 5662, 3891]);
    final invalid = await db.rawQuery(
      "SELECT COUNT(*) AS n FROM hadiths WHERE trim(arabic) = '' OR trim(translation) = ''",
    );
    expect(invalid.single['n'], 0);
    expect(await db.rawQuery('PRAGMA integrity_check'), [
      {'integrity_check': 'ok'},
    ]);
  });

  test(
    'collection statistics and per-narration chapter metadata reflect SQLite',
    () async {
      final books = await repository.books();
      for (final book in books) {
        expect(book.englishCount, inInclusiveRange(0, book.count));
        expect(book.mappedCount, inInclusiveRange(0, book.count));
        expect(book.gradedCount, inInclusiveRange(0, book.count));
        expect(book.chapterCount, greaterThan(0));
      }
      expect(books.fold(0, (sum, book) => sum + book.englishCount), 24020);
      final chapters = await repository.chaptersForEntry('bukhari', 1);
      expect(chapters.single.title, 'Revelation');
      expect(await repository.chaptersForEntry('bukhari', 999999), isEmpty);
    },
  );

  test(
    'every chapter has both labels and follows the selected language',
    () async {
      final chapters = await repository.chapters();
      expect(chapters.length, 187);
      for (final chapter in chapters) {
        expect(chapter.titleId?.trim(), isNot(isEmpty));
        expect(chapter.titleId, isNotNull);
        expect(chapter.titleEn?.trim(), isNot(isEmpty));
        expect(chapter.titleEn, isNotNull);
        expect(chapter.label('id'), chapter.titleId);
        expect(chapter.label('en'), chapter.titleEn);
      }
      final revelation =
          (await repository.chaptersForEntry('bukhari', 1)).single;
      expect(revelation.label('id'), 'Permulaan Wahyu');
      expect(revelation.label('en'), 'Revelation');
      expect(revelation.title, 'Revelation');
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  test(
    'duplicate labels open the union of source chapters without duplicate hadiths',
    () async {
      final chapters = await repository.chapters();
      for (final language in ['id', 'en']) {
        expect(
          chapters.map((c) => c.label(language)).toSet().length,
          chapters.length,
        );
      }
      final manners = chapters.singleWhere(
        (c) => c.label('id') == 'Adab dan Akhlak',
      );
      expect(manners.sourceIds.length, greaterThan(1));
      final entries = await repository.entries(
        chapterId: manners.id,
        limit: 10000,
      );
      expect(entries.length, manners.count);
      expect(
        entries.map((e) => '${e.bookId}:${e.number}').toSet().length,
        entries.length,
      );
      expect(entries.map((e) => e.bookId).toSet().length, manners.bookCount);
      for (final bookId in entries.map((e) => e.bookId).toSet()) {
        final filtered = (await repository.chapters(
          bookId: bookId,
        )).singleWhere((c) => c.id == manners.id);
        expect(filtered.count, entries.where((e) => e.bookId == bookId).length);
        expect(filtered.bookCount, 1);
      }
      final alias = manners.sourceIds.last;
      expect(
        (await repository.entries(chapterId: alias, limit: 10000)).length,
        manners.count,
      );
    },
  );

  test('paging stays inside the selected collection', () async {
    final first = await repository.entries(bookId: 'muslim');
    final second = await repository.entries(bookId: 'muslim', offset: 40);
    expect(first.length, 40);
    expect(first.first.number, 1);
    expect(second.first.number, 41);
    expect([...first, ...second].every((e) => e.bookId == 'muslim'), isTrue);
  });

  test('search handles text, number, literal wildcards and quotes', () async {
    expect(
      (await repository.entries(bookId: 'bukhari', query: 'niat')).isNotEmpty,
      isTrue,
    );
    final number = await repository.entries(bookId: 'bukhari', query: '7008');
    expect(number.any((e) => e.number == 7008), isTrue);
    expect(await repository.entries(query: "' OR 1=1 --"), isEmpty);
    expect(await repository.entries(query: '%_%'), isEmpty);
    final entry =
        (await repository.entries(bookId: 'bukhari', limit: 1)).single;
    expect(entry.translation, contains("Sa'id"));
    expect(entry.translation, isNot(contains(r"\'")));
  });

  test('matched chapters span collections and retain collection filters', () async {
    final chapters = await repository.chapters();
    expect(chapters, isNotEmpty);
    final shared = chapters.firstWhere((c) => c.bookCount > 1);
    final entries = await repository.entries(
      chapterId: shared.id,
      limit: 10000,
    );
    expect(entries.map((e) => e.bookId).toSet().length, shared.bookCount);
    final book = entries.first.bookId;
    expect(
      (await repository.entries(
        chapterId: shared.id,
        bookId: book,
      )).every((e) => e.bookId == book),
      isTrue,
    );
    final memory = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    try {
      await memory.execute(
        'CREATE TABLE books(id TEXT, title TEXT, sort_order INTEGER)',
      );
      await memory.execute(
        'CREATE TABLE hadiths(book_id TEXT, number INTEGER, arabic TEXT, translation TEXT)',
      );
      await memory.execute('CREATE TABLE chapters(id TEXT, title TEXT)');
      await memory.execute(
        'CREATE TABLE hadith_chapters(chapter_id TEXT, book_id TEXT, number INTEGER)',
      );
      await memory.rawInsert(
        "INSERT INTO books VALUES ('a', 'A', 0), ('b', 'B', 1)",
      );
      await memory.rawInsert(
        "INSERT INTO hadiths VALUES ('a', 1, 'ع', 'Satu'), ('b', 2, 'ع', 'Dua')",
      );
      await memory.rawInsert(
        "INSERT INTO chapters VALUES ('c', 'Bab terverifikasi')",
      );
      await memory.rawInsert(
        "INSERT INTO hadith_chapters VALUES ('c', 'a', 1), ('c', 'b', 2)",
      );
      final fixture = HadithRepository(database: memory);
      expect((await fixture.chapters()).single.count, 2);
      expect((await fixture.entries(chapterId: 'c')).map((e) => e.bookId), [
        'a',
        'b',
      ]);
    } finally {
      await memory.close();
    }
  });
}
