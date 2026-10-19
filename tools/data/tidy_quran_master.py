"""Normalize optional word fields without inventing missing linguistic data."""
import hashlib
import json
from pathlib import Path
import sqlite3

ROOT = Path(__file__).resolve().parents[2]
DATABASE = ROOT / 'assets/database/quran.db'
REPORT = ROOT / 'reports/quran_master_completion/cleanup.json'
FIELDS = ['RootAr', 'RootCode', 'RootEn', 'MeaningEn', 'MeaningId',
          'GrammarFormDesc', 'GrammarFormDescID']


def main():
    db = sqlite3.connect(DATABASE)
    before_hash = hashlib.sha256(DATABASE.read_bytes()).hexdigest()
    backup = ROOT / 'backups' / f'quran-before-cleanup-{before_hash[:12]}.db'
    if not backup.exists():
        with sqlite3.connect(backup) as target:
            db.backup(target)
    changes = []
    with db:
        db.execute('''CREATE TABLE IF NOT EXISTS master_edited_cleanup_log (
            row_id INTEGER NOT NULL, field TEXT NOT NULL, original_value TEXT,
            cleaned_value TEXT, PRIMARY KEY(row_id, field))''')
        for field in FIELDS:
            for row_id, value in db.execute(
                    f'SELECT id,{field} FROM master_edited WHERE {field} IS NOT NULL').fetchall():
                cleaned = value.strip() or None
                if value != cleaned:
                    db.execute(f'UPDATE master_edited SET {field}=? WHERE id=?', (cleaned, row_id))
                    db.execute('INSERT OR IGNORE INTO master_edited_cleanup_log VALUES (?,?,?,?)',
                               (row_id, field, value, cleaned))
                    changes.append({'row_id': row_id, 'field': field,
                                    'original_value': value, 'cleaned_value': cleaned})
        db.execute('PRAGMA user_version=5')
    assert db.execute('PRAGMA integrity_check').fetchone()[0] == 'ok'
    assert not db.execute('PRAGMA foreign_key_check').fetchall()
    assert db.execute('SELECT COUNT(*) FROM master_edited WHERE WordNo<=0').fetchone()[0] == 0
    count = db.execute('SELECT COUNT(*) FROM master_edited').fetchone()[0]
    db.execute('PRAGMA wal_checkpoint(TRUNCATE)')
    db.execute('PRAGMA journal_mode=DELETE')
    db.close()
    REPORT.write_text(json.dumps({'backup': str(backup), 'rows': count,
        'version': 5, 'before_sha256': before_hash,
        'after_sha256': hashlib.sha256(DATABASE.read_bytes()).hexdigest(),
        'changes': changes}, ensure_ascii=False, indent=2) + '\n')
    print(f'{len(changes)} fields normalized; {count} rows preserved; integrity ok')


if __name__ == '__main__':
    main()
