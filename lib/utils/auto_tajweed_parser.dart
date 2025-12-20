import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

/// =============================================================
/// AUTO TAJWEED PARSER (FINAL – STABLE & EDUCATIONAL)
/// =============================================================
/// - Source: aya_text (clean Arabic)
/// - No WidgetSpan (TextSpan only → safe for mushaf)
/// - No tanwin transfer
/// - Strict mad (ya/wau must be sukun)
/// - Lafẓ Jalālah handled per-token (no duplication bug)
/// - Learning mode: tap → explanation + highlight
/// =============================================================

const int cpSukun = 0x0652; // ْ
const int cpShadda = 0x0651; // ّ
const int cpFathatan = 0x064B; // ً
const int cpDammatan = 0x064C; // ٌ
const int cpKasratan = 0x064D; // ٍ

bool _isTanwin(int cp) =>
    cp == cpFathatan || cp == cpDammatan || cp == cpKasratan;

/// =============================================================
/// TOKEN
/// =============================================================
class _Token {
  final String base;
  String diacritics;

  _Token(this.base, [this.diacritics = '']);

  String get full => '$base$diacritics';
  bool get hasSukun => diacritics.contains('ْ');
  bool get hasShadda => diacritics.contains('ّ');
  bool get hasTanwin => diacritics.runes.any(_isTanwin);
  int get baseCode => base.runes.first;
}

/// =============================================================
/// PARSER
/// =============================================================
class AutoTajweedParser {
  static final Set<int> _idghamBighunnah =
      {'ي', 'ن', 'م', 'و'}.map((e) => e.codeUnitAt(0)).toSet();

  static final Set<int> _idghamBilaghunnah =
      {'ل', 'ر'}.map((e) => e.codeUnitAt(0)).toSet();

  static final Set<int> _ikhfaLetters = {
    'ت','ث','ج','د','ذ','ز','س','ش','ص','ض','ط','ظ','ف','ق','ك'
  }.map((e) => e.codeUnitAt(0)).toSet();

  static final Set<int> _qalqalahLetters =
      {'ق','ط','ب','ج','د'}.map((e) => e.codeUnitAt(0)).toSet();
  static final RegExp _lafzJalalahRegex =
    RegExp(r'اللّٰهُ?');
  static String _normalizeDiacritics(String diacs) {
    if (diacs.isEmpty) return diacs;

    final runes = diacs.runes.toList();

    final shadda = <int>[];
    final dagger = <int>[];
    final harakat = <int>[];
    final tanwin = <int>[];
    final sukun = <int>[];
    final others = <int>[];

    for (final r in runes) {
      if (r == 0x0651) {
        shadda.add(r);
      } else if (r == 0x0670) {
        dagger.add(r);
      } else if (r == 0x064E || r == 0x064F || r == 0x0650) {
        harakat.add(r);
      } else if (r == 0x064B || r == 0x064C || r == 0x064D) {
        tanwin.add(r);
      } else if (r == 0x0652) {
        sukun.add(r);
      } else {
        others.add(r);
      }
    }

    return String.fromCharCodes([
      ...shadda,
      ...dagger,
      ...harakat,
      ...tanwin,
      ...sukun,
      ...others,
    ]);
  }

  /// ===========================================================
  /// PUBLIC API
  /// ===========================================================
  static List<TextSpan> parse(
    String ayaText,
    TextStyle baseStyle, {
    bool learningMode = false,
    String? activeKey,
    ValueChanged<String>? onTapRule,
    VoidCallback? onClosePopup,
    BuildContext? context,
  }) {
    if (ayaText.isEmpty) return [];

    ayaText = ayaText.replaceAll('\u200c', '').replaceAll('\u200b', '');
    final tokens = _tokenize(ayaText);
    final List<TextSpan> spans = [];

    int i = 0;
    while (i < tokens.length) {
      final curr = tokens[i];
      final next = (i + 1 < tokens.length) ? tokens[i + 1] : null;

      // ===== LAFẒ JALĀLAH (اللّٰهُ) =====
      final match = _lafzJalalahRegex.firstMatch(ayaText);
      if (match != null) {
        final before = ayaText.substring(0, match.start);
        final lafz = match.group(0)!;
        final after = ayaText.substring(match.end);

        final spans = <TextSpan>[];

        // BEFORE → parse normal
        if (before.isNotEmpty) {
          spans.addAll(
            AutoTajweedParser.parse(
              before,
              baseStyle,
              learningMode: learningMode,
              activeKey: activeKey,
              onTapRule: onTapRule,
              onClosePopup: onClosePopup,
              context: context,
            ),
          );
        }

        // LAFẒ JALĀLAH → RAW, INTERACTIVE
        spans.add(
          TextSpan(
            text: lafz,
            style: baseStyle.copyWith(
              color: AppTheme.tajweedColors['jalalah'],
              backgroundColor: activeKey == 'jalalah'
                  ? AppTheme.tajweedColors['jalalah']?.withOpacity(0.15)
                  : null,
            ),
            recognizer: (learningMode && context != null)
                ? (TapGestureRecognizer()
                    ..onTap = () {
                      onTapRule?.call('jalalah');

                      final rule = AppTheme.tajweedRules.firstWhere(
                        (r) => r.key == 'jalalah',
                      );

                      showModalBottomSheet(
                        context: context,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: rule.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    rule.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(rule.description),
                            ],
                          ),
                        ),
                      ).whenComplete(() => onClosePopup?.call());
                    })
                : null,
          ),
        );

        // AFTER → parse normal
        if (after.isNotEmpty) {
          spans.addAll(
            AutoTajweedParser.parse(
              after,
              baseStyle,
              learningMode: learningMode,
              activeKey: activeKey,
              onTapRule: onTapRule,
              onClosePopup: onClosePopup,
              context: context,
            ),
          );
        }

        return spans;
      }
      String? ruleKey;

      if (next != null) {
        final nextCp = next.baseCode;

        // Mim Syafawi
        if (curr.base == 'م' && curr.hasSukun && next.base == 'م') {
          ruleKey = 'w';
        } else if (curr.base == 'م' && next.base == 'ب') {
          ruleKey = 'c';
        }

        // Nun / Tanwin
        else if ((curr.hasSukun || curr.hasTanwin) &&
            _idghamBighunnah.contains(nextCp)) {
          ruleKey = 'a';
        } else if ((curr.hasSukun || curr.hasTanwin) &&
            _idghamBilaghunnah.contains(nextCp)) {
          ruleKey = 'u';
        } else if ((curr.hasSukun || curr.hasTanwin) && next.base == 'ب') {
          ruleKey = 'i';
        } else if ((curr.hasSukun || curr.hasTanwin) &&
            _ikhfaLetters.contains(nextCp)) {
          ruleKey = 'f';
        }

        // Qalqalah
        else if (curr.hasSukun &&
            _qalqalahLetters.contains(curr.baseCode)) {
          ruleKey = 'q';
        }

        // Mad Thabi‘i (strict)
        else if (_hasFatha(curr) && next.base == 'ا') {
          ruleKey = 'n';
        } else if (_hasKasra(curr) &&
            next.base == 'ي' &&
            next.hasSukun) {
          ruleKey = 'n';
        } else if (_hasDhamma(curr) &&
            next.base == 'و' &&
            next.hasSukun) {
          ruleKey = 'n';
        }
      }

      if (ruleKey != null && next != null) {
        spans.add(TextSpan(
          text: curr.full + next.full,
          style: _style(baseStyle, ruleKey, activeKey == ruleKey),
          recognizer: _tap(
            context,
            learningMode,
            ruleKey,
            onTapRule,
            onClosePopup,
          ),
        ));
        i += 2;
      } else {
        spans.add(TextSpan(text: curr.full, style: baseStyle));
        i++;
      }
    }

    return spans;
  }

  /// ===========================================================
  /// HELPERS
  /// ===========================================================
  static TextStyle _style(
    TextStyle base,
    String key,
    bool active,
  ) {
    final color = AppTheme.tajweedColors[key];
    if (color == null) return base;

    return base.copyWith(
      color: color,
      backgroundColor: active ? color.withOpacity(0.18) : null,
    );
  }

  static GestureRecognizer? _tap(
    BuildContext? context,
    bool enabled,
    String key,
    ValueChanged<String>? onTapRule,
    VoidCallback? onClosePopup,
  ) {
    if (!enabled || context == null) return null;

    return TapGestureRecognizer()
      ..onTap = () {
        onTapRule?.call(key);

        final rule = AppTheme.tajweedRules.firstWhere(
          (r) => r.key == key,
        );

        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: rule.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rule.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(rule.description),
              ],
            ),
          ),
        ).whenComplete(() => onClosePopup?.call());
      };
  }

  static bool _hasFatha(_Token t) => t.diacritics.contains('َ');
  static bool _hasKasra(_Token t) => t.diacritics.contains('ِ');
  static bool _hasDhamma(_Token t) => t.diacritics.contains('ُ');

  static bool _isDiacritic(int cp) {
    if ((cp >= 0x064B && cp <= 0x065F) || cp == 0x0670) return true;
    if (cp >= 0x06D6 && cp <= 0x06ED) return true;
    return false;
  }
  static List<_Token> _tokenize(String text) {
    final runes = text.runes.toList();
    final List<_Token> out = [];
    int i = 0;

    while (i < runes.length) {
      final cp = runes[i];
      final ch = String.fromCharCode(cp);

      if (_isDiacritic(cp)) {
        if (out.isNotEmpty) out.last.diacritics += ch;
        i++;
        continue;
      }

      final token = _Token(ch);
      i++;
      while (i < runes.length && _isDiacritic(runes[i])) {
        token.diacritics += String.fromCharCode(runes[i]);
        token.diacritics = _normalizeDiacritics(token.diacritics);
        i++;
      }
      out.add(token);
    }
    return out;
  }
}
