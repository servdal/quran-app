"""Convert the six upstream MySQL dumps to SQLite, without executing source SQL.

Usage: python3 tools/data/build_hadith_database.py /path/to/hadits-database
Source revision: db43bdaa70ee528a0e663c089d3dab5bb4d855f0
"""
import hashlib
import json
from pathlib import Path
import re
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[2]
BOOKS = [
    ('bukhari', 'Shahih Bukhari', 'shahih-bukhari.sql', 7008),
    ('muslim', 'Shahih Muslim', 'shahih-muslim.sql', 5362),
    ('abu-daud', 'Sunan Abu Daud', 'sunan-abu-daud.sql', 4590),
    ('ibnu-majah', 'Sunan Ibnu Majah', 'sunan-ibnu-majah.sql', 4332),
    ('nasai', "Sunan Nasa’i", 'sunan-nasai.sql', 5662),
    ('tirmidzi', 'Sunan Tirmidzi', 'sunan-tirmidzi.sql', 3891),
]
ROW = re.compile(r"^\((\d+),\s*'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)',\s*'((?:[^'\\]|\\.)*)'\)[,;]?\s*$", re.M)
ESCAPES = {'0': '\0', 'n': '\n', 'r': '\r', 't': '\t', 'b': '\b', 'Z': '\x1a', "'": "'", '"': '"', '\\': '\\'}


def unescape(value):
    return re.sub(r'\\(.)', lambda m: ESCAPES.get(m[1], '\\' + m[1]), value)


def build(source):
    output = ROOT / 'assets/database/hadith.db'
    temporary = output.with_suffix('.db.tmp')
    temporary.unlink(missing_ok=True)
    manifest = {'source': 'https://github.com/irsyadulibad/hadits-database',
                'revision': 'db43bdaa70ee528a0e663c089d3dab5bb4d855f0',
                'schema_version': 1, 'books': []}
    with sqlite3.connect(temporary) as db:
        db.executescript('''
        PRAGMA user_version = 1;
        CREATE TABLE books (id TEXT PRIMARY KEY, title TEXT NOT NULL, sort_order INTEGER NOT NULL, hadith_count INTEGER NOT NULL);
        CREATE TABLE hadiths (book_id TEXT NOT NULL REFERENCES books(id), number INTEGER NOT NULL, arabic TEXT NOT NULL, translation TEXT NOT NULL, PRIMARY KEY(book_id, number));
        CREATE TABLE chapters (id TEXT PRIMARY KEY, title TEXT NOT NULL, source TEXT NOT NULL);
        CREATE TABLE hadith_chapters (chapter_id TEXT NOT NULL REFERENCES chapters(id), book_id TEXT NOT NULL, number INTEGER NOT NULL, PRIMARY KEY(chapter_id, book_id, number), FOREIGN KEY(book_id, number) REFERENCES hadiths(book_id, number));
        CREATE TABLE metadata (key TEXT PRIMARY KEY, value TEXT NOT NULL);
        ''')
        for order, (book, title, filename, expected) in enumerate(BOOKS):
            data = (source / filename).read_bytes()
            text = data.decode('utf-8')
            rows = ROW.findall(text)
            assert len(rows) == len(re.findall(r'^\(\d+,', text, re.M)) == expected, filename
            assert [int(r[0]) for r in rows] == list(range(1, expected + 1)), filename
            parsed = [(book, int(n), unescape(ar), unescape(tr)) for n, _, ar, tr in rows]
            assert all(ar.strip() and tr.strip() for _, _, ar, tr in parsed), filename
            db.execute('INSERT INTO books VALUES (?, ?, ?, ?)', (book, title, order, expected))
            db.executemany('INSERT INTO hadiths VALUES (?, ?, ?, ?)', parsed)
            manifest['books'].append({'id': book, 'title': title, 'count': expected, 'file': filename, 'sha256': hashlib.sha256(data).hexdigest()})
        db.executemany('INSERT INTO metadata VALUES (?, ?)', [
            ('source', manifest['source']), ('revision', manifest['revision']),
            ('chapter_status', 'Source does not provide chapter titles; no inferred correlations.')])
        assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        assert not db.execute('PRAGMA foreign_key_check').fetchall()
    temporary.replace(output)
    (output.parent / 'hadith_manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(f'{output}: {sum(b[3] for b in BOOKS):,} entries')


if __name__ == '__main__':
    build(Path(sys.argv[1]))
