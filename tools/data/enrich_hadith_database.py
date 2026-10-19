"""Enrich the local corpus using uniquely matching whole Arabic/Indonesian texts.

Usage: python3 tools/data/enrich_hadith_database.py /path/to/pinned/editions
The input directory contains revision.txt, LICENSE and 18 ara/ind/eng JSON files.
No matching by local hadith number or fuzzy similarity is permitted.
"""
from collections import defaultdict, Counter
import hashlib
import json
from pathlib import Path
import re
import shutil
import sqlite3
import sys
import unicodedata

ROOT = Path(__file__).resolve().parents[2]
BOOKS = {'bukhari': 'bukhari', 'muslim': 'muslim', 'abu-daud': 'abudawud',
         'ibnu-majah': 'ibnmajah', 'nasai': 'nasai', 'tirmidzi': 'tirmidhi'}
SOURCE = 'https://github.com/fawazahmed0/hadith-api'


def normalize(text):
    """Ignore diacritics, punctuation and case; preserve all letters and digits."""
    return ''.join(c for c in unicodedata.normalize('NFKD', text or '').casefold()
                   if c.isalnum())


def index_rows(rows):
    index = defaultdict(set)
    for row in rows:
        key = normalize(row.get('text', ''))
        if len(key) >= 80:
            index[key].add(str(row['hadithnumber']))
    return index


def match(local, arabic_index, indonesian_index):
    arabic = arabic_index.get(normalize(local['arabic']), set())
    indonesian = indonesian_index.get(normalize(local['translation']), set())
    # Contradictory whole-text matches must remain unresolved.
    candidates = arabic & indonesian if arabic and indonesian else arabic or indonesian
    if len(candidates) != 1:
        return None
    return next(iter(candidates)), 'arabic+indonesian' if arabic and indonesian else 'arabic' if arabic else 'indonesian'


def enrich(source, output=None):
    output = output or ROOT / 'assets/database/hadith.db'
    revision = (source / 'revision.txt').read_text().strip()
    if not re.fullmatch('[0-9a-f]{40}', revision):
        raise ValueError('A pinned source commit is required')
    temporary = output.with_suffix('.enrich.tmp')
    shutil.copyfile(output, temporary)
    audit = {'source': SOURCE, 'revision': revision,
             'method': 'unique normalized whole-text equality; no number-only or fuzzy matches',
             'files': {}, 'books': {}}
    with sqlite3.connect(temporary) as db:
        db.row_factory = sqlite3.Row
        baseline = list(db.execute('SELECT book_id, number, arabic, translation FROM hadiths ORDER BY book_id, number'))
        columns = {r['name'] for r in db.execute('PRAGMA table_info(hadiths)')}
        for column in ['english', 'grades', 'source_reference']:
            if column not in columns:
                db.execute(f'ALTER TABLE hadiths ADD COLUMN {column} TEXT')
        db.execute('UPDATE hadiths SET english = NULL, grades = NULL, source_reference = NULL')
        db.execute('DELETE FROM hadith_chapters')
        db.execute('DELETE FROM chapters')
        db.execute('''CREATE TABLE IF NOT EXISTS hadith_source_matches (
            book_id TEXT NOT NULL, number INTEGER NOT NULL, source_number TEXT NOT NULL,
            method TEXT NOT NULL, source TEXT NOT NULL, revision TEXT NOT NULL,
            PRIMARY KEY(book_id, number),
            FOREIGN KEY(book_id, number) REFERENCES hadiths(book_id, number))''')
        db.execute('DELETE FROM hadith_source_matches')
        for local_book, upstream_book in BOOKS.items():
            editions = {}
            for lang in ['ara', 'ind', 'eng']:
                path = source / f'{lang}-{upstream_book}.json'
                content = path.read_bytes()
                editions[lang] = json.loads(content)
                audit['files'][path.name] = hashlib.sha256(content).hexdigest()
            upstream = {lang: defaultdict(list) for lang in editions}
            for lang, data in editions.items():
                for row in data['hadiths']:
                    upstream[lang][str(row['hadithnumber'])].append(row)
            local_rows = list(db.execute('SELECT * FROM hadiths WHERE book_id = ?', (local_book,)))
            ar_index = index_rows(editions['ara']['hadiths'])
            id_index = index_rows(editions['ind']['hadiths'])
            proposed = [(row, match(row, ar_index, id_index)) for row in local_rows]
            reverse = Counter(result[0] for _, result in proposed if result)
            report = {'local_count': len(local_rows), 'matched': 0, 'english': 0, 'chapters': 0,
                      'grades': 0, 'methods': Counter(), 'unmatched_numbers': []}
            for row, result in proposed:
                if not result or reverse[result[0]] != 1:
                    report['unmatched_numbers'].append(row['number'])
                    continue
                source_number, method = result
                # Duplicate source numbers are ambiguous even when their texts agree.
                if any(len(upstream[l].get(source_number, [])) > 1 for l in upstream):
                    report['unmatched_numbers'].append(row['number'])
                    continue
                source_rows = [upstream[l][source_number][0] for l in upstream if upstream[l].get(source_number)]
                # Cross-language alignment is valid only if structural references agree.
                refs = {json.dumps(r.get('reference'), sort_keys=True) for r in source_rows if r.get('reference')}
                if len(refs) != 1:
                    report['unmatched_numbers'].append(row['number'])
                    continue
                reference = json.loads(next(iter(refs)))
                english_row = upstream['eng'].get(source_number, [])
                english = english_row[0].get('text', '').strip() if english_row else ''
                grades = []
                for source_row in source_rows:
                    for grade in source_row.get('grades', []):
                        if grade not in grades:
                            grades.append(grade)
                db.execute('UPDATE hadiths SET english=?, grades=?, source_reference=? WHERE book_id=? AND number=?',
                           (english or None, json.dumps(grades, ensure_ascii=False) if grades else None,
                            f'{upstream_book}:{source_number}', local_book, row['number']))
                db.execute('INSERT INTO hadith_source_matches VALUES (?,?,?,?,?,?)',
                           (local_book, row['number'], source_number, method, SOURCE, revision))
                report['matched'] += 1
                report['english'] += bool(english)
                report['grades'] += bool(grades)
                report['methods'][method] += 1
                section = str(reference.get('book', ''))
                # Prefer English section titles consistently across editions.
                title = editions['eng'].get('metadata', {}).get('sections', {}).get(section, '').strip()
                if title:
                    # Identical normalized section titles group across books; no semantic merging.
                    chapter_id = 'section-' + hashlib.sha256(normalize(title).encode()).hexdigest()[:20]
                    db.execute('INSERT OR IGNORE INTO chapters VALUES (?,?,?)', (chapter_id, title, SOURCE))
                    db.execute('INSERT INTO hadith_chapters VALUES (?,?,?)', (chapter_id, local_book, row['number']))
                    report['chapters'] += 1
            report['methods'] = dict(report['methods'])
            audit['books'][local_book] = report
            print(local_book, {k:v for k,v in report.items() if k != 'unmatched_numbers'})
        db.execute('CREATE INDEX IF NOT EXISTS hadith_chapters_by_hadith ON hadith_chapters(book_id, number)')
        db.execute('INSERT OR REPLACE INTO metadata VALUES (?,?)', ('enrichment_revision', revision))
        db.execute('INSERT OR REPLACE INTO metadata VALUES (?,?)', ('chapter_status', 'Exact normalized title grouping from uniquely matched source texts; partial coverage.'))
        db.execute('PRAGMA user_version = 2')
        assert [tuple(r) for r in baseline] == [tuple(r) for r in db.execute('SELECT book_id, number, arabic, translation FROM hadiths ORDER BY book_id, number')]
        assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        assert not db.execute('PRAGMA foreign_key_check').fetchall()
    temporary.replace(output)
    (output.parent / 'hadith_enrichment_audit.json').write_text(json.dumps(audit, ensure_ascii=False, indent=2) + '\n')
    shutil.copyfile(source / 'LICENSE', output.parent / 'HADITH_ENRICHMENT_LICENSE.txt')
    manifest_path = output.parent / 'hadith_manifest.json'
    manifest = json.loads(manifest_path.read_text())
    manifest['schema_version'] = 2
    manifest['enrichment'] = {'source': SOURCE, 'revision': revision, 'audit': 'hadith_enrichment_audit.json'}
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')


if __name__ == '__main__':
    enrich(Path(sys.argv[1]))
