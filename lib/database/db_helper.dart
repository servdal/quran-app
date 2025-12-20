import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;
  static const int _dbVersion = 2;
  static const String _dbName = 'quran.db';

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    // Copy database from assets if not exists
    if (!await File(path).exists()) {
      await Directory(dirname(path)).create(recursive: true);

      ByteData data = await rootBundle.load('assets/database/quran.db');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // SAFETY: only add column if not exists
          final columns = await db.rawQuery(
            "PRAGMA table_info(merged_aya)",
          );

          final hasColumn = columns.any(
            (c) => c['name'] == 'tafsir_jalalayn_en',
          );

          if (!hasColumn) {
            await db.execute(
              'ALTER TABLE merged_aya ADD COLUMN tafsir_jalalayn_en TEXT',
            );
          }
        }
      },
    );

    return _db!;
  }
}
