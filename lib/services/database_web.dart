// lib/services/database_web.dart

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

Future<QueryExecutor> constructDb({bool logStatements = false}) async {
  final result = await WasmDatabase.open(
    databaseName: 'grammar-db-v1',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor;
}