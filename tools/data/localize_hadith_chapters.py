"""Add complete bilingual chapter labels without changing source identities or texts."""
import json
from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[2]


def topic(title):
    return re.sub(
        r'^(?:The )?(?:Book (?:of|on|concerning|pertaining to)|Chapters (?:on|regarding)) (?:the )?',
        '', title, flags=re.I,
    )


def labels():
    result = {}
    for line in Path(__file__).with_name('hadith_chapter_translations.tsv').read_text().splitlines():
        if not line or line.startswith('#'):
            continue
        aliases, indonesian, english = line.split('\t')
        for alias in aliases.split('|'):
            if alias in result:
                raise ValueError(f'Duplicate topic: {alias}')
            result[alias] = (indonesian, english)
    return result


def localize(path=ROOT / 'assets/database/hadith.db'):
    translations = labels()
    with sqlite3.connect(path) as db:
        chapters = db.execute('SELECT id, title FROM chapters').fetchall()
        missing = [title for _, title in chapters if topic(title) not in translations]
        if missing:
            raise ValueError(f'Missing chapter labels: {missing}')
        columns = {row[1] for row in db.execute('PRAGMA table_info(chapters)')}
        for column in ('title_id', 'title_en'):
            if column not in columns:
                db.execute(f'ALTER TABLE chapters ADD COLUMN {column} TEXT')
        for chapter_id, title in chapters:
            db.execute('UPDATE chapters SET title_id=?, title_en=? WHERE id=?',
                       (*translations[topic(title)], chapter_id))
        db.execute('INSERT OR REPLACE INTO metadata VALUES (?,?)',
                   ('chapter_label_languages', 'id,en'))
        db.execute('PRAGMA user_version=3')
        assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
        assert not db.execute('PRAGMA foreign_key_check').fetchall()
    manifest_path = path.parent / 'hadith_manifest.json'
    if manifest_path.exists():
        manifest = json.loads(manifest_path.read_text())
        manifest['schema_version'] = 3
        manifest['chapter_labels'] = {'languages': ['id', 'en'], 'count': len(chapters),
                                      'source_titles_preserved': True}
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(f'Localized {len(chapters)} chapters in Indonesian and English.')


if __name__ == '__main__':
    localize()
