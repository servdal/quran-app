import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static Database? _db;
  static const int _dbVersion = 3;
  static const String _dbName = 'quran.db';
  static const String _assetDbPath = 'assets/database/quran.db';

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    if (!await File(path).exists()) {
      await _copyDatabaseFromAssets(path);
    } else if (await _needsAssetRefresh(path)) {
      await deleteDatabase(path);
      await _copyDatabaseFromAssets(path);
    }

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // SAFETY: only add column if not exists
          final columns = await db.rawQuery("PRAGMA table_info(merged_aya)");

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

  static Future<void> _copyDatabaseFromAssets(String path) async {
    await Directory(dirname(path)).create(recursive: true);

    final data = await rootBundle.load(_assetDbPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    await File(path).writeAsBytes(bytes, flush: true);
  }

  static Future<bool> _needsAssetRefresh(String path) async {
    Database? existingDb;

    try {
      existingDb = await openDatabase(
        path,
        readOnly: true,
        singleInstance: false,
      );

      return await existingDb.getVersion() < _dbVersion;
    } catch (_) {
      return true;
    } finally {
      await existingDb?.close();
    }
  }
}
