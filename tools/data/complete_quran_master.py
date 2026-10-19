"""Complete master_edited positions without inventing roots or grammatical analysis.

Reads all 114 previously audited UmmahAPI responses; no network requests.
Usage: python3 tools/data/complete_quran_master.py --cache /tmp/quran-word-audit
Writes an atomic database replacement, a SQLite backup, per-row provenance and reports.
"""
import argparse
from collections import defaultdict, Counter
import csv
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import sqlite3
import unicodedata

ROOT = Path(__file__).resolve().parents[2]
ROOT_FIELDS = ['RootAr', 'RootCode', 'RootEn']
ANALYSIS_FIELDS = ['RootWordId', *ROOT_FIELDS, 'MeaningId', 'GrammarFormDesc', 'GrammarFormDescID']
REQUIRED = ['WordAr', 'MeaningEn', *ANALYSIS_FIELDS]
COLUMNS = ['id', 'RootAr', 'RootCode', 'RootEn', 'RootWordId', 'ChapterNo', 'MeaningEn',
           'VerseNo', 'WordAr', 'WordNo', 'GrammarFormDesc', 'MeaningId', 'GrammarFormDescID']


def clean(value):
    return isinstance(value, str) and bool(value.strip()) and '??' not in value and '\ufffd' not in value


def arabic(text, vowels=False):
    text = unicodedata.normalize('NFKD', text or '').replace('ٱ', 'ا').replace('ڪ', 'ك').replace('ی', 'ي').replace('ـ', '')
    return ''.join(c for c in text if '\u0621' <= c <= '\u063a' or '\u0641' <= c <= '\u064a'
                   or (vowels and '\u064b' <= c <= '\u0652'))


def gloss(text):
    return ' '.join((text or '').strip().casefold().split())


def consistent(rows, fields):
    values = {tuple(r.get(field) for field in fields) for r in rows
              if all(clean(r.get(field)) for field in fields)}
    return next(iter(values)) if len(values) == 1 else None


def canonical_roots(rows):
    groups = defaultdict(list)
    for row in rows:
        if isinstance(row.get('RootWordId'), int) and row['RootWordId'] > 0:
            groups[row['RootWordId']].append(row)
    return {root_id: {field: next(iter(values)) for field in ROOT_FIELDS
                      if len(values := {r[field] for r in group if clean(r.get(field))}) == 1}
            for root_id, group in groups.items()}


def infer(word, by_gloss, by_vowels, roots):
    candidates = by_gloss.get((arabic(word['arabic']), gloss(word.get('translation'))), [])
    method = 'word_and_english_gloss' if candidates else 'api_only'
    if not candidates:
        candidate_vowels = by_vowels.get(arabic(word['arabic'], vowels=True), [])
        # Require repeated observations before reusing morphology across different glosses.
        if len({(r['ChapterNo'], r['VerseNo']) for r in candidate_vowels}) >= 2:
            candidates = candidate_vowels
            method = 'vocalized_word_consensus'
    result = {}
    if candidates:
        ids = {r['RootWordId'] for r in candidates if isinstance(r.get('RootWordId'), int) and r['RootWordId'] > 0}
        if len(ids) == 1:
            root_id = next(iter(ids))
            result['RootWordId'] = root_id
            result.update(roots.get(root_id, {}))
        grammar = consistent(candidates, ['GrammarFormDesc', 'GrammarFormDescID'])
        if grammar:
            result.update(zip(['GrammarFormDesc', 'GrammarFormDescID'], grammar))
        if method == 'word_and_english_gloss':
            meanings = {gloss(r.get('MeaningId')) for r in candidates if clean(r.get('MeaningId'))}
            if len(meanings) == 1:
                result['MeaningId'] = next(r['MeaningId'] for r in candidates if clean(r.get('MeaningId')))
    return result, method, sorted({r['id'] for r in candidates})


def missing_fields(row):
    result = []
    for field in REQUIRED:
        value = row.get(field)
        if field == 'RootWordId':
            if not isinstance(value, int) or value <= 0:
                result.append(field)
        elif not clean(value):
            result.append(field)
    return result


def digest_rows(connection, table):
    digest = hashlib.sha256()
    for row in connection.execute(f'SELECT * FROM {table} ORDER BY rowid'):
        digest.update(json.dumps(tuple(row), ensure_ascii=False, separators=(',', ':')).encode())
    return digest.hexdigest()


def csv_report(path, rows, fields):
    with path.open('w', newline='', encoding='utf-8-sig') as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(rows)


def complete(cache, database, output, backup_dir, baseline_path=None):
    cache, database, output, backup_dir = (p.resolve() for p in (cache, database, output, backup_dir))
    baseline_path = baseline_path.resolve() if baseline_path else None
    output.mkdir(parents=True, exist_ok=True)
    backup_dir.mkdir(parents=True, exist_ok=True)
    reference, hashes = {}, {}
    for surah in range(1, 115):
        path = cache / f'surah-{surah}.json'
        raw = path.read_bytes()
        hashes[str(surah)] = hashlib.sha256(raw).hexdigest()
        response = json.loads(raw)
        data = response['data']
        assert response['success'] and data['surah'] == surah
        assert len(data['verses']) == data['total_verses']
        for verse in data['verses']:
            words = [w for w in verse['words'] if w['type'] == 'word']
            assert len(words) == verse['word_count']
            assert [w['position'] for w in words] == list(range(1, len(words) + 1))
            for word in words:
                assert clean(word['arabic']) and clean(word['translation'])
                reference[(surah, verse['ayah'], word['position'])] = word
    source_path = baseline_path or database
    original_hash = hashlib.sha256(source_path.read_bytes()).hexdigest()
    backup = baseline_path or backup_dir / f'quran-before-master-completion-{original_hash[:12]}.db'
    source = sqlite3.connect(f'file:{source_path}?mode=ro', uri=True)
    source.row_factory = sqlite3.Row
    baseline = [dict(r) for r in source.execute('SELECT * FROM master_edited ORDER BY id')]
    if source.execute("SELECT name FROM sqlite_master WHERE name='master_edited_completion_log'").fetchone():
        raise RuntimeError('This asset has already been completed; start from the recorded backup to rebuild')
    merged_hash = digest_rows(source, 'merged_aya')
    expected_verses = {(r[0], r[1]) for r in source.execute('SELECT DISTINCT sura_id, aya_number FROM merged_aya')}
    assert {(s, a) for s, a, _ in reference} == expected_verses
    assert all((r['ChapterNo'],r['VerseNo'],r['WordNo']) in reference for r in baseline)
    if not backup.exists():
        with sqlite3.connect(backup) as target:
            source.backup(target)
    # A temporary database is published only when every assertion passes.
    temporary = database.with_suffix('.completion.tmp')
    temporary.unlink(missing_ok=True)
    db = sqlite3.connect(temporary)
    source.backup(db)
    source.close()
    db.row_factory = sqlite3.Row
    original_by_id = {row['id']: row for row in baseline}
    roots = canonical_roots(baseline)
    by_gloss, by_vowels = defaultdict(list), defaultdict(list)
    for row in baseline:
        if row['WordAr']:
            by_gloss[(arabic(row['WordAr']), gloss(row['MeaningEn']))].append(row)
            by_vowels[arabic(row['WordAr'], vowels=True)].append(row)
    now = datetime.now(timezone.utc).isoformat()
    logs, changed_fields = [], Counter()

    def record(row, changes, method, donors=None, old=None):
        if not changes:
            return
        for field in changes:
            changed_fields[field] += 1
        logs.append({'row_id': row['id'], 'surah': row['ChapterNo'], 'ayah': row['VerseNo'], 'word_no': row['WordNo'],
                     'method': method, 'filled_fields': json.dumps(changes, ensure_ascii=False),
                     'donor_ids': json.dumps(donors or []), 'original_values': json.dumps(old or {}, ensure_ascii=False)})

    with db:
        db.execute('''CREATE TABLE master_edited_completion_log (
            log_id INTEGER PRIMARY KEY, row_id INTEGER NOT NULL REFERENCES master_edited(id),
            surah INTEGER NOT NULL, ayah INTEGER NOT NULL, word_no INTEGER NOT NULL,
            method TEXT NOT NULL, filled_fields TEXT NOT NULL, donor_ids TEXT NOT NULL,
            original_values TEXT NOT NULL, source_url TEXT, source_sha256 TEXT,
            transliteration_en TEXT, completed_at TEXT NOT NULL)''')
        existing_positions = {(r['ChapterNo'],r['VerseNo'],r['WordNo']) for r in baseline}
        # Repair only empty word text and provably corrupt root labels sharing one RootWordId.
        for row in baseline:
            changes = {}
            reference_word = reference[(row['ChapterNo'],row['VerseNo'],row['WordNo'])]
            if not (row['WordAr'] or '').strip():
                changes['WordAr'] = reference_word['arabic']
            elif not clean(row['WordAr']) and gloss(row['MeaningEn']) == gloss(reference_word['translation']):
                changes['WordAr'] = reference_word['arabic']
            for field, value in roots.get(row['RootWordId'], {}).items():
                if not clean(row.get(field)):
                    changes[field] = value
            if changes:
                db.execute('UPDATE master_edited SET '+', '.join(f'{key}=?' for key in changes)+' WHERE id=?',
                           [*changes.values(), row['id']])
                record(row, changes, 'repair_empty_word_or_corrupt_root_consensus',
                       donors=[donor['id'] for donor in baseline if donor['RootWordId'] == row['RootWordId']
                               and any(field in ROOT_FIELDS and donor.get(field) == value for field,value in changes.items())],
                       old={f:row[f] for f in changes})
        next_id = max(r['id'] for r in baseline)
        new_methods = Counter()
        for position, word in sorted(reference.items()):
            if position in existing_positions:
                continue
            surah, ayah, number = position
            next_id += 1
            inferred, method, donors = infer(word, by_gloss, by_vowels, roots)
            row = dict.fromkeys(COLUMNS)
            row.update({'id': next_id, 'ChapterNo': surah, 'VerseNo': ayah, 'WordNo': number,
                        'WordAr': word['arabic'], 'MeaningEn': word['translation'], **inferred})
            db.execute('INSERT INTO master_edited ('+','.join(COLUMNS)+') VALUES ('+','.join('?' for _ in COLUMNS)+')',
                       [row[c] for c in COLUMNS])
            record(row, {key:value for key,value in row.items() if value is not None}, method, donors)
            new_methods[method] += 1
        for log in logs:
            word = reference[(log['surah'],log['ayah'],log['word_no'])]
            root_only = bool(json.loads(log['original_values'])) and 'WordAr' not in json.loads(log['filled_fields'])
            source_url = (f'local:master_edited:RootWordId={original_by_id[log["row_id"]]["RootWordId"]}' if root_only
                          else f'https://ummahapi.com/api/quran/words/{log["surah"]}')
            db.execute('INSERT INTO master_edited_completion_log (row_id,surah,ayah,word_no,method,filled_fields,donor_ids,original_values,source_url,source_sha256,transliteration_en,completed_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
                       [log[k] for k in ['row_id','surah','ayah','word_no','method','filled_fields','donor_ids','original_values']]+
                       [source_url, original_hash if root_only else hashes[str(log['surah'])],
                        None if root_only else (word.get('transliteration') or {}).get('text'), now])
        db.execute('CREATE INDEX IF NOT EXISTS master_edited_by_position ON master_edited(ChapterNo,VerseNo,WordNo)')
        db.execute('PRAGMA user_version = 4')
        after = [dict(r) for r in db.execute('SELECT * FROM master_edited ORDER BY ChapterNo,VerseNo,WordNo,id')]
        after_by_id = {r['id']:r for r in after}
        allowed_changes = {log['row_id']:json.loads(log['filled_fields']) for log in logs if json.loads(log['original_values'])}
        for old_row in baseline:
            expected = {**old_row, **allowed_changes.get(old_row['id'], {})}
            assert after_by_id[old_row['id']] == expected, old_row['id']
        assert {(r['ChapterNo'],r['VerseNo'],r['WordNo']) for r in after} == set(reference)
        assert len(after) == len(baseline) + len(set(reference) - existing_positions)
        assert digest_rows(db, 'merged_aya') == merged_hash
        assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        assert not db.execute('PRAGMA foreign_key_check').fetchall()
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)')
    db.execute('PRAGMA journal_mode = DELETE')
    db.close()
    # Reports distinguish field completeness from semantic verification.
    complete_rows, partial_rows, by_surah = [], [], defaultdict(Counter)
    original_max_id = max(r['id'] for r in baseline)
    new_ids = {r['row_id'] for r in logs if r['row_id'] > original_max_id}
    for row in after:
        missing = missing_fields(row)
        item = {'id':row['id'],'surah':row['ChapterNo'],'ayah':row['VerseNo'],'word_no':row['WordNo'],
                'arabic':row['WordAr'],'meaning_en':row['MeaningEn'],'root_word_id':row['RootWordId'],
                'missing_fields':';'.join(missing),'origin':'added' if row['id'] in new_ids else 'existing'}
        (partial_rows if missing else complete_rows).append(item)
        by_surah[row['ChapterNo']]['rows'] += 1
        by_surah[row['ChapterNo']]['partial' if missing else 'complete'] += 1
        if item['origin'] == 'added':by_surah[row['ChapterNo']]['added'] += 1
    unmatched_rows = [item for item in partial_rows if item['origin'] == 'added' and
                      all(field in item['missing_fields'].split(';') for field in ANALYSIS_FIELDS)]
    summary = {'completed_at':now,'backup':str(backup.relative_to(ROOT.resolve())) if backup.is_relative_to(ROOT.resolve()) else str(backup),
               'baseline_sha256':original_hash,'completed_sha256':hashlib.sha256(temporary.read_bytes()).hexdigest(),
               'original_rows':len(baseline),'final_rows':len(after),'unique_positions':len(reference),
               'added_rows':len(new_ids),'existing_rows_repaired':len(allowed_changes),
               'new_row_methods':dict(new_methods),'field_updates_including_inserts':dict(changed_fields),
               'complete_field_rows':len(complete_rows),'partial_field_rows':len(partial_rows),
               'added_complete_rows':sum(r['origin']=='added' for r in complete_rows),
               'unmatched_analysis_rows':len(unmatched_rows),
               'added_partial_with_reused_analysis':sum(r['origin']=='added' for r in partial_rows)-len(unmatched_rows),
               'remaining_empty_fields':dict(Counter(field for row in after for field in missing_fields(row))),
               'merged_aya_unchanged_sha256':merged_hash,'reference_sha256':hashes,
               'preserved_multi_root_position':'20:94:2',
               'completeness_definition':REQUIRED,
               'notes':['Field completeness does not certify linguistic correctness.',
                        'Missing Indonesian and grammar/root analysis have not been fabricated.',
                        'Only original local rows are used as inference donors; new guesses are never recycled.',
                        '20:94:2 has two original root analyses, both retained.']}
    fields=['id','surah','ayah','word_no','arabic','meaning_en','root_word_id','missing_fields','origin']
    csv_report(output/'complete_rows.csv',complete_rows,fields)
    csv_report(output/'partial_rows.csv',partial_rows,fields)
    csv_report(output/'unmatched_analysis_rows.csv',unmatched_rows,fields)
    csv_report(output/'changes.csv',logs,['row_id','surah','ayah','word_no','method','filled_fields','donor_ids','original_values'])
    csv_report(output/'surah_summary.csv',[{'surah':s,**dict(v)} for s,v in sorted(by_surah.items())],['surah','rows','complete','partial','added'])
    original_root_counts = Counter(r['RootWordId'] for r in baseline if r['RootWordId'])
    added_root_counts = Counter(r['RootWordId'] for r in after if r['id'] in new_ids and r['RootWordId'])
    csv_report(output/'root_word_id_reuse.csv', [
        {'RootWordId': root_id, **values, 'original_rows': original_root_counts[root_id],
         'added_rows': added_root_counts[root_id]} for root_id,values in sorted(roots.items())
    ], ['RootWordId','RootAr','RootCode','RootEn','original_rows','added_rows'])
    (output/'completion.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n')
    temporary.replace(database)
    print(json.dumps({k:v for k,v in summary.items() if k not in ['reference_sha256','notes']},ensure_ascii=False,indent=2))


if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--cache',type=Path,required=True)
    parser.add_argument('--database',type=Path,default=ROOT/'assets/database/quran.db')
    parser.add_argument('--output',type=Path,default=ROOT/'reports/quran_master_completion')
    parser.add_argument('--backup-dir',type=Path,default=ROOT/'backups')
    parser.add_argument('--baseline',type=Path,help='Rebuild from an existing pre-completion backup')
    args=parser.parse_args()
    complete(args.cache,args.database,args.output,args.backup_dir,args.baseline)
