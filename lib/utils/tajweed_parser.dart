import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

class TajweedParser {
  /// Parser teks tajwid untuk memberi warna sesuai aturan tajwid.
  ///
  /// Mendukung dua format:
  /// 1) [rule] ... []   → blok panjang (warna menempel sampai penutup `[]`)
  /// 2) [rule[chars]]   → inline (warna hanya untuk `chars`)
  ///
  /// Catatan:
  /// - rule dapat memiliki suffix id seperti `h:14568`. Kita normalisasi ke `h`.
  /// - ada normalisasi glyph khusus (ٮٰ → ى, ٱ → ال, ٲ → ٰ).
  /// - selain itu ada handling khusus untuk kombinasi `fatha + ٲ` (contoh: `َٲ`)
  ///   sehingga tanda panjang digabungkan ke huruf sebelumnya sebagai dagger-alif (ٰ)
  static List<TextSpan> parse(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final List<Color> colorStack = <Color>[baseStyle.color ?? Colors.black];
    final StringBuffer buf = StringBuffer();

    // Useful codepoints / literals
    const String fatha = 'َ'; // َ
    const String daggerAlef = 'ٰ'; // ٰ (dagger alif)
    const String smallAlef = 'ٲ'; // literal used in source text

    Color colorForRule(String raw) {
      // Normalisasi rule: ambil bagian sebelum ':' lalu trim
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
      // Rentang umum harakat & tanda-tanda Qur'anic combining marks
      if ((cp >= 0x064B && cp <= 0x065F) || cp == 0x0670) return true;
      if (cp >= 0x06D6 && cp <= 0x06ED) return true;
      return false;
    }

    /// Normalisasi glyph tertentu sebelum ditampilkan
    String normalizeGlyph(String glyph, {String? next, String? fullText, int? index}) {
      if (glyph == 'ٮٰ') {
        // ba' tanpa titik + alif kecil → alif maqṣūrah
        return 'ى';
      }
      if (glyph == 'ٱ') {
        // alif wasl → alif-lam (tampilan yang diinginkan)
        if (next == 'ل' || next == 'h') return 'ا';
        if (fullText != null && index != null && fullText.startsWith('[l[', index + 1)) {
          return 'ا';
        }
        return 'ال';
      }
      if (glyph == 'ٲ') {
        // small alif used in source → represent as dagger alif (handled specially)
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

    // jika ada fatha di akhir buffer atau di akhir span terakhir, hapuslah
    // dan kembalikan true. (digunakan untuk menggabungkan fatha+ٲ -> dagger)
    bool removeTrailingFatha() {
      // Cek buffer terlebih dahulu
      if (buf.isNotEmpty) {
        final String s = buf.toString();
        if (s.endsWith(fatha)) {
          buf.clear();
          if (s.length > 1) buf.write(s.substring(0, s.length - 1));
          return true;
        }
        return false;
      }

      // Cek span terakhir
      if (spans.isNotEmpty) {
        final TextSpan last = spans.removeLast();
        final String lastText = last.text ?? '';
        if (lastText.isNotEmpty && lastText.endsWith(fatha)) {
          final String trimmed = lastText.substring(0, lastText.length - 1);
          if (trimmed.isNotEmpty) {
            spans.add(TextSpan(text: trimmed, style: last.style));
          }
          // jika trimmed kosong, kita tidak menaruh kembali span kosong
          return true;
        }
        // kembalikan span jika tidak jadi dihapus
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
          // Tidak ada penutup, anggap ini teks biasa
          buf.write(ch);
          i += 1;
          continue;
        }

        final String inside = text.substring(i + 1, end);

        // CASE A: Penutup blok '[]'
        if (inside.isEmpty) {
          flushBuffer();
          if (colorStack.length > 1) {
            colorStack.removeLast();
          }
          i = end + 1;
          continue;
        }

        // CASE B: Inline [rule[chars]]
        final int innerOpen = inside.indexOf('[');
        if (innerOpen != -1) {
          final String ruleName = inside.substring(0, innerOpen);
          String innerText = inside.substring(innerOpen + 1);

          // Jika inline dimulai dengan fatha + smallAlef (contoh: 'َٲ')
          // maka kita ingin menggabungkannya menjadi daggerAlef (ٰ)
          if (innerText.length >= 2 && innerText[0] == fatha && innerText[1] == smallAlef) {
            // Hapus fatha di akhir buffer/last span bila ada, lalu flush
            final bool hadFatha = removeTrailingFatha();
            flushBuffer();

            // Ambil harakat setelah bracket (mis. kalau ada tashkil jalan)
            int j = end + 1;
            String diacs = '';
            while (j < text.length && isDiacritic(text[j])) {
              diacs = '$diacs${text[j]}';
              j += 1;
            }

            // Tampilkan dagger (yang mewakili alif panjang) dengan warna rule
            final Color c = colorForRule(ruleName);
            spans.add(TextSpan(
              text: '$daggerAlef$diacs',
              style: baseStyle.copyWith(color: c),
            ));

            i = j;
            continue;
          }

          // Normal inline: normalisasi glyph di dalamnya, lalu gabungkan harakat setelah ']'
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

        // CASE C: Pembuka blok [rule]
        flushBuffer();
        final Color newColor = colorForRule(inside);
        colorStack.add(newColor);
        i = end + 1;
      } else {
        // normal char
        buf.write(normalizeGlyph(ch, next: nextChar, fullText: text, index: i));
        i += 1;
      }
    }

    flushBuffer();
    return spans;
  }
}
