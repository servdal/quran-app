import unittest
from collections import defaultdict
from complete_quran_master import infer, canonical_roots, arabic, gloss, missing_fields


class CompletionInferenceTests(unittest.TestCase):
    def row(self, root=1, word='هُدًى', meaning='Guidance', meaning_id='petunjuk', grammar='Noun'):
        return {'id': root, 'RootWordId': root, 'RootAr': 'ه د ي' if root == 1 else 'ع ل م',
                'RootCode': 'hdy' if root == 1 else 'Elm', 'RootEn': 'ha dal ya' if root == 1 else 'ain lam mim',
                'WordAr': word, 'MeaningEn': meaning, 'MeaningId': meaning_id,
                'GrammarFormDesc': grammar, 'GrammarFormDescID': 'Isim' if grammar == 'Noun' else 'Fiil',
                'ChapterNo': root, 'VerseNo': 1}

    def test_same_form_and_gloss_reuses_unique_root_and_analysis(self):
        row = self.row()
        word = {'arabic': 'هُدًۭى', 'translation': 'Guidance'}
        values, method, donors = infer(word, {(arabic(row['WordAr']),gloss(row['MeaningEn'])):[row]}, {}, canonical_roots([row]))
        self.assertEqual(values['RootWordId'],1)
        self.assertEqual(values['MeaningId'],'petunjuk')
        self.assertEqual(values['GrammarFormDesc'],'Noun')
        self.assertEqual(donors,[1])

    def test_multiple_roots_are_not_chosen_even_when_word_and_gloss_agree(self):
        rows = [self.row(1),self.row(2)]
        result,_,_ = infer({'arabic':'هُدًى','translation':'Guidance'},
            {(arabic('هُدًى'),gloss('Guidance')):rows},{},canonical_roots(rows))
        self.assertNotIn('RootWordId',result)
        self.assertNotIn('RootAr',result)

    def test_vocalized_fallback_does_not_copy_contextual_translation(self):
        rows = [self.row(),dict(self.row(),id=2,ChapterNo=2,MeaningEn='A guidance')]
        result,method,_ = infer({'arabic':'هُدًى','translation':'guidance (for them)'},
            {},{arabic('هُدًى',vowels=True):rows},canonical_roots(rows))
        self.assertEqual(method,'vocalized_word_consensus')
        self.assertEqual(result['RootWordId'],1)
        self.assertNotIn('MeaningId',result)
        self.assertNotEqual(arabic('مِنْ',vowels=True),arabic('مَنْ',vowels=True))

    def test_rootwordid_does_not_determine_grammar(self):
        rows=[self.row(),self.row(grammar='Verb')]
        result,_,_=infer({'arabic':'هُدًى','translation':'Guidance'},
            {(arabic('هُدًى'),gloss('Guidance')):rows},{},canonical_roots(rows))
        self.assertIn('RootWordId',result)
        self.assertNotIn('GrammarFormDesc',result)

    def test_root_corruption_reuses_only_unanimous_clean_value(self):
        good=self.row();bad=dict(good,RootAr='ه ?? ي')
        self.assertEqual(canonical_roots([good,bad])[1]['RootAr'],'ه د ي')
        conflict=dict(good,RootAr='ع ل م')
        self.assertNotIn('RootAr',canonical_roots([good,conflict])[1])

    def test_unknown_words_stay_unknown_and_are_reported(self):
        result,method,donors=infer({'arabic':'مِن','translation':'from'},{},{},{})
        self.assertEqual(result,{})
        self.assertEqual(method,'api_only')
        self.assertIn('RootWordId',missing_fields({'WordAr':'مِن','MeaningEn':'from'}))

class CompletionPipelineTests(unittest.TestCase):
    def test_atomic_completion_preserves_annotations_and_reports_unknown_roots(self):
        import contextlib
        import io
        import json
        from pathlib import Path
        import sqlite3
        import tempfile
        import complete_quran_master as module
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            cache, reports, backups = root/'cache', root/'reports', root/'backups'
            cache.mkdir()
            for surah in range(1, 115):
                (cache/f'surah-{surah}.json').write_text(json.dumps({'success':True,'data':{
                    'surah':surah,'total_verses':1,'verses':[{'ayah':1,'word_count':1,'words':[
                        {'type':'word','position':1,'arabic':'هُدًى','translation':'Guidance',
                         'transliteration':{'text':'hudan'}}]}]}}))
            database = root/'quran.db'
            with sqlite3.connect(database) as db:
                db.execute('CREATE TABLE master_edited (' + ','.join(
                    column + (' INTEGER PRIMARY KEY' if column=='id' else ' INTEGER' if column in
                              ['RootWordId','ChapterNo','VerseNo','WordNo'] else ' TEXT') for column in module.COLUMNS) + ')')
                db.execute('CREATE TABLE merged_aya(sura_id INTEGER, aya_number INTEGER, aya_text TEXT)')
                db.executemany('INSERT INTO merged_aya VALUES (?,1,?)',[(s,'unchanged') for s in range(1,115)])
                rows = [dict(CompletionInferenceTests().row(), id=10, WordAr='هُ??ًى',RootEn='ha ?? ya'),
                        dict(CompletionInferenceTests().row(2), id=11, ChapterNo=1),
                        dict(CompletionInferenceTests().row(), id=12, ChapterNo=2)]
                for row in rows:
                    row.update(VerseNo=1,WordNo=1)
                    db.execute('INSERT INTO master_edited VALUES ('+','.join('?' for _ in module.COLUMNS)+')',
                               [row.get(k) for k in module.COLUMNS])
            original_root=module.ROOT
            try:
                module.ROOT=root
                with contextlib.redirect_stdout(io.StringIO()):module.complete(cache,database,reports,backups)
            finally:
                module.ROOT=original_root
            with sqlite3.connect(database) as db:
                self.assertEqual(db.execute('SELECT count(*) FROM master_edited').fetchone()[0],115)
                self.assertEqual(db.execute('SELECT count(*) FROM master_edited WHERE ChapterNo=1').fetchone()[0],2)
                self.assertEqual(db.execute('SELECT WordAr,RootEn FROM master_edited WHERE id=10').fetchone(),('هُدًى','ha dal ya'))
                self.assertEqual(db.execute('SELECT RootWordId FROM master_edited WHERE ChapterNo=3').fetchone()[0],None)
                self.assertEqual(db.execute('PRAGMA user_version').fetchone()[0],4)
                self.assertEqual(db.execute('PRAGMA integrity_check').fetchone()[0],'ok')
            report=json.loads((reports/'completion.json').read_text())
            self.assertEqual(report['added_rows'],112)
            self.assertEqual(report['partial_field_rows'],112)
            with sqlite3.connect(root/report['backup']) as backup:
                self.assertEqual(backup.execute('SELECT WordAr FROM master_edited WHERE id=10').fetchone()[0],'هُ??ًى')


if __name__ == '__main__':
    unittest.main()
