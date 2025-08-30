import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

class TajweedParser {
  /// Mem-parsing teks tajwid dengan aman menggunakan pemindai manual (parser)
  /// untuk menangani semua format, termasuk yang bersarang kompleks,
  /// tanpa menghilangkan teks atau menampilkan penanda.
  static List<TextSpan> parse(String text, TextStyle baseStyle) {
    List<TextSpan> spans = [];
    // Stack untuk melacak warna saat kita masuk/keluar dari blok tajwid bersarang
    List<Color> colorStack = [baseStyle.color ?? Colors.white];
    StringBuffer currentText = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (text[i] == '[') {
        // Sebuah penanda dimulai. Proses teks biasa yang sudah terkumpul.
        if (currentText.isNotEmpty) {
          spans.add(TextSpan(
            text: currentText.toString(),
            style: baseStyle.copyWith(color: colorStack.last),
          ));
          currentText.clear();
        }

        int endMarker = text.indexOf(']', i);
        if (endMarker == -1) {
          // Kurung buka tanpa penutup, anggap sebagai teks biasa
          currentText.write(text[i]);
          continue;
        }

        String ruleContent = text.substring(i + 1, endMarker);
        
        // Cek apakah ini adalah penanda pembuka blok bersarang (diikuti oleh '[')
        if (endMarker + 1 < text.length && text[endMarker + 1] == '[') {
          String baseRule = ruleContent.split(':')[0];
          Color newColor = AppTheme.tajweedColors[baseRule] ?? colorStack.last;
          colorStack.add(newColor); // Masukkan warna baru ke stack
          i = endMarker + 1; // Lompat ke setelah '[rule['
        } 
        // Cek apakah ini adalah penanda penutup blok bersarang ']]'
        else if (ruleContent.isEmpty) { 
            if (colorStack.length > 1) {
              colorStack.removeLast(); // Keluarkan warna dari stack
            }
            i = endMarker; // Lompat ke setelah ']'
        }
        // Jika tidak keduanya, ini adalah format yang tidak biasa seperti [p[ِي]
        // Kita akan menganggap ini sebagai blok mandiri
        else {
            int innerBracket = ruleContent.indexOf('[');
            if (innerBracket != -1) {
              String rule = ruleContent.substring(0, innerBracket);
              String content = ruleContent.substring(innerBracket + 1);
              
              String baseRule = rule.split(':')[0];
              // #### PERBAIKAN DI SINI ####
              // Menggunakan warna terakhir dari stack sebagai default
              Color color = AppTheme.tajweedColors[baseRule] ?? colorStack.last;
              spans.add(TextSpan(text: content, style: baseStyle.copyWith(color: color)));
            }
            i = endMarker;
        }

      } else {
        // Karakter biasa, tambahkan ke buffer.
        currentText.write(text[i]);
      }
    }

    // Tambahkan sisa teks di akhir.
    if (currentText.isNotEmpty) {
      spans.add(TextSpan(
        text: currentText.toString(),
        style: baseStyle.copyWith(color: colorStack.last),
      ));
    }

    // Fallback darurat jika seluruh proses gagal
    if (spans.isEmpty && text.isNotEmpty) {
       final cleanedText = text.replaceAll(RegExp(r'\[[^\]]*\]'), '');
       spans.add(TextSpan(text: cleanedText, style: baseStyle));
    }

    return spans;
  }
}

