import 'dart:convert';

import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HadithTextMode { tabs, arabic, translation, both }

const hadithFonts = ['LPMQ', 'KFGQPC', 'UthmanicHafs'];
const hadithBookIds = [
  'bukhari',
  'muslim',
  'abu-daud',
  'ibnu-majah',
  'nasai',
  'tirmidzi',
];

class HadithReaderState {
  final Set<String> bookmarks;
  final HadithTextMode mode;
  final String font;
  final double? arabicSize;
  final double? translationSize;

  const HadithReaderState({
    this.bookmarks = const {},
    this.mode = HadithTextMode.tabs,
    this.font = 'LPMQ',
    this.arabicSize,
    this.translationSize,
  });

  bool isBookmarked(String book, int number) =>
      bookmarks.contains('$book:$number');

  HadithReaderState copyWith({
    Set<String>? bookmarks,
    HadithTextMode? mode,
    String? font,
    double? arabicSize,
    double? translationSize,
  }) => HadithReaderState(
    bookmarks: Set.unmodifiable(bookmarks ?? this.bookmarks),
    mode: mode ?? this.mode,
    font: font ?? this.font,
    arabicSize: arabicSize ?? this.arabicSize,
    translationSize: translationSize ?? this.translationSize,
  );

  Map<String, Object?> toJson() => {
    'bookmarks': bookmarks.toList()..sort(),
    'mode': mode.name,
    'font': font,
    'arabic_size': arabicSize,
    'translation_size': translationSize,
  };

  factory HadithReaderState.fromJson(Map<String, dynamic> data) {
    double? size(String key, double min, double max) {
      final value = data[key];
      return value is num && value.isFinite
          ? value.toDouble().clamp(min, max)
          : null;
    }

    final bookmarks = <String>{};
    if (data['bookmarks'] is List) {
      for (final value in data['bookmarks'] as List) {
        if (value is! String) continue;
        final parts = value.split(':');
        if (parts.length == 2 &&
            hadithBookIds.contains(parts[0]) &&
            (int.tryParse(parts[1]) ?? 0) > 0) {
          bookmarks.add('${parts[0]}:${int.parse(parts[1])}');
        }
      }
    }
    return HadithReaderState(
      bookmarks: Set.unmodifiable(bookmarks),
      mode: HadithTextMode.values.firstWhere(
        (m) => m.name == data['mode'],
        orElse: () => HadithTextMode.tabs,
      ),
      font:
          hadithFonts.contains(data['font']) ? data['font'] as String : 'LPMQ',
      arabicSize: size('arabic_size', 18, 60),
      translationSize: size('translation_size', 12, 32),
    );
  }
}

class HadithReaderNotifier extends StateNotifier<HadithReaderState> {
  static const storageKey = 'hadith_reader_v1';
  late final Future<void> ready;
  Future<void> _queue = Future.value();

  HadithReaderNotifier() : super(const HadithReaderState()) {
    ready = _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic> && mounted) {
          state = HadithReaderState.fromJson(decoded);
        }
      }
    } on FormatException {
      /* Ignore corrupt saved preferences. */
    }
  }

  Future<void> _update(HadithReaderState Function(HadithReaderState) update) {
    final operation = _queue.then((_) async {
      await ready;
      if (!mounted) return;
      final next = update(state);
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(storageKey, jsonEncode(next.toJson()))) {
        throw StateError('Unable to save hadith preferences');
      }
      if (mounted) state = next;
    });
    _queue = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> toggleBookmark(String book, int number) {
    if (!hadithBookIds.contains(book) || number < 1) {
      throw ArgumentError('Invalid hadith');
    }
    return _update((current) {
      final keys = {...current.bookmarks};
      final key = '$book:$number';
      if (!keys.remove(key)) keys.add(key);
      return current.copyWith(bookmarks: keys);
    });
  }

  Future<void> setDisplay({
    HadithTextMode? mode,
    String? font,
    double? arabicSize,
    double? translationSize,
  }) => _update(
    (current) => current.copyWith(
      mode: mode,
      font: font != null && hadithFonts.contains(font) ? font : null,
      arabicSize: arabicSize?.clamp(18, 60),
      translationSize: translationSize?.clamp(12, 32),
    ),
  );
}

final hadithReaderProvider =
    StateNotifierProvider<HadithReaderNotifier, HadithReaderState>(
      (ref) => HadithReaderNotifier(),
    );
