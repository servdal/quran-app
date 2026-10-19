import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class HadithBook {
  final String id;
  final String title;
  final int count;

  final int englishCount;
  final int gradedCount;
  final int chapterCount;
  final int mappedCount;
  const HadithBook(
    this.id,
    this.title,
    this.count, {
    this.englishCount = 0,
    this.gradedCount = 0,
    this.chapterCount = 0,
    this.mappedCount = 0,
  });
}

class HadithEntry {
  final String bookId;
  final String bookTitle;
  final int number;
  final String arabic;
  final String translation;
  final String? english;
  final String? sourceReference;
  final List<Map<String, dynamic>> grades;

  HadithEntry.fromRow(Map<String, Object?> row)
    : bookId = row['book_id'] as String,
      bookTitle = row['book_title'] as String,
      number = row['number'] as int,
      arabic = row['arabic'] as String,
      translation = row['translation'] as String,
      english = row['english'] as String?,
      sourceReference = row['source_reference'] as String?,
      grades =
          row['grades'] == null
              ? const []
              : (jsonDecode(row['grades'] as String) as List)
                  .cast<Map<String, dynamic>>();
}

class HadithChapter {
  final String id;
  final String title;
  final int count;
  final int bookCount;

  const HadithChapter(this.id, this.title, this.count, this.bookCount);
}

class HadithRepository {
  static final instance = HadithRepository();
  Future<Database>? _opening;

  HadithRepository({Database? database})
    : _opening = database == null ? null : Future.value(database);

  Future<Database> get database => _opening ??= _openWithRetry();

  Future<Database> _openWithRetry() async {
    try {
      final path = p.join(await getDatabasesPath(), 'hadith-v2.db');
      if (!await File(path).exists()) {
        await Directory(p.dirname(path)).create(recursive: true);
        final data = await rootBundle.load('assets/database/hadith.db');
        final temporary = File('$path.tmp');
        await temporary.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        );
        await temporary.rename(path);
      }
      return await openDatabase(path, readOnly: true);
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<List<HadithBook>> books() async {
    final rows = await (await database).rawQuery('''
      SELECT b.*, COALESCE(s.english_count,0) AS english_count,
        COALESCE(s.graded_count,0) AS graded_count,
        COALESCE(c.chapter_count,0) AS chapter_count, COALESCE(c.mapped_count,0) AS mapped_count
      FROM books b LEFT JOIN (
        SELECT book_id, SUM(english IS NOT NULL AND trim(english) != '') AS english_count,
          SUM(grades IS NOT NULL AND grades != '[]') AS graded_count
        FROM hadiths GROUP BY book_id
      ) s ON s.book_id=b.id LEFT JOIN (
        SELECT book_id, COUNT(DISTINCT chapter_id) AS chapter_count,
          COUNT(DISTINCT number) AS mapped_count FROM hadith_chapters GROUP BY book_id
      ) c ON c.book_id=b.id ORDER BY b.sort_order
    ''');
    return rows
        .map(
          (r) => HadithBook(
            r['id'] as String,
            r['title'] as String,
            r['hadith_count'] as int,
            englishCount: r['english_count'] as int,
            gradedCount: r['graded_count'] as int,
            chapterCount: r['chapter_count'] as int,
            mappedCount: r['mapped_count'] as int,
          ),
        )
        .toList();
  }

  Future<List<HadithChapter>> chapters({String? bookId}) async {
    final rows = await (await database).rawQuery('''
      SELECT c.id, c.title, COUNT(*) AS total, COUNT(DISTINCT hc.book_id) AS book_count FROM chapters c
      JOIN hadith_chapters hc ON hc.chapter_id = c.id
      ${bookId == null ? '' : 'WHERE hc.book_id = ?'}
      GROUP BY c.id, c.title ORDER BY c.title
    ''', bookId == null ? [] : [bookId]);
    return rows
        .map(
          (r) => HadithChapter(
            r['id'] as String,
            r['title'] as String,
            r['total'] as int,
            r['book_count'] as int,
          ),
        )
        .toList();
  }

  Future<List<HadithChapter>> chaptersForEntry(
    String bookId,
    int number,
  ) async {
    final rows = await (await database).rawQuery(
      'SELECT c.id, c.title FROM chapters c JOIN hadith_chapters hc ON hc.chapter_id=c.id '
      'WHERE hc.book_id=? AND hc.number=? ORDER BY c.title',
      [bookId, number],
    );
    return rows
        .map(
          (r) => HadithChapter(r['id'] as String, r['title'] as String, 1, 1),
        )
        .toList();
  }

  Future<HadithEntry?> entry(String bookId, int number) async {
    final rows = await (await database).rawQuery(
      'SELECT h.*, b.title AS book_title FROM hadiths h JOIN books b ON b.id=h.book_id '
      'WHERE h.book_id=? AND h.number=?',
      [bookId, number],
    );
    return rows.isEmpty ? null : HadithEntry.fromRow(rows.single);
  }

  Future<List<HadithEntry>> entries({
    String? bookId,
    String? chapterId,
    String query = '',
    int offset = 0,
    int limit = 40,
  }) async {
    final conditions = <String>[];
    final args = <Object?>[];
    if (bookId != null) {
      conditions.add('h.book_id = ?');
      args.add(bookId);
    }
    if (chapterId != null) {
      conditions.add(
        'EXISTS (SELECT 1 FROM hadith_chapters hc WHERE '
        'hc.book_id = h.book_id AND hc.number = h.number AND hc.chapter_id = ?)',
      );
      args.add(chapterId);
    }
    final keyword = query.trim();
    if (keyword.isNotEmpty) {
      final escaped = keyword
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      conditions.add(
        "(h.translation LIKE ? ESCAPE '\\' OR h.arabic LIKE ? ESCAPE '\\' OR h.english LIKE ? ESCAPE '\\' OR h.number = ?)",
      );
      args.addAll([
        '%$escaped%',
        '%$escaped%',
        '%$escaped%',
        int.tryParse(keyword) ?? -1,
      ]);
    }
    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = await (await database).rawQuery(
      '''
      SELECT h.*, b.title AS book_title FROM hadiths h
      JOIN books b ON b.id = h.book_id $where
      ORDER BY b.sort_order, h.number LIMIT ? OFFSET ?
    ''',
      [...args, limit, offset],
    );
    return rows.map(HadithEntry.fromRow).toList();
  }
}
