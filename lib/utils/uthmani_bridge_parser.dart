import 'package:flutter/material.dart';

class UthmaniBridgeParser {
  /// FUNGSI UTAMA: Mengubah tajweed_text ber-tag menjadi List<TextSpan> Rasm Utsmani Polos
  static List<TextSpan> parseToPlainUthmani(String rawTajweedText, TextStyle baseStyle) {
    if (rawTajweedText.isEmpty) return [];

    // TAHAP 1: Membersihkan seluruh tag metadata kustom [h:1[, [l[, [p[, [n[, dll.
    // Kita gunakan Regex untuk menghapus semua huruf latin, angka, dan titik dua yang berada di dekat kurung siku.
    String cleanText = rawTajweedText.replaceAll(RegExp(r'\[[a-zA-Z0-9:]*\['), '');

    // TAHAP 2: Menghapus seluruh kurung siku tutup ']' yang tersisa akibat nested tags
    cleanText = cleanText.replaceAll(']', '');

    // TAHAP 3: Harmonisasi Unicode khusus untuk kesesuaian Font LPMQ Isep Misbah
    cleanText = _deepCleanUthmani(cleanText);

    // TAHAP 4: Kembalikan sebagai TextSpan tunggal yang bersih total
    return [
      TextSpan(text: cleanText, style: baseStyle),
    ];
  }

  /// FUNGSI INTERNAL: Mengatasi anomali harakat bertumpuk & fallback karakter font Kemenag
  static String _deepCleanUthmani(String text) {
    String res = text;

    // 1. Hilangkan invisible characters yang sering merusak pelompatan baris/text-wrapping Flutter
    res = res.replaceAll('\u200c', '').replaceAll('\u200b', '');

    // 2. Solusi Kasus 'Ash-Shiraat' (َٲ):
    // Ubah kombinasi Fathah + Alif Kustom 'ٲ' menjadi Fathah Tegak 'ٰ' standar
    res = res.replaceAll('َٲ', 'ٰ');
    res = res.replaceAll('ٲ', 'ٰ');

    // 3. Solusi Kasus 'Ad-Diin' & Alif Lam Syamsiyah:
    // Ubah Hamzah Washal 'ٱ' yang berdiri sendiri menjadi Alif standar 'ا'
    // agar font LPMQ tidak memunculkan tanda sukun bulat lonjong atau hamzah liar di atas Alif.
    res = res.replaceAll('ٱ', 'ا');

    // 4. Koreksi Tumpangan Harakat (Double Fathah):
    // Jika ada Fathah Normal (َ) bertemu langsung dengan Fathah Tegak (ٰ), hapus fathah normalnya 
    // HANYA jika posisinya bertumpuk tanpa jeda tatweel/kasyida.
    res = res.replaceAll(RegExp(r'َ(?=ٰ)'), '');

    return res;
  }
}