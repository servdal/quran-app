// lib/services/database_web.dart

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Obtains a database connection for the web platform.
Future<QueryExecutor> constructDb({bool logStatements = false}) async {
  print("[WEB DATABASE] Memulai koneksi...");
  final result = await WasmDatabase.open(
    // A name for the database in the browser's IndexedDB.
    databaseName: 'grammar-db-v1',

    // The path to the sqlite3.wasm file you downloaded.
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    
    // THIS IS THE NEW REQUIRED PARAMETER:
    // The path to the worker file you just created.
    driftWorkerUri: Uri.parse('drift_worker.js'),

    // This function runs only if the database doesn't exist yet.
    // It's responsible for providing the initial data from our asset.
    initializeDatabase: () async {
      print("[WEB DATABASE] Database tidak ditemukan di browser, memuat dari assets...");
      final byteData = await rootBundle.load('assets/database/grammar.db');
      print("[WEB DATABASE] Assets berhasil dimuat.");
      return byteData.buffer.asUint8List();
    },
  );
  print("[WEB DATABASE] Koneksi berhasil dibuat.");
  return result.resolvedExecutor;
}