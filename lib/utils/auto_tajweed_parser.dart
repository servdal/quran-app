import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

/// Auto Tajweed Parser
///
/// - Reads clean Arabic from `aya_text` (no tajweed tags).
/// - Auto-detects tajwid rules between adjacent letters/tokens:
///   idgham (bighunnah & bilaghunnah), ikhfa, iqlab, idgham syafawi,
///   ikhfa syafawi, qalqalah, and a simple mad detection (mad thabi'i).
/// - Colors entire fragments (letter + diacritics) using AppTheme.tajweedColors.
/// - Transfers tanwin visually to the next token when rule requires.
// ignore: unintended_html_in_doc_comment
/// - Returns List<TextSpan> to render in a RichText (TextDirection.rtl).
///
/// Note: This is intentionally conservative — it focuses on reliable,
/// well-defined rules and is easy to extend later.
/// Token model: baseLetter (string) + diacritics (string)
const int cpSukun = 0x0652; // 'ْ'
const int cpFathatan = 0x064B; // 'ً'
const int cpDammatan = 0x064C; // 'ٌ'
const int cpKasratan = 0x064D; // 'ٍ'
const int cpShadda = 0x0651; // 'ّ'
/// Return whether the codepoint is tanwin (ً ٌ ٍ)
bool _isTanwin(int cp) =>
    cp == cpFathatan || cp == cpDammatan || cp == cpKasratan;

class _Token {
  final String base; // single base char
  String diacritics; // possibly empty (one or more combining marks)
  _Token(this.base, [this.diacritics = '']);

  String get full => '$base$diacritics';

  bool get hasSukun {
    return diacritics.runes.any((r) => r == cpSukun);
  }

  bool get hasTanwin {
    return diacritics.runes.any((r) => _isTanwin(r));
  }

  bool get isLetterYOrW {
    final cp = base.runes.first;
    return cp == 'ي'.codeUnitAt(0) || cp == 'و'.codeUnitAt(0);
  }

  int baseCodeUnit() => base.runes.first;
}
class AutoTajweedParser {
  
  

  // sets of letters used in tajwid rules:
  static final Set<int> idghamBighunnahNext = {
    'ي'.codeUnitAt(0),
    'ن'.codeUnitAt(0),
    'م'.codeUnitAt(0),
    'و'.codeUnitAt(0),
  };
  static final Set<int> idghamBilaghunnahNext = {
    'ل'.codeUnitAt(0),
    'ر'.codeUnitAt(0),
  };
  static final Set<int> ikhfaLetters = {
    'ت'.codeUnitAt(0), 'ث'.codeUnitAt(0), 'ج'.codeUnitAt(0), 'د'.codeUnitAt(0),
    'ذ'.codeUnitAt(0), 'ز'.codeUnitAt(0), 'س'.codeUnitAt(0), 'ش'.codeUnitAt(0),
    'ص'.codeUnitAt(0), 'ض'.codeUnitAt(0), 'ط'.codeUnitAt(0), 'ظ'.codeUnitAt(0),
    'ف'.codeUnitAt(0), 'ق'.codeUnitAt(0), 'ك'.codeUnitAt(0),
  };
  static final Set<int> qalqalahLetters = {
    'ق'.codeUnitAt(0),
    'ط'.codeUnitAt(0),
    'ب'.codeUnitAt(0),
    'ج'.codeUnitAt(0),
    'د'.codeUnitAt(0),
  };

  /// map rule keys to colors via AppTheme
  /// We'll use the same keys as AppTheme.tajweedRules (a,u,w,i,f,c,q,n, etc.)
  static Color colorForKey(String key, Color fallback) {
    return AppTheme.tajweedColors[key] ?? fallback;
  }

  /// Return whether the codepoint is a combining diacritic we consider
  static bool _isDiacriticCodepoint(int cp) {
    if ((cp >= 0x064B && cp <= 0x065F) || cp == 0x0670) return true;
    if (cp >= 0x06D6 && cp <= 0x06ED) return true;
    return false;
  }

  
  

  /// Public API: parse aya_text into TextSpan list with automatic tajweed coloring.
  /// baseStyle is used for text metrics, color will be replaced per rule.
  static List<TextSpan> parse(String ayaText, TextStyle baseStyle) {
    if (ayaText.isEmpty) return [];
    ayaText = ayaText.replaceAll('\u200c', '').replaceAll('\u200b', '');

    final List<_Token> tokens = _tokenize(ayaText);

    // We'll construct TextSpans; default color is baseStyle.color or black
    final Color defaultColor = baseStyle.color ?? Colors.black;
    final List<TextSpan> out = [];

    // We'll keep track of which tokens have been colored/consumed.
    final int n = tokens.length;

    void emitTokenRaw(int idx) {
      final t = tokens[idx];
      final TextStyle style = baseStyle.copyWith(color: defaultColor);
      out.add(TextSpan(text: t.full, style: style));
    }

    int i = 0;
    while (i < n) {
      final curr = tokens[i];
      if (curr.base == 'ٰ') {
        out.add(TextSpan(text: curr.full, style: baseStyle.copyWith(color: defaultColor)));
        i++;
        continue;
      }
      final next = (i + 1 < n) ? tokens[i + 1] : null;

      String? ruleKey;

      final bool currHasTanwin = curr.hasTanwin;
      final bool currHasSukun = curr.hasSukun;

      if (next != null) {
        final int nextBaseCp = next.baseCodeUnit();

        // 1) Mim sukun + Mim -> idgham shafawi (w)
        if (curr.base == 'م' && currHasSukun && next.base == 'م') {
          ruleKey = 'w'; // idgham shafawi (mim-mim) - ghunnah
        }

        // 2) Mim (with or without explicit sukun) + Ba -> ikhfa shafawi (c)
        else if (curr.base == 'م' && next.base == 'ب') {
          // For education we mark it as ikhfa shafawi
          ruleKey = 'c';
        }

        // 3) Nun sukun or tanwin + next in bighunnah set -> idgham bighunnah (a)
        else if ((currHasSukun || currHasTanwin) &&
            idghamBighunnahNext.contains(nextBaseCp)) {
          ruleKey = 'a';
        }

        // 4) Nun sukun or tanwin + next in bilaghunnah set -> idgham bilaghunnah (u)
        else if ((currHasSukun || currHasTanwin) &&
            idghamBilaghunnahNext.contains(nextBaseCp)) {
          ruleKey = 'u';
        }

        // 5) Nun sukun/tanwin + next == Ba -> Iqlab (i)
        else if ((currHasSukun || currHasTanwin) && next.base == 'ب') {
          ruleKey = 'i';
        }

        // 6) Nun sukun/tanwin + next in ikhfa set -> Ikhfa (f)
        else if ((currHasSukun || currHasTanwin) &&
            ikhfaLetters.contains(nextBaseCp)) {
          ruleKey = 'f';
        }

        // 7) Qalqalah: if current has sukun and is qalqalah letter
        else if (currHasSukun && qalqalahLetters.contains(curr.baseCodeUnit())) {
          ruleKey = 'q';
        }

        // 8) Mad thabi'i simple detection:
        // - fatha followed by alif
        // - kasra followed by ya (sukun) or ya (with sukun)
        // - dhamma followed by waw (sukun)
        // For token-level: if current has fatha and next base is 'ا' => 'n'
        else if (_hasFatha(curr) && next.base == 'ا') {
          ruleKey = 'n'; // madd thabi'i
        } else if (_hasDhamma(curr) && next.base == 'و') {
          ruleKey = 'n';
        } else if (_hasKasra(curr) && next.base == 'ي') {
          ruleKey = 'n';
        }
      } else {
        // next == null, maybe current token has qalqalah sukun
        if (currHasSukun && qalqalahLetters.contains(curr.baseCodeUnit())) {
          ruleKey = 'q';
        }
      }

      // If ruleKey triggers transfer of tanwin (a, u, w, i) and curr had tanwin,
      // we will render curr without the tanwin and render next with the tanwin appended.
      final bool ruleNeedsTanwinTransfer = ruleKey != null && {'a', 'u', 'w', 'i'}.contains(ruleKey);

      if (ruleNeedsTanwinTransfer && currHasTanwin && next != null) {
        // Build curr display without tanwin (remove tanwin from diacritics)
        final String currDisplay = _removeTanwinFromString(curr.full);
        // Build next display with appended tanwin (we pick the same tanwin character)
        final String tanwinChar = _extractTrailingTanwin(curr.full);
        final String nextDisplay = '${next.full}$tanwinChar';

        // Emit both tokens colored by ruleKey
        final Color c = colorForKey(ruleKey, defaultColor);
        final TextStyle ruleStyle = baseStyle.copyWith(color: c);
        out.add(TextSpan(text: currDisplay, style: ruleStyle));
        out.add(TextSpan(text: nextDisplay, style: ruleStyle));

        // skip one extra token (we consumed next as well)
        i += 2;
        continue;
      }

      // If ruleKey exists and it's a binary rule (involving current and next),
      // color both tokens with the rule.
      if (ruleKey != null && next != null) {
        final Color c = colorForKey(ruleKey, defaultColor);
        final TextStyle ruleStyle = baseStyle.copyWith(color: c);
        out.add(TextSpan(text: curr.full, style: ruleStyle));
        out.add(TextSpan(text: next.full, style: ruleStyle));
        i += 2;
        continue;
      }

      // If no special rule linking current to next, check if current alone is qalqalah or mad.
      if (ruleKey == null) {
        // standalone qalqalah or madd that we earlier flagged (already covered some cases)
        // We'll emit raw token with default color.
        emitTokenRaw(i);
        i += 1;
        continue;
      }

      // Fallback: emit raw
      emitTokenRaw(i);
      i += 1;
    }

    return out;
  }

  // --- Helper functions used above ---

  /// Tokenize an Arabic string into base-letter + following diacritics groups.
  static List<_Token> _tokenize(String text) {
    final List<_Token> tokens = [];
    final runes = text.runes.toList();

    int idx = 0;
    while (idx < runes.length) {
      final int cp = runes[idx];
      final String ch = String.fromCharCode(cp);

      // if ch itself is a combining diacritic (rare at start), attach to previous token
      if (_isDiacriticCodepoint(cp)) {
        if (tokens.isEmpty) {
          // stray diacritic at start: create a pseudo base of empty string
          tokens.add(_Token('', String.fromCharCode(cp)));
        } else {
          tokens.last.diacritics = '${tokens.last.diacritics}${String.fromCharCode(cp)}';
        }
        idx++;
        continue;
      }

      // ch is base letter (or space / punctuation). Group following diacritics.
      String base = ch;
      String diacs = '';

      int j = idx + 1;
      while (j < runes.length && _isDiacriticCodepoint(runes[j])) {
        diacs = '$diacs${String.fromCharCode(runes[j])}';
        j++;
      }

      // If base is whitespace, we emit it as a token with no diacritics
      if (base.trim().isEmpty) {
        tokens.add(_Token(base, diacs));
      } else {
        tokens.add(_Token(base, diacs));
      }

      idx = j;
    }

    return tokens;
  }

  // remove trailing tanwin character from token full string, return new string
  static String _removeTanwinFromString(String full) {
    final runes = full.runes.toList();
    if (runes.isEmpty) return full;
    final last = runes.last;
    if (_isTanwin(last)) {
      return String.fromCharCodes(runes.sublist(0, runes.length - 1));
    }
    // also consider tanwin possibly before other diacritics? conservative: remove last tanwin if present anywhere at end
    return full;
  }

  // extract the trailing tanwin character from full; returns '' if none
  static String _extractTrailingTanwin(String full) {
    final runes = full.runes.toList();
    if (runes.isEmpty) return '';
    final last = runes.last;
    if (_isTanwin(last)) {
      return String.fromCharCode(last);
    }
    return '';
  }

  static bool _hasFatha(_Token t) {
    return t.diacritics.runes.any((r) => r == 0x064E);
  }

  static bool _hasKasra(_Token t) {
    return t.diacritics.runes.any((r) => r == 0x0650);
  }

  static bool _hasDhamma(_Token t) {
    return t.diacritics.runes.any((r) => r == 0x064F);
  }
}
