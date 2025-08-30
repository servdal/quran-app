import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

class TajweedParser {
  /// Parser teks tajwid untuk memberi warna sesuai aturan tajwid
  ///
  /// Mendukung dua format:
  /// 1. [rule] ... []   → blok panjang
  /// 2. [rule[char]]    → inline huruf tunggal
  static List<TextSpan> parse(String text, TextStyle baseStyle) {
    List<TextSpan> spans = [];
    List<Color> colorStack = [baseStyle.color ?? Colors.black];
    StringBuffer currentText = StringBuffer();

    int i = 0;
    while (i < text.length) {
      if (text[i] == '[') {
        // Flush teks sebelum marker
        if (currentText.isNotEmpty) {
          spans.add(TextSpan(
            text: currentText.toString(),
            style: baseStyle.copyWith(color: colorStack.last),
          ));
          currentText.clear();
        }

        int endMarker = text.indexOf(']', i);
        if (endMarker == -1) {
          // Tidak ada penutup, treat sebagai teks biasa
          currentText.write(text[i]);
          i++;
          continue;
        }

        String ruleContent = text.substring(i + 1, endMarker);

        // === CASE 1: Inline format [rule[char]] ===
        if (ruleContent.contains("[")) {
          var parts = ruleContent.split("[");
          if (parts.length >= 2) {
            var ruleName = parts[0]; // contoh "m"
            var innerText = parts[1]; // contoh "لٓ"
            Color color = AppTheme.tajweedColors[ruleName] ?? colorStack.last;
            spans.add(TextSpan(
              text: innerText,
              style: baseStyle.copyWith(color: color),
            ));
          }
          i = endMarker + 1;
          continue;
        }

        // === CASE 2: Penutup blok [] ===
        if (ruleContent.isEmpty) {
          if (colorStack.length > 1) {
            colorStack.removeLast();
          }
          i = endMarker + 1;
          continue;
        }

        // === CASE 3: Pembuka blok [rule] ===
        Color newColor = AppTheme.tajweedColors[ruleContent] ?? colorStack.last;
        colorStack.add(newColor);
        i = endMarker + 1;
      } else {
        currentText.write(text[i]);
        i++;
      }
    }

    // Flush sisa teks
    if (currentText.isNotEmpty) {
      spans.add(TextSpan(
        text: currentText.toString(),
        style: baseStyle.copyWith(color: colorStack.last),
      ));
    }

    return spans;
  }
}
