import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

class TajweedParser {
  static List<TextSpan> parse(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final List<Color> colorStack = <Color>[baseStyle.color ?? Colors.black];
    final StringBuffer buf = StringBuffer();

    const String fatha = 'َ';
    const String daggerAlef = 'ٰ';
    const String smallAlef = 'ٲ';

    Color colorForRule(String raw) {
      String rule = raw;
      final int colon = rule.indexOf(':');
      if (colon != -1) {
        rule = rule.substring(0, colon);
      }
      rule = rule.trim();
      return AppTheme.tajweedColors[rule] ?? colorStack.last;
    }

    bool isDiacritic(String ch) {
      if (ch.isEmpty) return false;
      final int cp = ch.codeUnitAt(0);
      if ((cp >= 0x064B && cp <= 0x065F) || cp == 0x0670) return true;
      if (cp >= 0x06D6 && cp <= 0x06ED) return true;
      return false;
    }

    String normalizeGlyph(String glyph, {String? next, String? fullText, int? index}) {
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
      if (glyph == 'ٲ') {
        return daggerAlef;
      }
      return glyph;
    }

    void flushBuffer() {
      if (buf.isNotEmpty) {
        spans.add(TextSpan(
          text: buf.toString(),
          style: baseStyle.copyWith(color: colorStack.last),
        ));
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
            spans.add(TextSpan(text: trimmed, style: last.style));
          }
          return true;
        }
        spans.add(last);
      }
      return false;
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
          flushBuffer();
          if (colorStack.length > 1) {
            colorStack.removeLast();
          }
          i = end + 1;
          continue;
        }

        final int innerOpen = inside.indexOf('[');
        if (innerOpen != -1) {
          final String ruleName = inside.substring(0, innerOpen);
          String innerText = inside.substring(innerOpen + 1);
          if (innerText.length >= 2 && innerText[0] == fatha && innerText[1] == smallAlef) {
            final bool hadFatha = removeTrailingFatha();
            flushBuffer();
            int j = end + 1;
            String diacs = '';
            while (j < text.length && isDiacritic(text[j])) {
              diacs = '$diacs${text[j]}';
              j += 1;
            }
            final Color c = colorForRule(ruleName);
            spans.add(TextSpan(
              text: '$daggerAlef$diacs',
              style: baseStyle.copyWith(color: c),
            ));

            i = j;
            continue;
          }
          innerText = normalizeGlyph(innerText, next: nextChar, fullText: text, index: i);

          int j = end + 1;
          while (j < text.length && isDiacritic(text[j])) {
            innerText = '$innerText${text[j]}';
            j += 1;
          }

          flushBuffer();
          final Color c = colorForRule(ruleName);
          if (innerText.isNotEmpty) {
            spans.add(TextSpan(
              text: innerText,
              style: baseStyle.copyWith(color: c),
            ));
          }
          i = j;
          continue;
        }

        flushBuffer();
        final Color newColor = colorForRule(inside);
        colorStack.add(newColor);
        i = end + 1;
      } else {
        buf.write(normalizeGlyph(ch, next: nextChar, fullText: text, index: i));
        i += 1;
      }
    }

    flushBuffer();
    return spans;
  }
}
