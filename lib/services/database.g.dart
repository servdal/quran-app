// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GrammarTableTable extends GrammarTable
    with TableInfo<$GrammarTableTable, Grammar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GrammarTableTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _rootArMeta = const VerificationMeta('rootAr');
  @override
  late final GeneratedColumn<String> rootAr = GeneratedColumn<String>(
    'RootAr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootCodeMeta = const VerificationMeta(
    'rootCode',
  );
  @override
  late final GeneratedColumn<String> rootCode = GeneratedColumn<String>(
    'RootCode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootEnMeta = const VerificationMeta('rootEn');
  @override
  late final GeneratedColumn<String> rootEn = GeneratedColumn<String>(
    'RootEn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rootWordIdMeta = const VerificationMeta(
    'rootWordId',
  );
  @override
  late final GeneratedColumn<int> rootWordId = GeneratedColumn<int>(
    'RootWordId',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningEnMeta = const VerificationMeta(
    'meaningEn',
  );
  @override
  late final GeneratedColumn<String> meaningEn = GeneratedColumn<String>(
    'MeaningEn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wordArMeta = const VerificationMeta('wordAr');
  @override
  late final GeneratedColumn<String> wordAr = GeneratedColumn<String>(
    'WordAr',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grammarFormDescMeta = const VerificationMeta(
    'grammarFormDesc',
  );
  @override
  late final GeneratedColumn<String> grammarFormDesc = GeneratedColumn<String>(
    'GrammarFormDesc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _meaningIDMeta = const VerificationMeta(
    'meaningID',
  );
  @override
  late final GeneratedColumn<String> meaningID = GeneratedColumn<String>(
    'MeaningID',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _grammarFormDescIDMeta = const VerificationMeta(
    'grammarFormDescID',
  );
  @override
  late final GeneratedColumn<String> grammarFormDescID =
      GeneratedColumn<String>(
        'GrammarFormDescID',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    chapterNo,
    verseNo,
    wordNo,
    rootAr,
    rootCode,
    rootEn,
    rootWordId,
    meaningEn,
    wordAr,
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
    if (data.containsKey('RootAr')) {
      context.handle(
        _rootArMeta,
        rootAr.isAcceptableOrUnknown(data['RootAr']!, _rootArMeta),
      );
    }
    if (data.containsKey('RootCode')) {
      context.handle(
        _rootCodeMeta,
        rootCode.isAcceptableOrUnknown(data['RootCode']!, _rootCodeMeta),
      );
    }
    if (data.containsKey('RootEn')) {
      context.handle(
        _rootEnMeta,
        rootEn.isAcceptableOrUnknown(data['RootEn']!, _rootEnMeta),
      );
    }
    if (data.containsKey('RootWordId')) {
      context.handle(
        _rootWordIdMeta,
        rootWordId.isAcceptableOrUnknown(data['RootWordId']!, _rootWordIdMeta),
      );
    }
    if (data.containsKey('MeaningEn')) {
      context.handle(
        _meaningEnMeta,
        meaningEn.isAcceptableOrUnknown(data['MeaningEn']!, _meaningEnMeta),
      );
    }
    if (data.containsKey('WordAr')) {
      context.handle(
        _wordArMeta,
        wordAr.isAcceptableOrUnknown(data['WordAr']!, _wordArMeta),
      );
    }
    if (data.containsKey('GrammarFormDesc')) {
      context.handle(
        _grammarFormDescMeta,
        grammarFormDesc.isAcceptableOrUnknown(
          data['GrammarFormDesc']!,
          _grammarFormDescMeta,
        ),
      );
    }
    if (data.containsKey('MeaningID')) {
      context.handle(
        _meaningIDMeta,
        meaningID.isAcceptableOrUnknown(data['MeaningID']!, _meaningIDMeta),
      );
    }
    if (data.containsKey('GrammarFormDescID')) {
      context.handle(
        _grammarFormDescIDMeta,
        grammarFormDescID.isAcceptableOrUnknown(
          data['GrammarFormDescID']!,
          _grammarFormDescIDMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chapterNo, verseNo, wordNo};
  @override
  Grammar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Grammar(
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
      rootAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}RootAr'],
      ),
      rootCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}RootCode'],
      ),
      rootEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}RootEn'],
      ),
      rootWordId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}RootWordId'],
      ),
      meaningEn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MeaningEn'],
      ),
      wordAr: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}WordAr'],
      ),
      grammarFormDesc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}GrammarFormDesc'],
      ),
      meaningID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}MeaningID'],
      ),
      grammarFormDescID: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}GrammarFormDescID'],
      ),
    );
  }

  @override
  $GrammarTableTable createAlias(String alias) {
    return $GrammarTableTable(attachedDatabase, alias);
  }
}

class Grammar extends DataClass implements Insertable<Grammar> {
  final int chapterNo;
  final int verseNo;
  final int wordNo;
  final String? rootAr;
  final String? rootCode;
  final String? rootEn;
  final int? rootWordId;
  final String? meaningEn;
  final String? wordAr;
  final String? grammarFormDesc;
  final String? meaningID;
  final String? grammarFormDescID;
  const Grammar({
    required this.chapterNo,
    required this.verseNo,
    required this.wordNo,
    this.rootAr,
    this.rootCode,
    this.rootEn,
    this.rootWordId,
    this.meaningEn,
    this.wordAr,
    this.grammarFormDesc,
    this.meaningID,
    this.grammarFormDescID,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ChapterNo'] = Variable<int>(chapterNo);
    map['VerseNo'] = Variable<int>(verseNo);
    map['WordNo'] = Variable<int>(wordNo);
    if (!nullToAbsent || rootAr != null) {
      map['RootAr'] = Variable<String>(rootAr);
    }
    if (!nullToAbsent || rootCode != null) {
      map['RootCode'] = Variable<String>(rootCode);
    }
    if (!nullToAbsent || rootEn != null) {
      map['RootEn'] = Variable<String>(rootEn);
    }
    if (!nullToAbsent || rootWordId != null) {
      map['RootWordId'] = Variable<int>(rootWordId);
    }
    if (!nullToAbsent || meaningEn != null) {
      map['MeaningEn'] = Variable<String>(meaningEn);
    }
    if (!nullToAbsent || wordAr != null) {
      map['WordAr'] = Variable<String>(wordAr);
    }
    if (!nullToAbsent || grammarFormDesc != null) {
      map['GrammarFormDesc'] = Variable<String>(grammarFormDesc);
    }
    if (!nullToAbsent || meaningID != null) {
      map['MeaningID'] = Variable<String>(meaningID);
    }
    if (!nullToAbsent || grammarFormDescID != null) {
      map['GrammarFormDescID'] = Variable<String>(grammarFormDescID);
    }
    return map;
  }

  GrammarTableCompanion toCompanion(bool nullToAbsent) {
    return GrammarTableCompanion(
      chapterNo: Value(chapterNo),
      verseNo: Value(verseNo),
      wordNo: Value(wordNo),
      rootAr:
          rootAr == null && nullToAbsent ? const Value.absent() : Value(rootAr),
      rootCode:
          rootCode == null && nullToAbsent
              ? const Value.absent()
              : Value(rootCode),
      rootEn:
          rootEn == null && nullToAbsent ? const Value.absent() : Value(rootEn),
      rootWordId:
          rootWordId == null && nullToAbsent
              ? const Value.absent()
              : Value(rootWordId),
      meaningEn:
          meaningEn == null && nullToAbsent
              ? const Value.absent()
              : Value(meaningEn),
      wordAr:
          wordAr == null && nullToAbsent ? const Value.absent() : Value(wordAr),
      grammarFormDesc:
          grammarFormDesc == null && nullToAbsent
              ? const Value.absent()
              : Value(grammarFormDesc),
      meaningID:
          meaningID == null && nullToAbsent
              ? const Value.absent()
              : Value(meaningID),
      grammarFormDescID:
          grammarFormDescID == null && nullToAbsent
              ? const Value.absent()
              : Value(grammarFormDescID),
    );
  }

  factory Grammar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Grammar(
      chapterNo: serializer.fromJson<int>(json['chapterNo']),
      verseNo: serializer.fromJson<int>(json['verseNo']),
      wordNo: serializer.fromJson<int>(json['wordNo']),
      rootAr: serializer.fromJson<String?>(json['rootAr']),
      rootCode: serializer.fromJson<String?>(json['rootCode']),
      rootEn: serializer.fromJson<String?>(json['rootEn']),
      rootWordId: serializer.fromJson<int?>(json['rootWordId']),
      meaningEn: serializer.fromJson<String?>(json['meaningEn']),
      wordAr: serializer.fromJson<String?>(json['wordAr']),
      grammarFormDesc: serializer.fromJson<String?>(json['grammarFormDesc']),
      meaningID: serializer.fromJson<String?>(json['meaningID']),
      grammarFormDescID: serializer.fromJson<String?>(
        json['grammarFormDescID'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chapterNo': serializer.toJson<int>(chapterNo),
      'verseNo': serializer.toJson<int>(verseNo),
      'wordNo': serializer.toJson<int>(wordNo),
      'rootAr': serializer.toJson<String?>(rootAr),
      'rootCode': serializer.toJson<String?>(rootCode),
      'rootEn': serializer.toJson<String?>(rootEn),
      'rootWordId': serializer.toJson<int?>(rootWordId),
      'meaningEn': serializer.toJson<String?>(meaningEn),
      'wordAr': serializer.toJson<String?>(wordAr),
      'grammarFormDesc': serializer.toJson<String?>(grammarFormDesc),
      'meaningID': serializer.toJson<String?>(meaningID),
      'grammarFormDescID': serializer.toJson<String?>(grammarFormDescID),
    };
  }

  Grammar copyWith({
    int? chapterNo,
    int? verseNo,
    int? wordNo,
    Value<String?> rootAr = const Value.absent(),
    Value<String?> rootCode = const Value.absent(),
    Value<String?> rootEn = const Value.absent(),
    Value<int?> rootWordId = const Value.absent(),
    Value<String?> meaningEn = const Value.absent(),
    Value<String?> wordAr = const Value.absent(),
    Value<String?> grammarFormDesc = const Value.absent(),
    Value<String?> meaningID = const Value.absent(),
    Value<String?> grammarFormDescID = const Value.absent(),
  }) => Grammar(
    chapterNo: chapterNo ?? this.chapterNo,
    verseNo: verseNo ?? this.verseNo,
    wordNo: wordNo ?? this.wordNo,
    rootAr: rootAr.present ? rootAr.value : this.rootAr,
    rootCode: rootCode.present ? rootCode.value : this.rootCode,
    rootEn: rootEn.present ? rootEn.value : this.rootEn,
    rootWordId: rootWordId.present ? rootWordId.value : this.rootWordId,
    meaningEn: meaningEn.present ? meaningEn.value : this.meaningEn,
    wordAr: wordAr.present ? wordAr.value : this.wordAr,
    grammarFormDesc:
        grammarFormDesc.present ? grammarFormDesc.value : this.grammarFormDesc,
    meaningID: meaningID.present ? meaningID.value : this.meaningID,
    grammarFormDescID:
        grammarFormDescID.present
            ? grammarFormDescID.value
            : this.grammarFormDescID,
  );
  Grammar copyWithCompanion(GrammarTableCompanion data) {
    return Grammar(
      chapterNo: data.chapterNo.present ? data.chapterNo.value : this.chapterNo,
      verseNo: data.verseNo.present ? data.verseNo.value : this.verseNo,
      wordNo: data.wordNo.present ? data.wordNo.value : this.wordNo,
      rootAr: data.rootAr.present ? data.rootAr.value : this.rootAr,
      rootCode: data.rootCode.present ? data.rootCode.value : this.rootCode,
      rootEn: data.rootEn.present ? data.rootEn.value : this.rootEn,
      rootWordId:
          data.rootWordId.present ? data.rootWordId.value : this.rootWordId,
      meaningEn: data.meaningEn.present ? data.meaningEn.value : this.meaningEn,
      wordAr: data.wordAr.present ? data.wordAr.value : this.wordAr,
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
          ..write('chapterNo: $chapterNo, ')
          ..write('verseNo: $verseNo, ')
          ..write('wordNo: $wordNo, ')
          ..write('rootAr: $rootAr, ')
          ..write('rootCode: $rootCode, ')
          ..write('rootEn: $rootEn, ')
          ..write('rootWordId: $rootWordId, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('wordAr: $wordAr, ')
          ..write('grammarFormDesc: $grammarFormDesc, ')
          ..write('meaningID: $meaningID, ')
          ..write('grammarFormDescID: $grammarFormDescID')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    chapterNo,
    verseNo,
    wordNo,
    rootAr,
    rootCode,
    rootEn,
    rootWordId,
    meaningEn,
    wordAr,
    grammarFormDesc,
    meaningID,
    grammarFormDescID,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Grammar &&
          other.chapterNo == this.chapterNo &&
          other.verseNo == this.verseNo &&
          other.wordNo == this.wordNo &&
          other.rootAr == this.rootAr &&
          other.rootCode == this.rootCode &&
          other.rootEn == this.rootEn &&
          other.rootWordId == this.rootWordId &&
          other.meaningEn == this.meaningEn &&
          other.wordAr == this.wordAr &&
          other.grammarFormDesc == this.grammarFormDesc &&
          other.meaningID == this.meaningID &&
          other.grammarFormDescID == this.grammarFormDescID);
}

class GrammarTableCompanion extends UpdateCompanion<Grammar> {
  final Value<int> chapterNo;
  final Value<int> verseNo;
  final Value<int> wordNo;
  final Value<String?> rootAr;
  final Value<String?> rootCode;
  final Value<String?> rootEn;
  final Value<int?> rootWordId;
  final Value<String?> meaningEn;
  final Value<String?> wordAr;
  final Value<String?> grammarFormDesc;
  final Value<String?> meaningID;
  final Value<String?> grammarFormDescID;
  final Value<int> rowid;
  const GrammarTableCompanion({
    this.chapterNo = const Value.absent(),
    this.verseNo = const Value.absent(),
    this.wordNo = const Value.absent(),
    this.rootAr = const Value.absent(),
    this.rootCode = const Value.absent(),
    this.rootEn = const Value.absent(),
    this.rootWordId = const Value.absent(),
    this.meaningEn = const Value.absent(),
    this.wordAr = const Value.absent(),
    this.grammarFormDesc = const Value.absent(),
    this.meaningID = const Value.absent(),
    this.grammarFormDescID = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GrammarTableCompanion.insert({
    required int chapterNo,
    required int verseNo,
    required int wordNo,
    this.rootAr = const Value.absent(),
    this.rootCode = const Value.absent(),
    this.rootEn = const Value.absent(),
    this.rootWordId = const Value.absent(),
    this.meaningEn = const Value.absent(),
    this.wordAr = const Value.absent(),
    this.grammarFormDesc = const Value.absent(),
    this.meaningID = const Value.absent(),
    this.grammarFormDescID = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : chapterNo = Value(chapterNo),
       verseNo = Value(verseNo),
       wordNo = Value(wordNo);
  static Insertable<Grammar> custom({
    Expression<int>? chapterNo,
    Expression<int>? verseNo,
    Expression<int>? wordNo,
    Expression<String>? rootAr,
    Expression<String>? rootCode,
    Expression<String>? rootEn,
    Expression<int>? rootWordId,
    Expression<String>? meaningEn,
    Expression<String>? wordAr,
    Expression<String>? grammarFormDesc,
    Expression<String>? meaningID,
    Expression<String>? grammarFormDescID,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chapterNo != null) 'ChapterNo': chapterNo,
      if (verseNo != null) 'VerseNo': verseNo,
      if (wordNo != null) 'WordNo': wordNo,
      if (rootAr != null) 'RootAr': rootAr,
      if (rootCode != null) 'RootCode': rootCode,
      if (rootEn != null) 'RootEn': rootEn,
      if (rootWordId != null) 'RootWordId': rootWordId,
      if (meaningEn != null) 'MeaningEn': meaningEn,
      if (wordAr != null) 'WordAr': wordAr,
      if (grammarFormDesc != null) 'GrammarFormDesc': grammarFormDesc,
      if (meaningID != null) 'MeaningID': meaningID,
      if (grammarFormDescID != null) 'GrammarFormDescID': grammarFormDescID,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GrammarTableCompanion copyWith({
    Value<int>? chapterNo,
    Value<int>? verseNo,
    Value<int>? wordNo,
    Value<String?>? rootAr,
    Value<String?>? rootCode,
    Value<String?>? rootEn,
    Value<int?>? rootWordId,
    Value<String?>? meaningEn,
    Value<String?>? wordAr,
    Value<String?>? grammarFormDesc,
    Value<String?>? meaningID,
    Value<String?>? grammarFormDescID,
    Value<int>? rowid,
  }) {
    return GrammarTableCompanion(
      chapterNo: chapterNo ?? this.chapterNo,
      verseNo: verseNo ?? this.verseNo,
      wordNo: wordNo ?? this.wordNo,
      rootAr: rootAr ?? this.rootAr,
      rootCode: rootCode ?? this.rootCode,
      rootEn: rootEn ?? this.rootEn,
      rootWordId: rootWordId ?? this.rootWordId,
      meaningEn: meaningEn ?? this.meaningEn,
      wordAr: wordAr ?? this.wordAr,
      grammarFormDesc: grammarFormDesc ?? this.grammarFormDesc,
      meaningID: meaningID ?? this.meaningID,
      grammarFormDescID: grammarFormDescID ?? this.grammarFormDescID,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chapterNo.present) {
      map['ChapterNo'] = Variable<int>(chapterNo.value);
    }
    if (verseNo.present) {
      map['VerseNo'] = Variable<int>(verseNo.value);
    }
    if (wordNo.present) {
      map['WordNo'] = Variable<int>(wordNo.value);
    }
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
    if (meaningEn.present) {
      map['MeaningEn'] = Variable<String>(meaningEn.value);
    }
    if (wordAr.present) {
      map['WordAr'] = Variable<String>(wordAr.value);
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
          ..write('chapterNo: $chapterNo, ')
          ..write('verseNo: $verseNo, ')
          ..write('wordNo: $wordNo, ')
          ..write('rootAr: $rootAr, ')
          ..write('rootCode: $rootCode, ')
          ..write('rootEn: $rootEn, ')
          ..write('rootWordId: $rootWordId, ')
          ..write('meaningEn: $meaningEn, ')
          ..write('wordAr: $wordAr, ')
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
      required int chapterNo,
      required int verseNo,
      required int wordNo,
      Value<String?> rootAr,
      Value<String?> rootCode,
      Value<String?> rootEn,
      Value<int?> rootWordId,
      Value<String?> meaningEn,
      Value<String?> wordAr,
      Value<String?> grammarFormDesc,
      Value<String?> meaningID,
      Value<String?> grammarFormDescID,
      Value<int> rowid,
    });
typedef $$GrammarTableTableUpdateCompanionBuilder =
    GrammarTableCompanion Function({
      Value<int> chapterNo,
      Value<int> verseNo,
      Value<int> wordNo,
      Value<String?> rootAr,
      Value<String?> rootCode,
      Value<String?> rootEn,
      Value<int?> rootWordId,
      Value<String?> meaningEn,
      Value<String?> wordAr,
      Value<String?> grammarFormDesc,
      Value<String?> meaningID,
      Value<String?> grammarFormDescID,
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

  ColumnFilters<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
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

  ColumnOrderings<String> get meaningEn => $composableBuilder(
    column: $table.meaningEn,
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
  GeneratedColumn<int> get chapterNo =>
      $composableBuilder(column: $table.chapterNo, builder: (column) => column);

  GeneratedColumn<int> get verseNo =>
      $composableBuilder(column: $table.verseNo, builder: (column) => column);

  GeneratedColumn<int> get wordNo =>
      $composableBuilder(column: $table.wordNo, builder: (column) => column);

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

  GeneratedColumn<String> get meaningEn =>
      $composableBuilder(column: $table.meaningEn, builder: (column) => column);

  GeneratedColumn<String> get wordAr =>
      $composableBuilder(column: $table.wordAr, builder: (column) => column);

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
                Value<int> chapterNo = const Value.absent(),
                Value<int> verseNo = const Value.absent(),
                Value<int> wordNo = const Value.absent(),
                Value<String?> rootAr = const Value.absent(),
                Value<String?> rootCode = const Value.absent(),
                Value<String?> rootEn = const Value.absent(),
                Value<int?> rootWordId = const Value.absent(),
                Value<String?> meaningEn = const Value.absent(),
                Value<String?> wordAr = const Value.absent(),
                Value<String?> grammarFormDesc = const Value.absent(),
                Value<String?> meaningID = const Value.absent(),
                Value<String?> grammarFormDescID = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarTableCompanion(
                chapterNo: chapterNo,
                verseNo: verseNo,
                wordNo: wordNo,
                rootAr: rootAr,
                rootCode: rootCode,
                rootEn: rootEn,
                rootWordId: rootWordId,
                meaningEn: meaningEn,
                wordAr: wordAr,
                grammarFormDesc: grammarFormDesc,
                meaningID: meaningID,
                grammarFormDescID: grammarFormDescID,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int chapterNo,
                required int verseNo,
                required int wordNo,
                Value<String?> rootAr = const Value.absent(),
                Value<String?> rootCode = const Value.absent(),
                Value<String?> rootEn = const Value.absent(),
                Value<int?> rootWordId = const Value.absent(),
                Value<String?> meaningEn = const Value.absent(),
                Value<String?> wordAr = const Value.absent(),
                Value<String?> grammarFormDesc = const Value.absent(),
                Value<String?> meaningID = const Value.absent(),
                Value<String?> grammarFormDescID = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GrammarTableCompanion.insert(
                chapterNo: chapterNo,
                verseNo: verseNo,
                wordNo: wordNo,
                rootAr: rootAr,
                rootCode: rootCode,
                rootEn: rootEn,
                rootWordId: rootWordId,
                meaningEn: meaningEn,
                wordAr: wordAr,
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
