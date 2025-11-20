import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

/// TajweedParser (edukatif)
///
/// - Menjaga semua harakat dari JSON kecuali menambahkan SUKUN untuk rule tertentu (p,w,u,f)
///   jika huruf di dalam block tidak punya harakat.
/// - Memindahkan TANWIN dari fragmen sebelumnya ke dalam fragmen saat rule
///   berada di daftar transferTanwinRules (a, u, w, i).
/// - Mewarnai seluruh fragmen (huruf + harakat). Tanwin diberi opacity 50%.
final List<Color> colorStack = <Color>[Colors.black];
// Helper: split fragment into TextSpans and handle tanwin softness (50% opacity)
bool isTanwinCodeUnit(int cp) {
  // 064B FATHATAN (ً), 064C DAMMATAN (ٌ), 064D KASRATAN (ٍ)
  return cp == 0x064B || cp == 0x064C || cp == 0x064D;
}
List<TextSpan> _fragmentToSpans(String fragment, TextStyle ruleStyle) {
  final List<TextSpan> out = [];
  final runes = fragment.runes.toList();
  for (var r in runes) {
    final ch = String.fromCharCode(r);
    if (isTanwinCodeUnit(r)) {
      final Color baseColor = ruleStyle.color ?? colorStack.last;
      final double newOpacity = (baseColor.opacity * 0.5).clamp(0.0, 1.0);
      final Color tanwinColor = baseColor.withOpacity(newOpacity);
      out.add(TextSpan(text: ch, style: ruleStyle.copyWith(color: tanwinColor)));
    } else {
      out.add(TextSpan(text: ch, style: ruleStyle));
    }
  }
  return out;
}
class TajweedParser {
  static const String sukunChar = 'ْ';
  static const String daggerAlef = 'ٰ';
  static const String smallAlef = 'ٲ';
  static const String fatha = 'َ';
  
    
  // Rules that require adding explicit sukun to the inner letter when missing
  // (extended per user request to include 'u' and 'f')
  static const Set<String> sukunRules = {'p', 'w', 'u', 'f'};

  // Rules that require moving/attaching tanwin from previous fragment to current letter
  static const Set<String> transferTanwinRules = {'a', 'u', 'w', 'i'};
  
  static List<TextSpan> parse(String text, TextStyle baseStyle) {
    if (text.isEmpty) return [];

    // small pre-normalizations (non-destructive)
    text = text.replaceAll('[o[َ[s[اْ]]', 'َا۟');
    text = text.replaceAll('[s[اْ]]', 'ا۟');
    text = text.replaceAll('[s[اْ]‌ۖ', 'اۖ');
    text = text.replaceAll('[s[اْ]‌ۚ', 'اْ');
    text = text.replaceAll('[s[اْ]ۗ', 'اۗ');
    text = text.replaceAll('[s[اْ]ۘ', 'اۘ');
    text = text.replaceAll('[s[اْ]ۙ', 'اۙ');
    text = text.replaceAll('[s[اْ]ۚ', 'اۚ');
    text = text.replaceAll('[s[اْ]ۛ', 'اۛ');
    text = text.replaceAll('[s[اْ]ۜ', 'اۜ');

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
      if (glyph == smallAlef) {
        return daggerAlef;
      }
      return glyph;
    }

    void flushBufferWithTopColor() {
      if (buf.isNotEmpty) {
        final Color top = colorStack.isNotEmpty ? colorStack.last : (baseStyle.color ?? Colors.black);
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
            spans.add(TextSpan(text: trimmed, style: last.style));
          }
          return true;
        }
        spans.add(last);
      }
      return false;
    }

    

    // Try to remove and return a trailing tanwin char (if any) from buffer or last span.
    // Returns the tanwin character removed or ''.
    String _popTrailingTanwin() {
      // check buffer first
      if (buf.isNotEmpty) {
        final s = buf.toString();
        if (s.isNotEmpty) {
          final runes = s.runes.toList();
          final last = runes.last;
          if (isTanwinCodeUnit(last)) {
            final char = String.fromCharCode(last);
            buf.clear();
            if (runes.length > 1) {
              buf.write(String.fromCharCodes(runes.sublist(0, runes.length - 1)));
            }
            return char;
          }
        }
        return '';
      }

      // then check spans from the end to find a trailing char that is tanwin
      if (spans.isNotEmpty) {
        // Look at last TextSpan. Might be part of multi-span fragment; check last.
        final TextSpan lastSpan = spans.removeLast();
        final String lastText = lastSpan.text ?? '';
        if (lastText.isNotEmpty) {
          final runes = lastText.runes.toList();
          final lastRune = runes.last;
          if (isTanwinCodeUnit(lastRune)) {
            final char = String.fromCharCode(lastRune);
            final String trimmed = runes.length > 1 ? String.fromCharCodes(runes.sublist(0, runes.length - 1)) : '';
            if (trimmed.isNotEmpty) {
              // put trimmed back
              spans.add(TextSpan(text: trimmed, style: lastSpan.style));
            }
            return char;
          } else {
            // no tanwin in last span, put it back
            spans.add(lastSpan);
            return '';
          }
        } else {
          // empty last text - just put back
          spans.add(lastSpan);
          return '';
        }
      }
      return '';
    }

    // Add sukun to the innerText when needed: if the first base letter lacks diacritic
    // we append sukunChar. naive but practical: if innerText's first rune is letter and
    // second rune is not diacritic, append sukun.
    String _ensureSukunIfNeeded(String ruleKey, String innerText) {
      if (!sukunRules.contains(ruleKey)) return innerText;
      if (innerText.isEmpty) return innerText;

      final runes = innerText.runes.toList();
      // find first "base letter" (skip leading diacritics if any; though unlikely)
      int idx = 0;
      while (idx < runes.length && isDiacritic(String.fromCharCode(runes[idx]))) {
        idx++;
      }
      if (idx >= runes.length) return innerText; // nothing to do

      // if after base letter there is an explicit sukun already, do nothing
      if (idx + 1 < runes.length && String.fromCharCode(runes[idx + 1]) == sukunChar) {
        return innerText;
      }

      // if there is any diacritic immediately after the base letter (like fatha, dhamma, kasra, tanwin),
      // we should NOT add sukun because it already has harakat.
      if (idx + 1 < runes.length && isDiacritic(String.fromCharCode(runes[idx + 1]))) {
        return innerText;
      }

      // otherwise, append sukun after the base letter.
      // Build new string inserting sukun after first base letter
      final before = String.fromCharCodes(runes.sublist(0, idx + 1));
      final after = idx + 1 < runes.length ? String.fromCharCodes(runes.sublist(idx + 1)) : '';
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

        // empty inside -> pop color state
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
          // rule with inner text: ruleName[innerText
          String ruleName = inside.substring(0, innerOpen);
          String ruleKey = ruleName;
          final int colon = ruleName.indexOf(':');
          if (colon != -1) ruleKey = ruleName.substring(0, colon).trim();
          String innerText = inside.substring(innerOpen + 1);

          // if innerText begins with fatha+smallAlef -> special daggerAlef handling
          if (innerText.length >= 2 && innerText[0] == fatha && innerText[1] == smallAlef) {
            final bool hadF = removeTrailingFatha();
            flushBufferWithTopColor();
            int j = end + 1;
            String diacs = '';
            while (j < text.length && isDiacritic(text[j])) {
              diacs = '$diacs${text[j]}';
              j += 1;
            }
            final Color c = colorForRule(ruleName);
            final TextStyle ruleStyle = baseStyle.copyWith(color: c);
            spans.addAll(_fragmentToSpans('$daggerAlef$diacs', ruleStyle));
            i = j;
            continue;
          }

          // minimal normalization (non-destructive)
          innerText = normalizeGlyph(innerText, next: nextChar, fullText: text, index: i);

          // *** FIX ORDER: first try to pop tanwin from previous fragment if rule requires transfer
          if (transferTanwinRules.contains(ruleKey)) {
            final String movedTanwin = _popTrailingTanwin();
            if (movedTanwin.isNotEmpty) {
              innerText = '$innerText$movedTanwin';
            }
          }

          // gather trailing diacritics after block
          int j = end + 1;
          while (j < text.length && isDiacritic(text[j])) {
            innerText = '$innerText${text[j]}';
            j += 1;
          }

          // 2) If ruleKey is in sukunRules, ensure innerText has sukun on base letter when appropriate
          innerText = _ensureSukunIfNeeded(ruleKey, innerText);

          // flush buffer (with top color)
          flushBufferWithTopColor();

          final Color c = colorForRule(ruleName);
          final TextStyle ruleStyle = baseStyle.copyWith(color: c);

          if (innerText.isNotEmpty) {
            spans.addAll(_fragmentToSpans(innerText, ruleStyle));
          }

          i = j;
          continue;
        }

        // opening color token like [h:123] or [h]
        flushBufferWithTopColor();
        final Color newColor = colorForRule(inside);
        colorStack.add(newColor);
        i = end + 1;
      } else {
        // plain char outside rule block
        buf.write(normalizeGlyph(ch, next: nextChar, fullText: text, index: i));
        i += 1;
      }
    }

    // flush remaining buffer
    flushBufferWithTopColor();
    return spans;
  }
}
