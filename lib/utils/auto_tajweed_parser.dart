import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/theme/app_theme.dart';

// --- Helper Constants ---
const int cpSukun = 0x0652;
const int cpShadda = 0x0651;
const int cpFatha = 0x064E;
const int cpKasra = 0x0650;
const int cpDhamma = 0x064F;
const int cpFathatan = 0x064B;
const int cpDammatan = 0x064C;
const int cpKasratan = 0x064D;
const int cpAlef = 0x0627;
const int cpYa = 0x064A;
const int cpWaw = 0x0648;
const int cpNun = 0x0646;
const int cpMim = 0x0645;
const int cpBa = 0x0628;

bool _isTanwin(int cp) =>
    cp == cpFathatan || cp == cpDammatan || cp == cpKasratan;

// --- Token Class ---
class _Token {
  final String base;
  String diacritics;

  _Token(this.base, [this.diacritics = '']);

  String get full => '$base$diacritics';
  
  int get baseCode => base.runes.first;
  
  // Helpers
  bool get hasSukun => diacritics.contains(String.fromCharCode(cpSukun));
  bool get hasShadda => diacritics.contains(String.fromCharCode(cpShadda));
  bool get hasTanwin => diacritics.runes.any(_isTanwin);
  
  bool get isNun => baseCode == cpNun;
  bool get isMim => baseCode == cpMim;
  
  // Cek Nun Mati (Nun Sukun)
  bool get isNunSakina => isNun && hasSukun; 
  
  bool get hasFatha => diacritics.contains(String.fromCharCode(cpFatha));
  bool get hasKasra => diacritics.contains(String.fromCharCode(cpKasra));
  bool get hasDhamma => diacritics.contains(String.fromCharCode(cpDhamma));
}

/// =============================================================
/// PARSER
/// =============================================================
class AutoTajweedParser {
  // --- Huruf Sets ---
  static final Set<int> _idghamBighunnah =
      {'ي', 'ن', 'م', 'و'}.map((e) => e.codeUnitAt(0)).toSet();

  static final Set<int> _idghamBilaghunnah =
      {'ل', 'ر'}.map((e) => e.codeUnitAt(0)).toSet();

  static final Set<int> _ikhfaLetters =
      {
        'ت', 'ث', 'ج', 'د', 'ذ', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ف', 'ق', 'ك'
      }.map((e) => e.codeUnitAt(0)).toSet();

  static final Set<int> _qalqalahLetters =
      {'ق', 'ط', 'ب', 'ج', 'د'}.map((e) => e.codeUnitAt(0)).toSet();

  static final RegExp _lafzJalalahRegex = RegExp(r'([اال]لّٰ[ه][َُِ]?)');

  static String _normalizeDiacritics(String diacs) {
    if (diacs.isEmpty) return diacs;
    final seen = <int>{};
    final out = <int>[];
    for (final r in diacs.runes) {
      if (!seen.contains(r)) {
        seen.add(r);
        out.add(r);
      }
    }
    return String.fromCharCodes(out);
  }

  /// ===========================================================
  /// PUBLIC API
  /// ===========================================================
  static List<TextSpan> parse(
    String ayaText,
    TextStyle baseStyle, {
    required String lang,
    bool learningMode = false,
    String? activeKey,
    ValueChanged<String>? onTapRule,
    VoidCallback? onClosePopup,
    BuildContext? context,
  }) {
    if (ayaText.isEmpty) return [];
    
    final effectiveStyle = baseStyle.color == null
            ? baseStyle.copyWith(color: Colors.black)
            : baseStyle;

    ayaText = ayaText.replaceAll('\u200c', '').replaceAll('\u200b', '');

    // 1. REKURSIF LAFADZ ALLAH (Prioritas Tertinggi)
    final match = _lafzJalalahRegex.firstMatch(ayaText);
    if (match != null) {
      final List<TextSpan> combinedSpans = [];
      final before = ayaText.substring(0, match.start);
      final lafz = match.group(0)!;
      final after = ayaText.substring(match.end);

      if (before.isNotEmpty) {
        combinedSpans.addAll(parse(before, effectiveStyle, lang: lang, learningMode: learningMode, activeKey: activeKey, onTapRule: onTapRule, onClosePopup: onClosePopup, context: context));
      }

      // Span Lafadz Allah
      combinedSpans.add(
        TextSpan(
          text: lafz, // Langsung isi text, jangan kosong
          style: effectiveStyle.copyWith(
            color: AppTheme.tajweedColors['jalalah'],
            backgroundColor: activeKey == 'jalalah'
                    ? AppTheme.tajweedColors['jalalah']?.withOpacity(0.15)
                    : null,
          ),
          recognizer: _getRecognizer(context, learningMode, 'jalalah', lang, onTapRule, onClosePopup),
        ),
      );

      if (after.isNotEmpty) {
        combinedSpans.addAll(parse(after, effectiveStyle, lang: lang, learningMode: learningMode, activeKey: activeKey, onTapRule: onTapRule, onClosePopup: onClosePopup, context: context));
      }
      return combinedSpans;
    }

    // 2. TOKENISASI UNTUK TAJWID LAIN
    final tokens = _tokenize(ayaText);
    final List<TextSpan> spans = [];
    int i = 0;

    while (i < tokens.length) {
      final curr = tokens[i];
      final next = (i + 1 < tokens.length) ? tokens[i + 1] : null;
      
      String? ruleKey;
      bool involvesNextToken = false; // Flag apakah aturan ini memakan 2 huruf

      // --- LOGIKA DETEKSI (DIPERBAIKI) ---
      
      // A. Ghunnah Musyaddadah (Nun/Mim Tasydid)
      // Cek ini dulu karena hanya melibatkan 1 huruf
      if (curr.hasShadda && (curr.isNun || curr.isMim)) {
        ruleKey = 'g'; // Pastikan key 'g' ada di AppTheme (Ghunnah)
      }
      
      // B. Qalqalah (Hanya huruf Qalqalah + Sukun)
      else if (curr.hasSukun && _qalqalahLetters.contains(curr.baseCode)) {
        ruleKey = 'q';
      }

      // C. Hukum Mim Mati (Mim Sukun + Huruf Berikutnya)
      else if (next != null && curr.isMim && curr.hasSukun) {
        if (next.isMim) {
          ruleKey = 'w'; // Idgham Mimi (Mim ketemu Mim)
          involvesNextToken = true;
        } else if (next.baseCode == cpBa) {
          ruleKey = 'c'; // Ikhfa Syafawi (Mim ketemu Ba)
          involvesNextToken = true;
        }
        // Izhar Syafawi biasanya tidak diwarnai khusus, jadi skip
      }

      // D. Hukum Nun Mati & Tanwin (Syarat Utama: Nun Sukun ATAU Tanwin)
      // INI PERBAIKAN LOGIKA UTAMANYA
      else if (next != null && (curr.isNunSakina || curr.hasTanwin)) {
        final nextCp = next.baseCode;
        
        if (_idghamBighunnah.contains(nextCp)) {
          ruleKey = 'a'; // Idgham Bighunnah
          involvesNextToken = true;
        } else if (_idghamBilaghunnah.contains(nextCp)) {
          ruleKey = 'u'; // Idgham Bilaghunnah
          involvesNextToken = true;
        } else if (nextCp == cpBa) {
          ruleKey = 'i'; // Iqlab
          involvesNextToken = true;
        } else if (_ikhfaLetters.contains(nextCp)) {
          ruleKey = 'f'; // Ikhfa Haqiqi
          involvesNextToken = true;
        }
      }

      // E. Mad Thobi'i (Sederhana)
      else if (next != null) {
        if (curr.hasFatha && next.baseCode == cpAlef) {
           ruleKey = 'n'; // Mad Alif
           involvesNextToken = true;
        } else if (curr.hasKasra && next.baseCode == cpYa && next.hasSukun) {
           ruleKey = 'n'; // Mad Ya
           involvesNextToken = true;
        } else if (curr.hasDhamma && next.baseCode == cpWaw && next.hasSukun) {
           ruleKey = 'n'; // Mad Wau
           involvesNextToken = true;
        }
      }

      // --- PEMBUATAN SPAN ---
      
      if (ruleKey != null) {
        if (involvesNextToken && next != null) {
          // GABUNGKAN TEKS (FIX CLICK ISSUE)
          // Daripada children, kita gabung stringnya agar hit-test area solid
          final combinedText = curr.full + next.full;
          
          spans.add(
            TextSpan(
              text: combinedText,
              style: _style(effectiveStyle, ruleKey, activeKey == ruleKey),
              recognizer: _getRecognizer(context, learningMode, ruleKey, lang, onTapRule, onClosePopup),
            ),
          );
          i += 2; // Lompat 2 token
        } else {
          // Hukum 1 huruf (Qalqalah / Ghunnah)
          spans.add(
            TextSpan(
              text: curr.full,
              style: _style(effectiveStyle, ruleKey, activeKey == ruleKey),
              recognizer: _getRecognizer(context, learningMode, ruleKey, lang, onTapRule, onClosePopup),
            ),
          );
          i += 1; // Lompat 1 token
        }
      } else {
        // Tidak ada hukum tajwid
        spans.add(TextSpan(text: curr.full, style: effectiveStyle));
        i++;
      }
    }

    return spans;
  }

  // --- Helper Methods ---

  static TextStyle _style(TextStyle base, String key, bool active) {
    final color = AppTheme.tajweedColors[key];
    if (color == null) return base;
    return base.copyWith(
      color: color,
      backgroundColor: active ? color.withOpacity(0.18) : null,
    );
  }

  static GestureRecognizer? _getRecognizer(
    BuildContext? context,
    bool enabled,
    String key,
    String lang,
    ValueChanged<String>? onTapRule,
    VoidCallback? onClosePopup,
  ) {
    if (!enabled || context == null) return null;

    return TapGestureRecognizer()
      ..onTap = () {
        onTapRule?.call(key);
        
        final rule = AppTheme.tajweedRules.firstWhere(
          (r) => r.key == key,
          orElse: () => AppTheme.tajweedRules.first,
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
                      lang == 'id' ? rule.nameId : rule.nameEn,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(lang == 'id' ? rule.descriptionId : rule.descriptionEn),
              ],
            ),
          ),
        ).whenComplete(() => onClosePopup?.call());
      };
  }

  static bool _isDiacritic(int cp) {
    // Range harakat umum + shadda + superscript alif
    if (cp >= 0x064B && cp <= 0x0652) return true;
    if (cp == 0x0651) return true; 
    if (cp == 0x0670) return true; 
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