// lib/services/database_native.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<QueryExecutor> constructDb({bool logStatements = false}) async {
  final appDocumentsDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(appDocumentsDir.path, 'database/grammar.db');
  final dbFile = File(dbPath);
  return NativeDatabase.createInBackground(dbFile, logStatements: logStatements);
}
