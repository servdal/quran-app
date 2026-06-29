import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/utils/recitation_alignment.dart';

void main() {
  test('normalizes waqf marks and harakat out of target words', () {
    expect(
      RecitationAlignment.normalizePhonetic('الْعٰلَمِيْنَۙ'),
      RecitationAlignment.normalizePhonetic('العالمين'),
    );
  });

  test('matches the active recitation against constrained target words', () {
    final match = RecitationAlignment.align(
      hypotheses: const ['الحمد لله رب العالمين'],
      targetWords: const ['اَلْحَمْدُ', 'لِلّٰهِ', 'رَبِّ', 'الْعٰلَمِيْنَۙ'],
      currentIndex: 0,
    );

    expect(match.isMatch, isTrue);
    expect(match.matchedWordCount, greaterThan(1));
  });

  test('rejects unrelated recitation', () {
    final match = RecitationAlignment.align(
      hypotheses: const ['مالك يوم الدين'],
      targetWords: const ['اَلْحَمْدُ', 'لِلّٰهِ', 'رَبِّ', 'الْعٰلَمِيْنَۙ'],
      currentIndex: 0,
    );

    expect(match.isMatch, isFalse);
    expect(match.matchedWordCount, 0);
  });
}
