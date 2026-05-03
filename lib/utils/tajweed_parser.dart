import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

final List<Color> colorStack = <Color>[Colors.black];

bool isTanwinCodeUnit(int cp) {
  return cp == 0x064B || cp == 0x064C || cp == 0x064D;
}

List<TextSpan> _fragmentToSpans(
  String fragment,
  TextStyle ruleStyle, {
  GestureRecognizer? recognizer,
}) {
  if (fragment.isEmpty) return [];
  return [TextSpan(text: fragment, style: ruleStyle, recognizer: recognizer)];
}

class TajweedParser {
  static const String sukunChar = 'ْ';
  static const String daggerAlef = 'ٰ';
  static const String smallAlef = 'ٲ';
  static const String fatha = 'َ';

  static const Set<String> sukunRules = {'p', 'w', 'u', 'f'};

  static const Set<String> transferTanwinRules = {'a', 'u', 'w', 'i'};

  static List<TextSpan> parse(
    String text,
    TextStyle baseStyle, {
    String lang = 'id',
    bool learningMode = false,
    String? activeKey,
    ValueChanged<String>? onTapRule,
    VoidCallback? onClosePopup,
    BuildContext? context,
  }) {
    if (text.isEmpty) return [];

    final Color baseColor =
        baseStyle.color ??
        (context != null
            ? Theme.of(context).colorScheme.onSurface
            : Colors.black);
    colorStack
      ..clear()
      ..add(baseColor);

    text = text.replaceAll('\u200c', '');
    
    // PERBAIKAN UTAMA: Regex yang bisa menangani teks di antara tag bersarang
    final RegExp nestedBlockPattern = RegExp(
      r'\[([a-zA-Z0-9_]+(?::\d+)?)\[([^\[\]]*)\[([a-zA-Z0-9_]+(?::\d+)?)\[([^\[\]]+)\]([^\[\]]*)\]',
    );
    
    // Looping untuk meratakan (flatten) semua tag yang bersarang dari dalam ke luar
    while (nestedBlockPattern.hasMatch(text)) {
      text = text.replaceAllMapped(nestedBlockPattern, (match) {
        final String outerRule = match.group(1)!;
        final String textBefore = match.group(2)!; // Teks sebelum inner tag (misal: ُوٓ)
        // match.group(3) adalah inner rule, kita lewati seperti logika asli Anda
        final String innerBody = match.group(4)!;
        final String trailingText = match.group(5)!;
        return '[$outerRule[$textBefore$innerBody$trailingText]';
      });
    }

    final List<TextSpan> spans = [];
    final StringBuffer buf = StringBuffer();

    Color colorForRule(String raw) {
      String rule = raw;
      final int colon = rule.indexOf(':');
      if (colon != -1) {
        rule = rule.substring(0, colon);
      }
      rule = rule.trim();
      return AppTheme.tajweedColors[rule] ?? colorStack.last;
    }

    TextStyle styleForRule(String ruleKey, TextStyle style) {
      final color = AppTheme.tajweedColors[ruleKey];
      if (color == null) return style;
      return style.copyWith(
        color: color,
        backgroundColor:
            activeKey == ruleKey ? color.withValues(alpha: 0.15) : null,
      );
    }

    GestureRecognizer? recognizerForRule(String ruleKey) {
      if (!learningMode || context == null) return null;

      return TapGestureRecognizer()
        ..onTap = () {
          onTapRule?.call(ruleKey);

          final rule = AppTheme.tajweedRules.firstWhere(
            (r) => r.key == ruleKey,
            orElse: () => AppTheme.tajweedRules.first,
          );

          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder:
                (_) => Padding(
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
                            lang == 'id' ? rule.nameId : rule.nameEn,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang == 'id' ? rule.descriptionId : rule.descriptionEn,
                      ),
                    ],
                  ),
                ),
          ).whenComplete(() => onClosePopup?.call());
        };
    }

    bool isDiacritic(String ch) {
      if (ch.isEmpty) return false;
      final int cp = ch.codeUnitAt(0);
      if ((cp >= 0x064B && cp <= 0x065F) || cp == 0x0670) return true;
      if (cp >= 0x06D6 && cp <= 0x06ED) return true;
      return false;
    }

    String normalizeGlyph(
      String glyph, {
      String? next,
      String? fullText,
      int? index,
    }) {
      if (glyph == 'ٮٰ') {
        return 'ى';
      }
      if (glyph == 'ٱ') {
        if (next == 'ل' || next == 'h') return 'ا';
        if (fullText != null && index != null && fullText.startsWith('[l[', index + 1)) {
          return 'ا';
        }
        return 'ال';
      }
      if (glyph == smallAlef) {
        return daggerAlef;
      }
      return glyph;
    }

    void flushBufferWithTopColor() {
      if (buf.isNotEmpty) {
        final Color top = colorStack.isNotEmpty ? colorStack.last : baseColor;
        final TextStyle topStyle = baseStyle.copyWith(color: top);
        spans.addAll(_fragmentToSpans(buf.toString(), topStyle));
        buf.clear();
      }
    }

    bool removeTrailingFatha() {
      if (buf.isNotEmpty) {
        final String s = buf.toString();
        if (s.endsWith(fatha)) {
          buf.clear();
          if (s.length > 1) buf.write(s.substring(0, s.length - 1));
          return true;
        }
        return false;
      }

      if (spans.isNotEmpty) {
        final TextSpan last = spans.removeLast();
        final String lastText = last.text ?? '';
        if (lastText.isNotEmpty && lastText.endsWith(fatha)) {
          final String trimmed = lastText.substring(0, lastText.length - 1);
          if (trimmed.isNotEmpty) {
            spans.add(
              TextSpan(
                text: trimmed,
                style: last.style,
                recognizer: last.recognizer,
              ),
            );
          }
          return true;
        }
        spans.add(last);
      }
      return false;
    }

    String popTrailingCluster() {
      String popFrom(String source) {
        if (source.isEmpty) return '';
        final runes = source.runes.toList();
        int start = runes.length - 1;
        if (!isDiacritic(String.fromCharCode(runes[start]))) {
          return String.fromCharCode(runes[start]);
        }
        while (start > 0 && isDiacritic(String.fromCharCode(runes[start]))) {
          start--;
        }
        return String.fromCharCodes(runes.sublist(start));
      }

      if (buf.isNotEmpty) {
        final String s = buf.toString();
        final String cluster = popFrom(s);
        if (cluster.isEmpty) return '';
        buf.clear();
        buf.write(s.substring(0, s.length - cluster.length));
        return cluster;
      }

      if (spans.isEmpty) return '';
      final TextSpan last = spans.removeLast();
      final String lastText = last.text ?? '';
      final String cluster = popFrom(lastText);
      if (cluster.isEmpty) {
        spans.add(last);
        return '';
      }
      final String trimmed = lastText.substring(
        0,
        lastText.length - cluster.length,
      );
      if (trimmed.isNotEmpty) {
        spans.add(
          TextSpan(
            text: trimmed,
            style: last.style,
            recognizer: last.recognizer,
          ),
        );
      }
      return cluster;
    }

    String popTrailingTanwin() {
      if (buf.isNotEmpty) {
        final s = buf.toString();
        if (s.isNotEmpty) {
          final runes = s.runes.toList();
          final last = runes.last;
          if (isTanwinCodeUnit(last)) {
            final char = String.fromCharCode(last);
            buf.clear();
            if (runes.length > 1) {
              buf.write(
                String.fromCharCodes(runes.sublist(0, runes.length - 1)),
              );
            }
            return char;
          }
        }
        return '';
      }

      if (spans.isNotEmpty) {
        final TextSpan lastSpan = spans.removeLast();
        final String lastText = lastSpan.text ?? '';
        if (lastText.isNotEmpty) {
          final runes = lastText.runes.toList();
          final lastRune = runes.last;
          if (isTanwinCodeUnit(lastRune)) {
            final char = String.fromCharCode(lastRune);
            final String trimmed =
                runes.length > 1
                    ? String.fromCharCodes(runes.sublist(0, runes.length - 1))
                    : '';
            if (trimmed.isNotEmpty) {
              spans.add(
                TextSpan(
                  text: trimmed,
                  style: lastSpan.style,
                  recognizer: lastSpan.recognizer,
                ),
              );
            }
            return char;
          } else {
            spans.add(lastSpan);
            return '';
          }
        } else {
          spans.add(lastSpan);
          return '';
        }
      }
      return '';
    }

    String ensureSukunIfNeeded(String ruleKey, String innerText) {
      if (!sukunRules.contains(ruleKey)) return innerText;
      if (innerText.isEmpty) return innerText;

      final runes = innerText.runes.toList();
      int idx = 0;
      while (idx < runes.length &&
          isDiacritic(String.fromCharCode(runes[idx]))) {
        idx++;
      }
      if (idx >= runes.length) return innerText; // nothing to do

      if (idx + 1 < runes.length &&
          String.fromCharCode(runes[idx + 1]) == sukunChar) {
        return innerText;
      }

      if (idx + 1 < runes.length &&
          isDiacritic(String.fromCharCode(runes[idx + 1]))) {
        return innerText;
      }

      final before = String.fromCharCodes(runes.sublist(0, idx + 1));
      final after =
          idx + 1 < runes.length
              ? String.fromCharCodes(runes.sublist(idx + 1))
              : '';
      return '$before$sukunChar$after';
    }

    int i = 0;
    while (i < text.length) {
      final String ch = text[i];
      final nextChar = (i + 1 < text.length) ? text[i + 1] : null;

      if (ch == '[') {
        final int end = text.indexOf(']', i);
        if (end == -1) {
          buf.write(ch);
          i += 1;
          continue;
        }

        final String inside = text.substring(i + 1, end);

        if (inside.isEmpty) {
          flushBufferWithTopColor();
          if (colorStack.length > 1) {
            colorStack.removeLast();
          }
          i = end + 1;
          continue;
        }

        final int innerOpen = inside.indexOf('[');
        if (innerOpen != -1) {
          String ruleName = inside.substring(0, innerOpen);
          String ruleKey = ruleName;
          final int colon = ruleName.indexOf(':');
          if (colon != -1) ruleKey = ruleName.substring(0, colon).trim();
          String innerText = inside.substring(innerOpen + 1);

          if (innerText.length >= 2 &&
              innerText[0] == fatha &&
              innerText[1] == smallAlef) {
            bool isLafadzAllah = buf.toString().endsWith('ل');
            if (!isLafadzAllah) {
              removeTrailingFatha();
            }
            flushBufferWithTopColor();
            int j = end + 1;
            String diacs = '';
            while (j < text.length && isDiacritic(text[j])) {
              diacs = '$diacs${text[j]}';
              j += 1;
            }
            final Color c = colorForRule(ruleName);
            final TextStyle ruleStyle = styleForRule(
              ruleKey,
              baseStyle.copyWith(color: c),
            );
            spans.addAll(
              _fragmentToSpans(
                '$daggerAlef$diacs',
                ruleStyle,
                recognizer: recognizerForRule(ruleKey),
              ),
            );
            i = j;
            continue;
          }

          // PERBAIKAN TAMBAHAN: Eksekusi normalizeGlyph per-karakter jika itu berupa string panjang
          if (innerText.isNotEmpty) {
            String normalizedInner = '';
            for (int k = 0; k < innerText.length; k++) {
              String charToNorm = innerText[k];
              String? nxt = (k + 1 < innerText.length) ? innerText[k + 1] : nextChar;
              normalizedInner += normalizeGlyph(charToNorm, next: nxt, fullText: text, index: i + 1 + innerOpen + 1 + k);
            }
            innerText = normalizedInner;
          }

          if (innerText.isNotEmpty && isDiacritic(innerText[0])) {
            final String previousCluster = popTrailingCluster();
            if (previousCluster.isNotEmpty) {
              innerText = '$previousCluster$innerText';
            }
          }

          if (transferTanwinRules.contains(ruleKey)) {
            final String movedTanwin = popTrailingTanwin();
            if (movedTanwin.isNotEmpty) {
              innerText = '$innerText$movedTanwin';
            }
          }

          int j = end + 1;
          while (j < text.length && (isDiacritic(text[j]))) {
            innerText = '$innerText${text[j]}';
            j += 1;
          }

          innerText = ensureSukunIfNeeded(ruleKey, innerText);

          flushBufferWithTopColor();

          final Color c = colorForRule(ruleName);
          final TextStyle ruleStyle = styleForRule(
            ruleKey,
            baseStyle.copyWith(color: c),
          );

          if (innerText.isNotEmpty) {
            spans.addAll(
              _fragmentToSpans(
                innerText,
                ruleStyle,
                recognizer: recognizerForRule(ruleKey),
              ),
            );
          }

          i = j;
          continue;
        }

        flushBufferWithTopColor();
        final Color newColor = colorForRule(inside);
        colorStack.add(newColor);
        i = end + 1;
      } else {
        buf.write(normalizeGlyph(ch, next: nextChar, fullText: text, index: i));
        i += 1;
      }
    }

    flushBufferWithTopColor();
    return spans;
  }
}