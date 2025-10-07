// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GrammarTableTable extends GrammarTable
    with TableInfo<$GrammarTableTable, Grammar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _rootArMeta = const VerificationMeta('rootAr');
  @override
  late final GeneratedColumn<String> rootAr = GeneratedColumn<String>(
    'RootAr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rootEnMeta = const VerificationMeta('rootEn');
  @override
  late final GeneratedColumn<String> rootEn = GeneratedColumn<String>(
    'RootEn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningEnMeta = const VerificationMeta(
    'meaningEn',
  );
  @override
  late final GeneratedColumn<String> meaningEn = GeneratedColumn<String>(
    'MeaningEn',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningIDMeta = const VerificationMeta(
    'meaningID',
  );
  @override
  late final GeneratedColumn<String> meaningID = GeneratedColumn<String>(
    'MeaningID',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordArMeta = const VerificationMeta('wordAr');
  @override
  late final GeneratedColumn<String> wordAr = GeneratedColumn<String>(
    'WordAr',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grammarFormDescMeta = const VerificationMeta(
    'grammarFormDesc',
  );
  @override
  late final GeneratedColumn<String> grammarFormDesc = GeneratedColumn<String>(
    'GrammarFormDesc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterNoMeta = const VerificationMeta(
    'chapterNo',
  );
  @override
  late final GeneratedColumn<int> chapterNo = GeneratedColumn<int>(
    'ChapterNo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _verseNoMeta = const VerificationMeta(
    'verseNo',
  );
  @override
  late final GeneratedColumn<int> verseNo = GeneratedColumn<int>(
    'VerseNo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wordNoMeta = const VerificationMeta('wordNo');
  @override
  late final GeneratedColumn<int> wordNo = GeneratedColumn<int>(
    'WordNo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    rootAr,
    rootEn,
    meaningEn,
    meaningID,
    wordAr,
    grammarFormDesc,
    chapterNo,
    verseNo,
    wordNo,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<Grammar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('RootAr')) {
      context.handle(
        _rootArMeta,
        rootAr.isAcceptableOrUnknown(data['RootAr']!, _rootArMeta),
      );
    } else if (isInserting) {
      context.missing(_rootArMeta);
    }
    if (data.containsKey('RootEn')) {
      context.handle(
        _rootEnMeta,
        rootEn.isAcceptableOrUnknown(data['RootEn']!, _rootEnMeta),
      );
    } else if (isInserting) {
      context.missing(_rootEnMeta);
    }
    if (data.containsKey('MeaningEn')) {
      context.handle(
        _meaningEnMeta,
        meaningEn.isAcceptableOrUnknown(data['MeaningEn']!, _meaningEnMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningEnMeta);
    }
    if (data.containsKey('MeaningID')) {
      context.handle(
        _meaningIDMeta,
        meaningID.isAcceptableOrUnknown(data['MeaningID']!, _meaningIDMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningIDMeta);
    }
    if (data.containsKey('WordAr')) {
      context.handle(
        _wordArMeta,
        wordAr.isAcceptableOrUnknown(data['WordAr']!, _wordArMeta),
      );
    } else if (isInserting) {
      context.missing(_wordArMeta);
    }
    if (data.containsKey('GrammarFormDesc')) {
      context.handle(
        _grammarFormDescMeta,
        grammarFormDesc.isAcceptableOrUnknown(
          data['GrammarFormDesc']!,
          _grammarFormDescMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grammarFormDescMeta);
    }
    if (data.containsKey('ChapterNo')) {
      context.handle(
        _chapterNoMeta,
        chapterNo.isAcceptableOrUnknown(data['ChapterNo']!, _chapterNoMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterNoMeta);
    }
    if (data.containsKey('VerseNo')) {
      context.handle(
        _verseNoMeta,
        verseNo.isAcceptableOrUnknown(data['VerseNo']!, _verseNoMeta),
      );
    } else if (isInserting) {
      context.missing(_verseNoMeta);
    }
    if (data.containsKey('WordNo')) {
      context.handle(
        _wordNoMeta,
        wordNo.isAcceptableOrUnknown(data['WordNo']!, _wordNoMeta),
      );
    } else if (isInserting) {
      context.missing(_wordNoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chapterNo, verseNo, wordNo};
  @override
  Grammar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grammar(
      rootAr:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}RootAr'],
          )!,
      rootEn:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}RootEn'],
          )!,
      meaningEn:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}MeaningEn'],
          )!,
      meaningID:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}MeaningID'],
          )!,
      wordAr:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}WordAr'],
          )!,
      grammarFormDesc:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}GrammarFormDesc'],
          )!,
      chapterNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}ChapterNo'],
          )!,
      verseNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}VerseNo'],
          )!,
      wordNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}WordNo'],
          )!,
    );
  }

  @override
  $GrammarTableTable createAlias(String alias) {
    return $GrammarTableTable(attachedDatabase, alias);
  }
}

class Grammar extends DataClass implements Insertable<Grammar> {
  final String rootAr;
  final String rootEn;
  final String meaningEn;
  final String meaningID;
  final String wordAr;
  final String grammarFormDesc;
  final int chapterNo;
  final int verseNo;
  final int wordNo;
  const Grammar({
    required this.rootAr,
    required this.rootEn,
    required this.meaningEn,
    required this.meaningID,
    required this.wordAr,
    required this.grammarFormDesc,
    required this.chapterNo,
    required this.verseNo,
    required this.wordNo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['RootAr'] = Variable<String>(rootAr);
    map['RootEn'] = Variable<String>(rootEn);
    map['MeaningEn'] = Variable<String>(meaningEn);
    map['MeaningID'] = Variable<String>(meaningID);
    map['WordAr'] = Variable<String>(wordAr);
    map['GrammarFormDesc'] = Variable<String>(grammarFormDesc);
    map['ChapterNo'] = Variable<int>(chapterNo);
    map['VerseNo'] = Variable<int>(verseNo);
    map['WordNo'] = Variable<int>(wordNo);
    return map;
  }

  GrammarTableCompanion toCompanion(bool nullToAbsent) {
    return GrammarTableCompanion(
      rootAr: Value(rootAr),
      rootEn: Value(rootEn),
      meaningEn: Value(meaningEn),
      meaningID: Value(meaningID),
      wordAr: Value(wordAr),
      grammarFormDesc: Value(grammarFormDesc),
      chapterNo: Value(chapterNo),
      verseNo: Value(verseNo),
      wordNo: Value(wordNo),
    );
  }

  factory Grammar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grammar(
      rootAr: serializer.fromJson<String>(json['rootAr']),
      rootEn: serializer.fromJson<String>(json['rootEn']),
      meaningEn: serializer.fromJson<String>(json['meaningEn']),
      meaningID: serializer.fromJson<String>(json['meaningID']),
      wordAr: serializer.fromJson<String>(json['wordAr']),
      grammarFormDesc: serializer.fromJson<String>(json['grammarFormDesc']),
      chapterNo: serializer.fromJson<int>(json['chapterNo']),
      verseNo: serializer.fromJson<int>(json['verseNo']),
      wordNo: serializer.fromJson<int>(json['wordNo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rootAr': serializer.toJson<String>(rootAr),
      'rootEn': serializer.toJson<String>(rootEn),
      'meaningEn': serializer.toJson<String>(meaningEn),
      'meaningID': serializer.toJson<String>(meaningID),
      'wordAr': serializer.toJson<String>(wordAr),
      'grammarFormDesc': serializer.toJson<String>(grammarFormDesc),
      'chapterNo': serializer.toJson<int>(chapterNo),
      'verseNo': serializer.toJson<int>(verseNo),
      'wordNo': serializer.toJson<int>(wordNo),
    };
  }

  Grammar copyWith({
    String? rootAr,
    String? rootEn,
    String? meaningEn,
    String? meaningID,
    String? wordAr,
    String? grammarFormDesc,
    int? chapterNo,
    int? verseNo,
    int? wordNo,
  }) => Grammar(
    rootAr: rootAr ?? this.rootAr,
    rootEn: rootEn ?? this.rootEn,
    meaningEn: meaningEn ?? this.meaningEn,
    meaningID: meaningID ?? this.meaningID,
    wordAr: wordAr ?? this.wordAr,
    grammarFormDesc: grammarFormDesc ?? this.grammarFormDesc,
    chapterNo: chapterNo ?? this.chapterNo,
    verseNo: verseNo ?? this.verseNo,
    wordNo: wordNo ?? this.wordNo,
  );
  Grammar copyWithCompanion(GrammarTableCompanion data) {
    return Grammar(
      rootAr: data.rootAr.present ? data.rootAr.value : this.rootAr,
      rootEn: data.rootEn.present ? data.rootEn.value : this.rootEn,
      meaningEn: data.meaningEn.present ? data.meaningEn.value : this.meaningEn,
      meaningID: data.meaningID.present ? data.meaningID.value : this.meaningID,
      wordAr: data.wordAr.present ? data.wordAr.value : this.wordAr,
      grammarFormDesc:
          data.grammarFormDesc.present
              ? data.grammarFormDesc.value
              : this.grammarFormDesc,
      chapterNo: data.chapterNo.present ? data.chapterNo.value : this.chapterNo,
      verseNo: data.verseNo.present ? data.verseNo.value : this.verseNo,
      wordNo: data.wordNo.present ? data.wordNo.value : this.wordNo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Grammar(')
          ..write('rootAr: $rootAr, ')
          ..write('rootEn: $rootEn, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('meaningID: $meaningID, ')
          ..write('wordAr: $wordAr, ')
          ..write('grammarFormDesc: $grammarFormDesc, ')
          ..write('chapterNo: $chapterNo, ')
          ..write('verseNo: $verseNo, ')
          ..write('wordNo: $wordNo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rootAr,
    rootEn,
    meaningEn,
    meaningID,
    wordAr,
    grammarFormDesc,
    chapterNo,
    verseNo,
    wordNo,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grammar &&
          other.rootAr == this.rootAr &&
          other.rootEn == this.rootEn &&
          other.meaningEn == this.meaningEn &&
          other.meaningID == this.meaningID &&
          other.wordAr == this.wordAr &&
          other.grammarFormDesc == this.grammarFormDesc &&
          other.chapterNo == this.chapterNo &&
          other.verseNo == this.verseNo &&
          other.wordNo == this.wordNo);
}

class GrammarTableCompanion extends UpdateCompanion<Grammar> {
  final Value<String> rootAr;
  final Value<String> rootEn;
  final Value<String> meaningEn;
  final Value<String> meaningID;
  final Value<String> wordAr;
  final Value<String> grammarFormDesc;
  final Value<int> chapterNo;
  final Value<int> verseNo;
  final Value<int> wordNo;
  final Value<int> rowid;
  const GrammarTableCompanion({
    this.rootAr = const Value.absent(),
    this.rootEn = const Value.absent(),
    this.meaningEn = const Value.absent(),
    this.meaningID = const Value.absent(),
    this.wordAr = const Value.absent(),
    this.grammarFormDesc = const Value.absent(),
    this.chapterNo = const Value.absent(),
    this.verseNo = const Value.absent(),
    this.wordNo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarTableCompanion.insert({
    required String rootAr,
    required String rootEn,
    required String meaningEn,
    required String meaningID,
    required String wordAr,
    required String grammarFormDesc,
    required int chapterNo,
    required int verseNo,
    required int wordNo,
    this.rowid = const Value.absent(),
  }) : rootAr = Value(rootAr),
       rootEn = Value(rootEn),
       meaningEn = Value(meaningEn),
       meaningID = Value(meaningID),
       wordAr = Value(wordAr),
       grammarFormDesc = Value(grammarFormDesc),
       chapterNo = Value(chapterNo),
       verseNo = Value(verseNo),
       wordNo = Value(wordNo);
  static Insertable<Grammar> custom({
    Expression<String>? rootAr,
    Expression<String>? rootEn,
    Expression<String>? meaningEn,
    Expression<String>? meaningID,
    Expression<String>? wordAr,
    Expression<String>? grammarFormDesc,
    Expression<int>? chapterNo,
    Expression<int>? verseNo,
    Expression<int>? wordNo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rootAr != null) 'RootAr': rootAr,
      if (rootEn != null) 'RootEn': rootEn,
      if (meaningEn != null) 'MeaningEn': meaningEn,
      if (meaningID != null) 'MeaningID': meaningID,
      if (wordAr != null) 'WordAr': wordAr,
      if (grammarFormDesc != null) 'GrammarFormDesc': grammarFormDesc,
      if (chapterNo != null) 'ChapterNo': chapterNo,
      if (verseNo != null) 'VerseNo': verseNo,
      if (wordNo != null) 'WordNo': wordNo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarTableCompanion copyWith({
    Value<String>? rootAr,
    Value<String>? rootEn,
    Value<String>? meaningEn,
    Value<String>? meaningID,
    Value<String>? wordAr,
    Value<String>? grammarFormDesc,
    Value<int>? chapterNo,
    Value<int>? verseNo,
    Value<int>? wordNo,
    Value<int>? rowid,
  }) {
    return GrammarTableCompanion(
      rootAr: rootAr ?? this.rootAr,
      rootEn: rootEn ?? this.rootEn,
      meaningEn: meaningEn ?? this.meaningEn,
      meaningID: meaningID ?? this.meaningID,
      wordAr: wordAr ?? this.wordAr,
      grammarFormDesc: grammarFormDesc ?? this.grammarFormDesc,
      chapterNo: chapterNo ?? this.chapterNo,
      verseNo: verseNo ?? this.verseNo,
      wordNo: wordNo ?? this.wordNo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rootAr.present) {
      map['RootAr'] = Variable<String>(rootAr.value);
    }
    if (rootEn.present) {
      map['RootEn'] = Variable<String>(rootEn.value);
    }
    if (meaningEn.present) {
      map['MeaningEn'] = Variable<String>(meaningEn.value);
    }
    if (meaningID.present) {
      map['MeaningID'] = Variable<String>(meaningID.value);
    }
    if (wordAr.present) {
      map['WordAr'] = Variable<String>(wordAr.value);
    }
    if (grammarFormDesc.present) {
      map['GrammarFormDesc'] = Variable<String>(grammarFormDesc.value);
    }
    if (chapterNo.present) {
      map['ChapterNo'] = Variable<int>(chapterNo.value);
    }
    if (verseNo.present) {
      map['VerseNo'] = Variable<int>(verseNo.value);
    }
    if (wordNo.present) {
      map['WordNo'] = Variable<int>(wordNo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GrammarTableCompanion(')
          ..write('rootAr: $rootAr, ')
          ..write('rootEn: $rootEn, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('meaningID: $meaningID, ')
          ..write('wordAr: $wordAr, ')
          ..write('grammarFormDesc: $grammarFormDesc, ')
          ..write('chapterNo: $chapterNo, ')
          ..write('verseNo: $verseNo, ')
          ..write('wordNo: $wordNo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GrammarTableTable grammarTable = $GrammarTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [grammarTable];
}

typedef $$GrammarTableTableCreateCompanionBuilder =
    GrammarTableCompanion Function({
      required String rootAr,
      required String rootEn,
      required String meaningEn,
      required String meaningID,
      required String wordAr,
      required String grammarFormDesc,
      required int chapterNo,
      required int verseNo,
      required int wordNo,
      Value<int> rowid,
    });
typedef $$GrammarTableTableUpdateCompanionBuilder =
    GrammarTableCompanion Function({
      Value<String> rootAr,
      Value<String> rootEn,
      Value<String> meaningEn,
      Value<String> meaningID,
      Value<String> wordAr,
      Value<String> grammarFormDesc,
      Value<int> chapterNo,
      Value<int> verseNo,
      Value<int> wordNo,
      Value<int> rowid,
    });

class $$GrammarTableTableFilterComposer
    extends Composer<_$AppDatabase, $GrammarTableTable> {
  $$GrammarTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get rootAr => $composableBuilder(
    column: $table.rootAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootEn => $composableBuilder(
    column: $table.rootEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningID => $composableBuilder(
    column: $table.meaningID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordAr => $composableBuilder(
    column: $table.wordAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grammarFormDesc => $composableBuilder(
    column: $table.grammarFormDesc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterNo => $composableBuilder(
    column: $table.chapterNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verseNo => $composableBuilder(
    column: $table.verseNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordNo => $composableBuilder(
    column: $table.wordNo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GrammarTableTableOrderingComposer
    extends Composer<_$AppDatabase, $GrammarTableTable> {
  $$GrammarTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get rootAr => $composableBuilder(
    column: $table.rootAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootEn => $composableBuilder(
    column: $table.rootEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningID => $composableBuilder(
    column: $table.meaningID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordAr => $composableBuilder(
    column: $table.wordAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grammarFormDesc => $composableBuilder(
    column: $table.grammarFormDesc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterNo => $composableBuilder(
    column: $table.chapterNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verseNo => $composableBuilder(
    column: $table.verseNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordNo => $composableBuilder(
    column: $table.wordNo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GrammarTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $GrammarTableTable> {
  $$GrammarTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get rootAr =>
      $composableBuilder(column: $table.rootAr, builder: (column) => column);

  GeneratedColumn<String> get rootEn =>
      $composableBuilder(column: $table.rootEn, builder: (column) => column);

  GeneratedColumn<String> get meaningEn =>
      $composableBuilder(column: $table.meaningEn, builder: (column) => column);

  GeneratedColumn<String> get meaningID =>
      $composableBuilder(column: $table.meaningID, builder: (column) => column);

  GeneratedColumn<String> get wordAr =>
      $composableBuilder(column: $table.wordAr, builder: (column) => column);

  GeneratedColumn<String> get grammarFormDesc => $composableBuilder(
    column: $table.grammarFormDesc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chapterNo =>
      $composableBuilder(column: $table.chapterNo, builder: (column) => column);

  GeneratedColumn<int> get verseNo =>
      $composableBuilder(column: $table.verseNo, builder: (column) => column);

  GeneratedColumn<int> get wordNo =>
      $composableBuilder(column: $table.wordNo, builder: (column) => column);
}

class $$GrammarTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GrammarTableTable,
          Grammar,
          $$GrammarTableTableFilterComposer,
          $$GrammarTableTableOrderingComposer,
          $$GrammarTableTableAnnotationComposer,
          $$GrammarTableTableCreateCompanionBuilder,
          $$GrammarTableTableUpdateCompanionBuilder,
          (Grammar, BaseReferences<_$AppDatabase, $GrammarTableTable, Grammar>),
          Grammar,
          PrefetchHooks Function()
        > {
  $$GrammarTableTableTableManager(_$AppDatabase db, $GrammarTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$GrammarTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$GrammarTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$GrammarTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> rootAr = const Value.absent(),
                Value<String> rootEn = const Value.absent(),
                Value<String> meaningEn = const Value.absent(),
                Value<String> meaningID = const Value.absent(),
                Value<String> wordAr = const Value.absent(),
                Value<String> grammarFormDesc = const Value.absent(),
                Value<int> chapterNo = const Value.absent(),
                Value<int> verseNo = const Value.absent(),
                Value<int> wordNo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarTableCompanion(
                rootAr: rootAr,
                rootEn: rootEn,
                meaningEn: meaningEn,
                meaningID: meaningID,
                wordAr: wordAr,
                grammarFormDesc: grammarFormDesc,
                chapterNo: chapterNo,
                verseNo: verseNo,
                wordNo: wordNo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rootAr,
                required String rootEn,
                required String meaningEn,
                required String meaningID,
                required String wordAr,
                required String grammarFormDesc,
                required int chapterNo,
                required int verseNo,
                required int wordNo,
                Value<int> rowid = const Value.absent(),
              }) => GrammarTableCompanion.insert(
                rootAr: rootAr,
                rootEn: rootEn,
                meaningEn: meaningEn,
                meaningID: meaningID,
                wordAr: wordAr,
                grammarFormDesc: grammarFormDesc,
                chapterNo: chapterNo,
                verseNo: verseNo,
                wordNo: wordNo,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GrammarTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GrammarTableTable,
      Grammar,
      $$GrammarTableTableFilterComposer,
      $$GrammarTableTableOrderingComposer,
      $$GrammarTableTableAnnotationComposer,
      $$GrammarTableTableCreateCompanionBuilder,
      $$GrammarTableTableUpdateCompanionBuilder,
      (Grammar, BaseReferences<_$AppDatabase, $GrammarTableTable, Grammar>),
      Grammar,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GrammarTableTableTableManager get grammarTable =>
      $$GrammarTableTableTableManager(_db, _db.grammarTable);
}
