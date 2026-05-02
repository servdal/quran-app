import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/utils/tajweed_parser.dart';

void main() {
  test('keeps Quran Cloud glyphs and attaches leading diacritics', () {
    const tajweedText =
        'وَكَأَيّ[a:2298[ِن م]ِّ[f:4585[ن ق]َرْيَةٍ هِىَ أَشَدُّ قُوَّ[a:12557[ةً م]ِّ[f:12558[ن ق]َرْيَتِكَ [h:12559[ٱ]لَّت[o[ِىٓ] أَخْرَجَتْكَ أَهْلَكْنَ[n[ـٰ]هُمْ فَلَا نَاصِرَ لَهُمْ';

    final plainText =
        TextSpan(
          children: TajweedParser.parse(
            tajweedText,
            const TextStyle(color: Colors.black),
          ),
        ).toPlainText();

    expect(plainText, contains('ٱلَّتِىٓ'));
    expect(plainText, isNot(contains('التِىٓ')));
    expect(plainText, contains('وَكَأَيِّن مِّنْ قَرْيَةٍ'));
    expect(plainText, contains('قَرْيَتِكَ ٱلَّتِىٓ'));
  });

  test('keeps lafadz Allah in one shaped fragment after tajweed marker', () {
    const tajweedText =
        'أُ[s[وْ]لَ[o[ـٰٓ]ئِكَ [h:51[ٱ]لَّذِينَ لَعَنَهُمُ [h:462[ٱ]للَّهُ فَأَصَ[g[مّ]َهُمْ وَأَعْمَ[o[ىٰٓ] أَ[q:76[بْ]صَ[n[ـٰ]رَهُمْ';

    final spans = TajweedParser.parse(
      tajweedText,
      const TextStyle(color: Colors.black),
    );
    final plainText = TextSpan(children: spans).toPlainText();

    expect(plainText, contains('ٱللَّهُ'));
    expect(spans.any((span) => (span.text ?? '').contains('للَّهُ')), isTrue);
  });

  test('normalizes nested madd marker before sukun marker', () {
    const tajweedText =
        'وَلَنَ[q:791[بْ]لُوَ[g[نّ]َكُمْ حَتَّىٰ نَعْلَمَ [h:12602[ٱ]لْمُجَ[n[ـٰ]هِدِينَ مِ[f:344[نك]ُمْ وَ[h:918[ٱ][l[ل]صَّ[n[ـٰ]بِرِينَ وَنَ[q:12603[بْ]لُو[o[َ[s[اْ]] أَخْبَارَكُمْ';

    final plainText =
        TextSpan(
          children: TajweedParser.parse(
            tajweedText,
            const TextStyle(color: Colors.black),
          ),
        ).toPlainText();

    expect(plainText, contains('وَنَبْلُوَا۟ أَخْبَارَكُمْ'));
    expect(plainText, isNot(contains('[o')));
    expect(plainText, isNot(contains('[s')));
  });

  test('normalizes open sukun alif marker before spaces', () {
    const tajweedText =
        'وَءَاتَيْنَ[n[ـٰ]ه[c:12402[ُم ب]َيِّنَ[n[ـٰ][a:12403[تٍ م]ِّنَ [h:2233[ٱ]لْأَمْرِ‌ۖ فَمَا [h:6193[ٱ]خْتَلَف[o[ُوٓ][s[اْ] إِلَّا م[i:146[ِنۢ ب]َعْدِ مَا ج[o[َا]ٓءَهُمُ [h:1804[ٱ]لْعِلْمُ بَغْي[i:1169[َۢا ب]َيْنَهُمْ‌ۚ إِ[g[نّ]َ رَبَّكَ يَ[q:6194[قْ]ضِى بَيْنَهُمْ يَوْمَ [h:592[ٱ]لْقِيَ[n[ـٰ]مَةِ فِيمَا كَانُو[s[اْ] فِيهِ يَخْتَلِف[p[ُو]نَ';

    final spans = TajweedParser.parse(
      tajweedText,
      const TextStyle(color: Colors.black),
    );
    final plainText = TextSpan(children: spans).toPlainText();

    expect(plainText, contains('ٱخْتَلَفُوٓا۟ إِلَّا'));
    expect(plainText, contains('كَانُوا۟ فِيهِ'));
    expect(plainText, isNot(contains('[s')));
    expect(spans.any((span) => (span.text ?? '').contains('فُوٓا۟')), isTrue);
  });
}
