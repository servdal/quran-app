import 'dart:math' as math;

class RecitationMatch {
  final bool isMatch;
  final int matchedWordCount;
  final double confidence;
  final String normalizedInput;

  const RecitationMatch({
    required this.isMatch,
    required this.matchedWordCount,
    required this.confidence,
    required this.normalizedInput,
  });
}

class RecitationAlignment {
  static const int _maxLookAheadWords = 6;

  static RecitationMatch align({
    required List<String> hypotheses,
    required List<String> targetWords,
    required int currentIndex,
  }) {
    if (currentIndex >= targetWords.length) {
      return const RecitationMatch(
        isMatch: true,
        matchedWordCount: 0,
        confidence: 1,
        normalizedInput: '',
      );
    }

    final normalizedHypotheses =
        hypotheses
            .map(normalizePhonetic)
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList();

    if (normalizedHypotheses.isEmpty) {
      return const RecitationMatch(
        isMatch: false,
        matchedWordCount: 0,
        confidence: 0,
        normalizedInput: '',
      );
    }

    var bestScore = 0.0;
    var bestCount = 0;
    var bestInput = normalizedHypotheses.first;
    var bestAcceptedScore = 0.0;
    var bestAcceptedCount = 0;

    final maxCount = math.min(
      _maxLookAheadWords,
      targetWords.length - currentIndex,
    );
    for (final input in normalizedHypotheses) {
      for (var count = 1; count <= maxCount; count++) {
        final target =
            targetWords
                .skip(currentIndex)
                .take(count)
                .map(normalizePhonetic)
                .where((value) => value.isNotEmpty)
                .join();

        if (target.isEmpty) continue;

        final score = _prefixSimilarity(input, target);
        if (score > bestScore || (score == bestScore && count > bestCount)) {
          bestScore = score;
          bestCount = count;
          bestInput = input;
        }

        final minimumScore = count > 1 ? 0.72 : 0.62;
        if (score >= minimumScore &&
            (count > bestAcceptedCount ||
                (count == bestAcceptedCount && score > bestAcceptedScore))) {
          bestAcceptedScore = score;
          bestAcceptedCount = count;
          bestInput = input;
        }
      }
    }

    if (bestAcceptedCount > 0) {
      return RecitationMatch(
        isMatch: true,
        matchedWordCount: bestAcceptedCount,
        confidence: bestAcceptedScore,
        normalizedInput: bestInput,
      );
    }

    return RecitationMatch(
      isMatch: false,
      matchedWordCount: 0,
      confidence: bestScore,
      normalizedInput: bestInput,
    );
  }

  static String normalizePhonetic(String text) {
    if (text.isEmpty) return '';

    var clean = text;
    clean = clean.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    clean = clean.replaceAll(RegExp(r'[ىئ]'), 'ي');
    clean = clean.replaceAll('ؤ', 'و');
    clean = clean.replaceAll('ة', 'ه');
    clean = clean.replaceAll('ـ', '');
    clean = clean.replaceAll('ٰ', 'ا');

    clean = clean.replaceAll(RegExp(r'[0-9٠-٩]'), '');
    clean = clean.replaceAll(
      RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED]'),
      '',
    );
    clean = clean.replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z]'), '');

    final letterNames = <String, String>{
      'الف': 'ا',
      'لام': 'ل',
      'ميم': 'م',
      'كاف': 'ك',
      'ها': 'ه',
      'هاء': 'ه',
      'يا': 'ي',
      'عين': 'ع',
      'سين': 'س',
      'صاد': 'ص',
      'نون': 'ن',
      'قاف': 'ق',
      'راء': 'ر',
      'را': 'ر',
      'طا': 'ط',
      'طه': 'طه',
      'يس': 'يس',
      'حم': 'حم',
    };
    for (final entry in letterNames.entries) {
      clean = clean.replaceAll(entry.key, entry.value);
    }

    clean = clean
        .replaceAll('ص', 'س')
        .replaceAll('ث', 'س')
        .replaceAll('ذ', 'ز')
        .replaceAll('ظ', 'ز')
        .replaceAll('ض', 'د')
        .replaceAll('ط', 'ت')
        .replaceAll('ق', 'ك');

    if (RegExp(r'[a-zA-Z]').hasMatch(clean)) {
      clean = _latinPhonemeToArabicSkeleton(clean);
    }

    return clean.trim();
  }

  static double _prefixSimilarity(String input, String target) {
    if (input.isEmpty || target.isEmpty) return 0;
    if (input == target || input.startsWith(target) || input.contains(target)) {
      return 1;
    }

    final comparableInput =
        input.length > target.length
            ? input.substring(0, target.length)
            : input;
    final distance = _levenshtein(comparableInput, target);
    final maxLength = math.max(comparableInput.length, target.length);
    return 1 - (distance / maxLength);
  }

  static int _levenshtein(String source, String target) {
    if (source == target) return 0;
    if (source.isEmpty) return target.length;
    if (target.isEmpty) return source.length;

    final previous = List<int>.generate(target.length + 1, (index) => index);
    final current = List<int>.filled(target.length + 1, 0);

    for (var i = 0; i < source.length; i++) {
      current[0] = i + 1;
      for (var j = 0; j < target.length; j++) {
        final cost = source.codeUnitAt(i) == target.codeUnitAt(j) ? 0 : 1;
        current[j + 1] = math.min(
          current[j] + 1,
          math.min(previous[j + 1] + 1, previous[j] + cost),
        );
      }
      for (var j = 0; j <= target.length; j++) {
        previous[j] = current[j];
      }
    }

    return current[target.length];
  }

  static String _latinPhonemeToArabicSkeleton(String value) {
    var text = value.toLowerCase();
    final replacements = <String, String>{
      'kh': 'خ',
      'gh': 'غ',
      'sh': 'ش',
      'th': 'س',
      'dh': 'ز',
      'aa': 'ا',
      'ee': 'ي',
      'ii': 'ي',
      'oo': 'و',
      'uu': 'و',
      'a': 'ا',
      'i': 'ي',
      'u': 'و',
      'b': 'ب',
      't': 'ت',
      'j': 'ج',
      'h': 'ه',
      'd': 'د',
      'r': 'ر',
      'z': 'ز',
      's': 'س',
      'c': 'ك',
      'k': 'ك',
      'l': 'ل',
      'm': 'م',
      'n': 'ن',
      'w': 'و',
      'y': 'ي',
      'f': 'ف',
      'q': 'ك',
    };

    for (final entry in replacements.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    return text.replaceAll(RegExp(r'[^ء-ي]'), '');
  }
}
