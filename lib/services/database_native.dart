// lib/services/database_native.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<QueryExecutor> constructDb({bool logStatements = false}) async {
  final db = LazyDatabase(() async {
    // 1. Dapatkan path ke direktori dokumen aplikasi.
    final appDocumentsDir = await getApplicationDocumentsDirectory();
    
    // 2. Tentukan path tujuan, termasuk sub-direktori 'database'.
    final dbDirectory = Directory(p.join(appDocumentsDir.path, 'database'));
    final dbFile = File(p.join(dbDirectory.path, 'grammar.db'));

    print("Lokasi database yang diharapkan: ${dbFile.path}");

    // 3. Cek jika file database BELUM ADA di direktori tujuan.
    if (!await dbFile.exists()) {
      print("Database tidak ditemukan. Menyalin dari assets...");
      
      // 4. Pastikan direktori tujuan sudah ada.
      // `recursive: true` akan membuat semua direktori yang diperlukan.
      await dbDirectory.create(recursive: true);
      print("Direktori 'database' telah dibuat/diverifikasi.");

      // 5. Muat database dari assets menggunakan path yang benar.
      try {
        final blob = await rootBundle.load('assets/database/grammar.db');
        final buffer = blob.buffer;
        await dbFile.writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
        print("Database berhasil disalin ke ${dbFile.path}");
      } catch (e) {
        print("GAGAL MENYALIN DATABASE: $e");
      }
    } else {
      print("Database sudah ada di lokasi.");
    }

    return NativeDatabase(dbFile, logStatements: logStatements);
  });
  return db;
}