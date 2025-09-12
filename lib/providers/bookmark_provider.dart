import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

// === PERUBAHAN DI SINI ===
// Menambahkan 'deresan' ke dalam enum
enum BookmarkViewType { surah, page, deresan }

class Bookmark {
  final String type;
  final int surahId;
  final String surahName;
  final int ayahNumber;
  final int? pageNumber;

  Bookmark({
    required this.type,
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'surahId': surahId,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'pageNumber': pageNumber,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        type: json['type'],
        surahId: json['surahId'],
        surahName: json['surahName'],
        ayahNumber: json['ayahNumber'],
        pageNumber: json['pageNumber'],
      );
}

class BookmarkNotifier extends StateNotifier<AsyncValue<Bookmark?>> {
  BookmarkNotifier() : super(const AsyncValue.loading()) {
    _loadBookmark();
  }

  static const String _bookmarkKey = 'bookmark_key';

  Future<void> _loadBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkJson = prefs.getString(_bookmarkKey);
      if (bookmarkJson != null) {
        final bookmarkData =
            Bookmark.fromJson(Map<String, dynamic>.from(json.decode(bookmarkJson)));
        state = AsyncValue.data(bookmarkData);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> setBookmark({
    required int surahId,
    required String surahName,
    required int ayahNumber,
    required int? pageNumber,
    required BookmarkViewType viewType,
  }) async {
    final bookmark = Bookmark(
      type: viewType.name,
      surahId: surahId,
      surahName: surahName,
      ayahNumber: ayahNumber,
      pageNumber: pageNumber,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bookmarkKey, json.encode(bookmark.toJson()));
    state = AsyncValue.data(bookmark);
  }

  Future<void> removeBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookmarkKey);
    state = const AsyncValue.data(null);
  }
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, AsyncValue<Bookmark?>>((ref) {
  return BookmarkNotifier();
});
