"""Read-only audit of master_edited against UmmahAPI's word-by-word dataset.

Fetch one response per surah (114 requests); cache responses outside the project.
Usage: python3 tools/data/audit_quran_words.py --cache /tmp/quran-word-audit
No SQL data is updated. Text differences are review candidates, not proven errors.
"""
import argparse
from collections import defaultdict, Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
import csv
import hashlib
import json
from pathlib import Path
import sqlite3
import unicodedata
import urllib.request

ROOT = Path(__file__).resolve().parents[2]


def normalize(text):
    text = unicodedata.normalize('NFKD', text or '').replace('ٱ', 'ا').replace('ـ', '')
    return ''.join(c for c in text if '\u0621' <= c <= '\u063a' or '\u0641' <= c <= '\u064a')


def fetch(surah, cache):
    path = cache / f'surah-{surah}.json'
    if path.exists():
        data = json.loads(path.read_text())
    else:
        request = urllib.request.Request(f'https://ummahapi.com/api/quran/words/{surah}',
                                         headers={'User-Agent': 'Mushaf-data-audit/1.0', 'Accept': 'application/json'})
        with urllib.request.urlopen(request, timeout=45) as response:
            raw = response.read()
        data = json.loads(raw)
        if not data.get('success') or data.get('data', {}).get('surah') != surah:
            raise ValueError(f'Invalid response for surah {surah}')
        path.write_bytes(raw)
    verses = data['data']['verses']
    if len(verses) != data['data']['total_verses']:
        raise ValueError(f'Incomplete response for surah {surah}')
    return verses, hashlib.sha256(path.read_bytes()).hexdigest()


def write_csv(path, rows, fields):
    with path.open('w', newline='', encoding='utf-8-sig') as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows)


def audit(cache, output):
    cache.mkdir(parents=True, exist_ok=True)
    output.mkdir(parents=True, exist_ok=True)
    db_path = ROOT / 'assets/database/quran.db'
    connection = sqlite3.connect(f'file:{db_path}?mode=ro', uri=True)
    connection.row_factory = sqlite3.Row
    local = defaultdict(list)
    rows = list(connection.execute('SELECT * FROM master_edited'))
    for row in rows:
        local[(row['ChapterNo'], row['VerseNo'], row['WordNo'])].append(dict(row))
    expected_verses = {(r[0], r[1]) for r in connection.execute('SELECT DISTINCT sura_id, aya_number FROM merged_aya')}
    reference, manifest, failures = {}, {}, {}
    with ThreadPoolExecutor(max_workers=4) as pool:
        futures = {pool.submit(fetch, surah, cache): surah for surah in range(1, 115)}
        for future in as_completed(futures):
            surah = futures[future]
            try:
                verses, digest = future.result()
                manifest[str(surah)] = digest
                for verse in verses:
                    words = [word for word in verse['words'] if word.get('type') == 'word']
                    positions = [word['position'] for word in words]
                    if len(words) != verse['word_count'] or positions != list(range(1, len(words) + 1)):
                        raise ValueError(f'Invalid word positions in {surah}:{verse["ayah"]}')
                    for word in words:
                        reference[(surah, verse['ayah'], word['position'])] = word
            except Exception as error:
                failures[str(surah)] = f'{type(error).__name__}: {error}'
            print(f'Audited surah {surah} ({len(manifest)}/114)', flush=True)
    # Never present partial network coverage as a complete audit.
    if failures:
        (output / 'fetch_failures.json').write_text(json.dumps(failures, ensure_ascii=False, indent=2))
        raise RuntimeError(f'{len(failures)} surahs failed; cached successes can be reused')
    missing, conflicts, extra, duplicates = [], [], [], []
    verse_positions = defaultdict(list)
    for s, a, n in reference:
        verse_positions[(s, a)].append(n)
    for (s, a, n), word in sorted(reference.items()):
        group = local.get((s, a, n), [])
        if not group:
            missing.append({'surah': s, 'ayah': a, 'word_no': n, 'arabic': word['arabic'],
                            'meaning_en': word.get('translation', ''),
                            'transliteration': (word.get('transliteration') or {}).get('text', '')})
        else:
            for row in group:
                if normalize(row['WordAr']) != normalize(word['arabic']):
                    conflicts.append({'surah': s, 'ayah': a, 'word_no': n, 'local_id': row['id'],
                                      'local_arabic': row['WordAr'], 'reference_arabic': word['arabic'],
                                      'local_meaning': row['MeaningEn'], 'reference_meaning': word.get('translation', '')})
    for (s, a, n), group in sorted(local.items()):
        if len(group) > 1:
            for row in group:
                duplicates.append({'surah': s, 'ayah': a, 'word_no': n, 'local_id': row['id'],
                                   'arabic': row['WordAr'], 'meaning_en': row['MeaningEn']})
        if (s, a, n) not in reference:
            for row in group:
                extra.append({'surah': s, 'ayah': a, 'word_no': n, 'local_id': row['id'], 'arabic': row['WordAr']})
    local_verses = {(s, a) for s, a, _ in local}
    missing_verses = sorted(expected_verses - local_verses)
    position_categories = Counter()
    verse_bounds = {}
    for surah, ayah, number in local:
        key = (surah, ayah)
        low, high = verse_bounds.get(key, (number, number))
        verse_bounds[key] = (min(low, number), max(high, number))
    for row in missing:
        key = row['surah'], row['ayah']
        if key not in verse_bounds:
            position_categories['whole_verse'] += 1
        elif row['word_no'] < verse_bounds[key][0]:
            position_categories['before_first'] += 1
        elif row['word_no'] > verse_bounds[key][1]:
            position_categories['after_last'] += 1
        else:
            position_categories['between_existing'] += 1
    report = {'database': 'assets/database/quran.db', 'source': 'https://ummahapi.com/api/quran/words/{surah}',
              'local_rows': len(rows), 'local_unique_positions': len(local),
              'local_verses': len(local_verses), 'expected_verses': len(expected_verses),
              'reference_words': len(reference), 'reference_verses': len(verse_positions),
              'missing_words': len(missing), 'verses_with_missing_words': len({(r['surah'], r['ayah']) for r in missing}),
              'wholly_missing_verses': missing_verses, 'duplicate_positions': len({(r['surah'],r['ayah'],r['word_no']) for r in duplicates}),
              'empty_arabic_rows': [dict(r) for r in rows if not (r['WordAr'] or '').strip()],
              'normalized_text_difference_rows': len(conflicts), 'local_positions_outside_reference': len(extra),
              'missing_by_surah': dict(sorted(Counter(r['surah'] for r in missing).items())),
              'missing_position_categories': dict(position_categories),
              'text_differences_with_same_english_meaning': sum(
                  r['local_meaning'].strip().casefold() == r['reference_meaning'].strip().casefold() for r in conflicts),
              'reference_sha256': dict(sorted(manifest.items(), key=lambda pair: int(pair[0]))),
              'notes': ['Positions are compared by surah/ayah/word number, not whitespace tokenization.',
                        'Arabic text differences can reflect orthography/tokenization and require review.',
                        'API supplies Arabic, English word meanings and transliteration, not roots or grammar.',
                        'Database was opened read-only; no rows have been changed.']}
    write_csv(output / 'missing_words.csv', missing, ['surah', 'ayah', 'word_no', 'arabic', 'meaning_en', 'transliteration'])
    write_csv(output / 'text_differences.csv', conflicts, ['surah','ayah','word_no','local_id','local_arabic','reference_arabic','local_meaning','reference_meaning'])
    write_csv(output / 'duplicate_positions.csv', duplicates, ['surah','ayah','word_no','local_id','arabic','meaning_en'])
    write_csv(output / 'outside_reference.csv', extra, ['surah','ayah','word_no','local_id','arabic'])
    (output / 'audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps({k:v for k,v in report.items() if k not in ['reference_sha256','missing_by_surah','notes','empty_arabic_rows']}, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--cache', type=Path, required=True)
    parser.add_argument('--output', type=Path, default=ROOT / 'reports/quran_word_audit')
    args = parser.parse_args()
    audit(args.cache, args.output)
