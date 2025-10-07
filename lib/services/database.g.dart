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
  static const VerificationMeta _rootCodeMeta = const VerificationMeta(
    'rootCode',
  );
  @override
  late final GeneratedColumn<String> rootCode = GeneratedColumn<String>(
    'RootCode',
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
  static const VerificationMeta _rootWordIdMeta = const VerificationMeta(
    'rootWordId',
  );
  @override
  late final GeneratedColumn<int> rootWordId = GeneratedColumn<int>(
    'RootWordId',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _wordArMeta = const VerificationMeta('wordAr');
  @override
  late final GeneratedColumn<String> wordAr = GeneratedColumn<String>(
    'WordAr',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _grammarFormDescIDMeta = const VerificationMeta(
    'grammarFormDescID',
  );
  @override
  late final GeneratedColumn<String> grammarFormDescID =
      GeneratedColumn<String>(
        'GrammarFormDescID',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    rootAr,
    rootCode,
    rootEn,
    rootWordId,
    chapterNo,
    meaningEn,
    verseNo,
    wordAr,
    wordNo,
    grammarFormDesc,
    meaningID,
    grammarFormDescID,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'grammar';
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
    if (data.containsKey('RootCode')) {
      context.handle(
        _rootCodeMeta,
        rootCode.isAcceptableOrUnknown(data['RootCode']!, _rootCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_rootCodeMeta);
    }
    if (data.containsKey('RootEn')) {
      context.handle(
        _rootEnMeta,
        rootEn.isAcceptableOrUnknown(data['RootEn']!, _rootEnMeta),
      );
    } else if (isInserting) {
      context.missing(_rootEnMeta);
    }
    if (data.containsKey('RootWordId')) {
      context.handle(
        _rootWordIdMeta,
        rootWordId.isAcceptableOrUnknown(data['RootWordId']!, _rootWordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rootWordIdMeta);
    }
    if (data.containsKey('ChapterNo')) {
      context.handle(
        _chapterNoMeta,
        chapterNo.isAcceptableOrUnknown(data['ChapterNo']!, _chapterNoMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterNoMeta);
    }
    if (data.containsKey('MeaningEn')) {
      context.handle(
        _meaningEnMeta,
        meaningEn.isAcceptableOrUnknown(data['MeaningEn']!, _meaningEnMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningEnMeta);
    }
    if (data.containsKey('VerseNo')) {
      context.handle(
        _verseNoMeta,
        verseNo.isAcceptableOrUnknown(data['VerseNo']!, _verseNoMeta),
      );
    } else if (isInserting) {
      context.missing(_verseNoMeta);
    }
    if (data.containsKey('WordAr')) {
      context.handle(
        _wordArMeta,
        wordAr.isAcceptableOrUnknown(data['WordAr']!, _wordArMeta),
      );
    } else if (isInserting) {
      context.missing(_wordArMeta);
    }
    if (data.containsKey('WordNo')) {
      context.handle(
        _wordNoMeta,
        wordNo.isAcceptableOrUnknown(data['WordNo']!, _wordNoMeta),
      );
    } else if (isInserting) {
      context.missing(_wordNoMeta);
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
    if (data.containsKey('MeaningID')) {
      context.handle(
        _meaningIDMeta,
        meaningID.isAcceptableOrUnknown(data['MeaningID']!, _meaningIDMeta),
      );
    } else if (isInserting) {
      context.missing(_meaningIDMeta);
    }
    if (data.containsKey('GrammarFormDescID')) {
      context.handle(
        _grammarFormDescIDMeta,
        grammarFormDescID.isAcceptableOrUnknown(
          data['GrammarFormDescID']!,
          _grammarFormDescIDMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_grammarFormDescIDMeta);
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
      rootCode:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}RootCode'],
          )!,
      rootEn:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}RootEn'],
          )!,
      rootWordId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}RootWordId'],
          )!,
      chapterNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}ChapterNo'],
          )!,
      meaningEn:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}MeaningEn'],
          )!,
      verseNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}VerseNo'],
          )!,
      wordAr:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}WordAr'],
          )!,
      wordNo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}WordNo'],
          )!,
      grammarFormDesc:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}GrammarFormDesc'],
          )!,
      meaningID:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}MeaningID'],
          )!,
      grammarFormDescID:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}GrammarFormDescID'],
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
  final String rootCode;
  final String rootEn;
  final int rootWordId;
  final int chapterNo;
  final String meaningEn;
  final int verseNo;
  final String wordAr;
  final int wordNo;
  final String grammarFormDesc;
  final String meaningID;
  final String grammarFormDescID;
  const Grammar({
    required this.rootAr,
    required this.rootCode,
    required this.rootEn,
    required this.rootWordId,
    required this.chapterNo,
    required this.meaningEn,
    required this.verseNo,
    required this.wordAr,
    required this.wordNo,
    required this.grammarFormDesc,
    required this.meaningID,
    required this.grammarFormDescID,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['RootAr'] = Variable<String>(rootAr);
    map['RootCode'] = Variable<String>(rootCode);
    map['RootEn'] = Variable<String>(rootEn);
    map['RootWordId'] = Variable<int>(rootWordId);
    map['ChapterNo'] = Variable<int>(chapterNo);
    map['MeaningEn'] = Variable<String>(meaningEn);
    map['VerseNo'] = Variable<int>(verseNo);
    map['WordAr'] = Variable<String>(wordAr);
    map['WordNo'] = Variable<int>(wordNo);
    map['GrammarFormDesc'] = Variable<String>(grammarFormDesc);
    map['MeaningID'] = Variable<String>(meaningID);
    map['GrammarFormDescID'] = Variable<String>(grammarFormDescID);
    return map;
  }

  GrammarTableCompanion toCompanion(bool nullToAbsent) {
    return GrammarTableCompanion(
      rootAr: Value(rootAr),
      rootCode: Value(rootCode),
      rootEn: Value(rootEn),
      rootWordId: Value(rootWordId),
      chapterNo: Value(chapterNo),
      meaningEn: Value(meaningEn),
      verseNo: Value(verseNo),
      wordAr: Value(wordAr),
      wordNo: Value(wordNo),
      grammarFormDesc: Value(grammarFormDesc),
      meaningID: Value(meaningID),
      grammarFormDescID: Value(grammarFormDescID),
    );
  }

  factory Grammar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grammar(
      rootAr: serializer.fromJson<String>(json['rootAr']),
      rootCode: serializer.fromJson<String>(json['rootCode']),
      rootEn: serializer.fromJson<String>(json['rootEn']),
      rootWordId: serializer.fromJson<int>(json['rootWordId']),
      chapterNo: serializer.fromJson<int>(json['chapterNo']),
      meaningEn: serializer.fromJson<String>(json['meaningEn']),
      verseNo: serializer.fromJson<int>(json['verseNo']),
      wordAr: serializer.fromJson<String>(json['wordAr']),
      wordNo: serializer.fromJson<int>(json['wordNo']),
      grammarFormDesc: serializer.fromJson<String>(json['grammarFormDesc']),
      meaningID: serializer.fromJson<String>(json['meaningID']),
      grammarFormDescID: serializer.fromJson<String>(json['grammarFormDescID']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'rootAr': serializer.toJson<String>(rootAr),
      'rootCode': serializer.toJson<String>(rootCode),
      'rootEn': serializer.toJson<String>(rootEn),
      'rootWordId': serializer.toJson<int>(rootWordId),
      'chapterNo': serializer.toJson<int>(chapterNo),
      'meaningEn': serializer.toJson<String>(meaningEn),
      'verseNo': serializer.toJson<int>(verseNo),
      'wordAr': serializer.toJson<String>(wordAr),
      'wordNo': serializer.toJson<int>(wordNo),
      'grammarFormDesc': serializer.toJson<String>(grammarFormDesc),
      'meaningID': serializer.toJson<String>(meaningID),
      'grammarFormDescID': serializer.toJson<String>(grammarFormDescID),
    };
  }

  Grammar copyWith({
    String? rootAr,
    String? rootCode,
    String? rootEn,
    int? rootWordId,
    int? chapterNo,
    String? meaningEn,
    int? verseNo,
    String? wordAr,
    int? wordNo,
    String? grammarFormDesc,
    String? meaningID,
    String? grammarFormDescID,
  }) => Grammar(
    rootAr: rootAr ?? this.rootAr,
    rootCode: rootCode ?? this.rootCode,
    rootEn: rootEn ?? this.rootEn,
    rootWordId: rootWordId ?? this.rootWordId,
    chapterNo: chapterNo ?? this.chapterNo,
    meaningEn: meaningEn ?? this.meaningEn,
    verseNo: verseNo ?? this.verseNo,
    wordAr: wordAr ?? this.wordAr,
    wordNo: wordNo ?? this.wordNo,
    grammarFormDesc: grammarFormDesc ?? this.grammarFormDesc,
    meaningID: meaningID ?? this.meaningID,
    grammarFormDescID: grammarFormDescID ?? this.grammarFormDescID,
  );
  Grammar copyWithCompanion(GrammarTableCompanion data) {
    return Grammar(
      rootAr: data.rootAr.present ? data.rootAr.value : this.rootAr,
      rootCode: data.rootCode.present ? data.rootCode.value : this.rootCode,
      rootEn: data.rootEn.present ? data.rootEn.value : this.rootEn,
      rootWordId:
          data.rootWordId.present ? data.rootWordId.value : this.rootWordId,
      chapterNo: data.chapterNo.present ? data.chapterNo.value : this.chapterNo,
      meaningEn: data.meaningEn.present ? data.meaningEn.value : this.meaningEn,
      verseNo: data.verseNo.present ? data.verseNo.value : this.verseNo,
      wordAr: data.wordAr.present ? data.wordAr.value : this.wordAr,
      wordNo: data.wordNo.present ? data.wordNo.value : this.wordNo,
      grammarFormDesc:
          data.grammarFormDesc.present
              ? data.grammarFormDesc.value
              : this.grammarFormDesc,
      meaningID: data.meaningID.present ? data.meaningID.value : this.meaningID,
      grammarFormDescID:
          data.grammarFormDescID.present
              ? data.grammarFormDescID.value
              : this.grammarFormDescID,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Grammar(')
          ..write('rootAr: $rootAr, ')
          ..write('rootCode: $rootCode, ')
          ..write('rootEn: $rootEn, ')
          ..write('rootWordId: $rootWordId, ')
          ..write('chapterNo: $chapterNo, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('verseNo: $verseNo, ')
          ..write('wordAr: $wordAr, ')
          ..write('wordNo: $wordNo, ')
          ..write('grammarFormDesc: $grammarFormDesc, ')
          ..write('meaningID: $meaningID, ')
          ..write('grammarFormDescID: $grammarFormDescID')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    rootAr,
    rootCode,
    rootEn,
    rootWordId,
    chapterNo,
    meaningEn,
    verseNo,
    wordAr,
    wordNo,
    grammarFormDesc,
    meaningID,
    grammarFormDescID,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grammar &&
          other.rootAr == this.rootAr &&
          other.rootCode == this.rootCode &&
          other.rootEn == this.rootEn &&
          other.rootWordId == this.rootWordId &&
          other.chapterNo == this.chapterNo &&
          other.meaningEn == this.meaningEn &&
          other.verseNo == this.verseNo &&
          other.wordAr == this.wordAr &&
          other.wordNo == this.wordNo &&
          other.grammarFormDesc == this.grammarFormDesc &&
          other.meaningID == this.meaningID &&
          other.grammarFormDescID == this.grammarFormDescID);
}

class GrammarTableCompanion extends UpdateCompanion<Grammar> {
  final Value<String> rootAr;
  final Value<String> rootCode;
  final Value<String> rootEn;
  final Value<int> rootWordId;
  final Value<int> chapterNo;
  final Value<String> meaningEn;
  final Value<int> verseNo;
  final Value<String> wordAr;
  final Value<int> wordNo;
  final Value<String> grammarFormDesc;
  final Value<String> meaningID;
  final Value<String> grammarFormDescID;
  final Value<int> rowid;
  const GrammarTableCompanion({
    this.rootAr = const Value.absent(),
    this.rootCode = const Value.absent(),
    this.rootEn = const Value.absent(),
    this.rootWordId = const Value.absent(),
    this.chapterNo = const Value.absent(),
    this.meaningEn = const Value.absent(),
    this.verseNo = const Value.absent(),
    this.wordAr = const Value.absent(),
    this.wordNo = const Value.absent(),
    this.grammarFormDesc = const Value.absent(),
    this.meaningID = const Value.absent(),
    this.grammarFormDescID = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarTableCompanion.insert({
    required String rootAr,
    required String rootCode,
    required String rootEn,
    required int rootWordId,
    required int chapterNo,
    required String meaningEn,
    required int verseNo,
    required String wordAr,
    required int wordNo,
    required String grammarFormDesc,
    required String meaningID,
    required String grammarFormDescID,
    this.rowid = const Value.absent(),
  }) : rootAr = Value(rootAr),
       rootCode = Value(rootCode),
       rootEn = Value(rootEn),
       rootWordId = Value(rootWordId),
       chapterNo = Value(chapterNo),
       meaningEn = Value(meaningEn),
       verseNo = Value(verseNo),
       wordAr = Value(wordAr),
       wordNo = Value(wordNo),
       grammarFormDesc = Value(grammarFormDesc),
       meaningID = Value(meaningID),
       grammarFormDescID = Value(grammarFormDescID);
  static Insertable<Grammar> custom({
    Expression<String>? rootAr,
    Expression<String>? rootCode,
    Expression<String>? rootEn,
    Expression<int>? rootWordId,
    Expression<int>? chapterNo,
    Expression<String>? meaningEn,
    Expression<int>? verseNo,
    Expression<String>? wordAr,
    Expression<int>? wordNo,
    Expression<String>? grammarFormDesc,
    Expression<String>? meaningID,
    Expression<String>? grammarFormDescID,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (rootAr != null) 'RootAr': rootAr,
      if (rootCode != null) 'RootCode': rootCode,
      if (rootEn != null) 'RootEn': rootEn,
      if (rootWordId != null) 'RootWordId': rootWordId,
      if (chapterNo != null) 'ChapterNo': chapterNo,
      if (meaningEn != null) 'MeaningEn': meaningEn,
      if (verseNo != null) 'VerseNo': verseNo,
      if (wordAr != null) 'WordAr': wordAr,
      if (wordNo != null) 'WordNo': wordNo,
      if (grammarFormDesc != null) 'GrammarFormDesc': grammarFormDesc,
      if (meaningID != null) 'MeaningID': meaningID,
      if (grammarFormDescID != null) 'GrammarFormDescID': grammarFormDescID,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarTableCompanion copyWith({
    Value<String>? rootAr,
    Value<String>? rootCode,
    Value<String>? rootEn,
    Value<int>? rootWordId,
    Value<int>? chapterNo,
    Value<String>? meaningEn,
    Value<int>? verseNo,
    Value<String>? wordAr,
    Value<int>? wordNo,
    Value<String>? grammarFormDesc,
    Value<String>? meaningID,
    Value<String>? grammarFormDescID,
    Value<int>? rowid,
  }) {
    return GrammarTableCompanion(
      rootAr: rootAr ?? this.rootAr,
      rootCode: rootCode ?? this.rootCode,
      rootEn: rootEn ?? this.rootEn,
      rootWordId: rootWordId ?? this.rootWordId,
      chapterNo: chapterNo ?? this.chapterNo,
      meaningEn: meaningEn ?? this.meaningEn,
      verseNo: verseNo ?? this.verseNo,
      wordAr: wordAr ?? this.wordAr,
      wordNo: wordNo ?? this.wordNo,
      grammarFormDesc: grammarFormDesc ?? this.grammarFormDesc,
      meaningID: meaningID ?? this.meaningID,
      grammarFormDescID: grammarFormDescID ?? this.grammarFormDescID,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (rootAr.present) {
      map['RootAr'] = Variable<String>(rootAr.value);
    }
    if (rootCode.present) {
      map['RootCode'] = Variable<String>(rootCode.value);
    }
    if (rootEn.present) {
      map['RootEn'] = Variable<String>(rootEn.value);
    }
    if (rootWordId.present) {
      map['RootWordId'] = Variable<int>(rootWordId.value);
    }
    if (chapterNo.present) {
      map['ChapterNo'] = Variable<int>(chapterNo.value);
    }
    if (meaningEn.present) {
      map['MeaningEn'] = Variable<String>(meaningEn.value);
    }
    if (verseNo.present) {
      map['VerseNo'] = Variable<int>(verseNo.value);
    }
    if (wordAr.present) {
      map['WordAr'] = Variable<String>(wordAr.value);
    }
    if (wordNo.present) {
      map['WordNo'] = Variable<int>(wordNo.value);
    }
    if (grammarFormDesc.present) {
      map['GrammarFormDesc'] = Variable<String>(grammarFormDesc.value);
    }
    if (meaningID.present) {
      map['MeaningID'] = Variable<String>(meaningID.value);
    }
    if (grammarFormDescID.present) {
      map['GrammarFormDescID'] = Variable<String>(grammarFormDescID.value);
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
          ..write('rootCode: $rootCode, ')
          ..write('rootEn: $rootEn, ')
          ..write('rootWordId: $rootWordId, ')
          ..write('chapterNo: $chapterNo, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('verseNo: $verseNo, ')
          ..write('wordAr: $wordAr, ')
          ..write('wordNo: $wordNo, ')
          ..write('grammarFormDesc: $grammarFormDesc, ')
          ..write('meaningID: $meaningID, ')
          ..write('grammarFormDescID: $grammarFormDescID, ')
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
      required String rootCode,
      required String rootEn,
      required int rootWordId,
      required int chapterNo,
      required String meaningEn,
      required int verseNo,
      required String wordAr,
      required int wordNo,
      required String grammarFormDesc,
      required String meaningID,
      required String grammarFormDescID,
      Value<int> rowid,
    });
typedef $$GrammarTableTableUpdateCompanionBuilder =
    GrammarTableCompanion Function({
      Value<String> rootAr,
      Value<String> rootCode,
      Value<String> rootEn,
      Value<int> rootWordId,
      Value<int> chapterNo,
      Value<String> meaningEn,
      Value<int> verseNo,
      Value<String> wordAr,
      Value<int> wordNo,
      Value<String> grammarFormDesc,
      Value<String> meaningID,
      Value<String> grammarFormDescID,
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

  ColumnFilters<String> get rootCode => $composableBuilder(
    column: $table.rootCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rootEn => $composableBuilder(
    column: $table.rootEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rootWordId => $composableBuilder(
    column: $table.rootWordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapterNo => $composableBuilder(
    column: $table.chapterNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verseNo => $composableBuilder(
    column: $table.verseNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wordAr => $composableBuilder(
    column: $table.wordAr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wordNo => $composableBuilder(
    column: $table.wordNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grammarFormDesc => $composableBuilder(
    column: $table.grammarFormDesc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaningID => $composableBuilder(
    column: $table.meaningID,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grammarFormDescID => $composableBuilder(
    column: $table.grammarFormDescID,
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

  ColumnOrderings<String> get rootCode => $composableBuilder(
    column: $table.rootCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rootEn => $composableBuilder(
    column: $table.rootEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rootWordId => $composableBuilder(
    column: $table.rootWordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapterNo => $composableBuilder(
    column: $table.chapterNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verseNo => $composableBuilder(
    column: $table.verseNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wordAr => $composableBuilder(
    column: $table.wordAr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wordNo => $composableBuilder(
    column: $table.wordNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grammarFormDesc => $composableBuilder(
    column: $table.grammarFormDesc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaningID => $composableBuilder(
    column: $table.meaningID,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grammarFormDescID => $composableBuilder(
    column: $table.grammarFormDescID,
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

  GeneratedColumn<String> get rootCode =>
      $composableBuilder(column: $table.rootCode, builder: (column) => column);

  GeneratedColumn<String> get rootEn =>
      $composableBuilder(column: $table.rootEn, builder: (column) => column);

  GeneratedColumn<int> get rootWordId => $composableBuilder(
    column: $table.rootWordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get chapterNo =>
      $composableBuilder(column: $table.chapterNo, builder: (column) => column);

  GeneratedColumn<String> get meaningEn =>
      $composableBuilder(column: $table.meaningEn, builder: (column) => column);

  GeneratedColumn<int> get verseNo =>
      $composableBuilder(column: $table.verseNo, builder: (column) => column);

  GeneratedColumn<String> get wordAr =>
      $composableBuilder(column: $table.wordAr, builder: (column) => column);

  GeneratedColumn<int> get wordNo =>
      $composableBuilder(column: $table.wordNo, builder: (column) => column);

  GeneratedColumn<String> get grammarFormDesc => $composableBuilder(
    column: $table.grammarFormDesc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaningID =>
      $composableBuilder(column: $table.meaningID, builder: (column) => column);

  GeneratedColumn<String> get grammarFormDescID => $composableBuilder(
    column: $table.grammarFormDescID,
    builder: (column) => column,
  );
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
                Value<String> rootCode = const Value.absent(),
                Value<String> rootEn = const Value.absent(),
                Value<int> rootWordId = const Value.absent(),
                Value<int> chapterNo = const Value.absent(),
                Value<String> meaningEn = const Value.absent(),
                Value<int> verseNo = const Value.absent(),
                Value<String> wordAr = const Value.absent(),
                Value<int> wordNo = const Value.absent(),
                Value<String> grammarFormDesc = const Value.absent(),
                Value<String> meaningID = const Value.absent(),
                Value<String> grammarFormDescID = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarTableCompanion(
                rootAr: rootAr,
                rootCode: rootCode,
                rootEn: rootEn,
                rootWordId: rootWordId,
                chapterNo: chapterNo,
                meaningEn: meaningEn,
                verseNo: verseNo,
                wordAr: wordAr,
                wordNo: wordNo,
                grammarFormDesc: grammarFormDesc,
                meaningID: meaningID,
                grammarFormDescID: grammarFormDescID,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String rootAr,
                required String rootCode,
                required String rootEn,
                required int rootWordId,
                required int chapterNo,
                required String meaningEn,
                required int verseNo,
                required String wordAr,
                required int wordNo,
                required String grammarFormDesc,
                required String meaningID,
                required String grammarFormDescID,
                Value<int> rowid = const Value.absent(),
              }) => GrammarTableCompanion.insert(
                rootAr: rootAr,
                rootCode: rootCode,
                rootEn: rootEn,
                rootWordId: rootWordId,
                chapterNo: chapterNo,
                meaningEn: meaningEn,
                verseNo: verseNo,
                wordAr: wordAr,
                wordNo: wordNo,
                grammarFormDesc: grammarFormDesc,
                meaningID: meaningID,
                grammarFormDescID: grammarFormDescID,
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
