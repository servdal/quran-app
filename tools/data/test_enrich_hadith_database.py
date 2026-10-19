import unittest
from enrich_hadith_database import index_rows, match, normalize


class MatchingTests(unittest.TestCase):
    def test_diacritics_and_punctuation_do_not_change_whole_text(self):
        self.assertEqual(normalize('حَدِيثٌ، صحيح'), normalize('حديث صحيح'))

    def test_local_number_is_not_used_for_matching(self):
        text = 'A complete narration with enough content to prevent accidental short matches. ' * 3
        local = {'number': 1, 'arabic': '', 'translation': text}
        index = index_rows([{'hadithnumber': 900, 'text': text}])
        self.assertEqual(match(local, {}, index), ('900', 'indonesian'))

    def test_duplicate_narrations_are_not_guessed_from_number(self):
        text = 'A complete repeated narration. ' * 8
        index = index_rows([{'hadithnumber': 1, 'text': text}, {'hadithnumber': 2, 'text': text}])
        self.assertIsNone(match({'arabic': '', 'translation': text}, {}, index))

    def test_contradictory_arabic_and_indonesian_matches_are_rejected(self):
        arabic, translation = 'عربية ' * 50, 'Indonesian narration ' * 10
        self.assertIsNone(match({'arabic': arabic, 'translation': translation},
            index_rows([{'hadithnumber': 1, 'text': arabic}]),
            index_rows([{'hadithnumber': 2, 'text': translation}])))

    def test_short_headings_are_not_narration_anchors(self):
        self.assertEqual(index_rows([{'hadithnumber': 1, 'text': 'Introduction'}]), {})


if __name__ == '__main__':
    unittest.main()
