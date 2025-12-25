import 'dart:convert';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BookmarkViewType { surah, page, classic, tafsir }

class Bookmark {
  final BookmarkViewType type;
  final int surahId;
  final String surahName;

  final int? ayahNumber;
  final int? pageNumber;

  Bookmark({
    required this.type,
    required this.surahId,
    required this.surahName,
    this.ayahNumber,
    this.pageNumber,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'surahId': surahId,
    'surahName': surahName,
    'ayahNumber': ayahNumber,
    'pageNumber': pageNumber,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    type: BookmarkViewType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => BookmarkViewType.surah,
    ),
    surahId: json['surahId'],
    surahName: json['surahName'],
    ayahNumber: json['ayahNumber'],
    pageNumber: json['pageNumber'],
  );
}

class BookmarkNotifier extends StateNotifier<Map<String, Bookmark>> {
  BookmarkNotifier() : super({}) {
    _loadBookmarks();
  }

  static const String _bookmarksKey = 'bookmarks_map';

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_bookmarksKey);
    if (jsonString != null) {
      final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
      final Map<String, Bookmark> bookmarks = decodedMap.map(
        (key, value) => MapEntry(key, Bookmark.fromJson(value)),
      );
      if (mounted) {
        state = bookmarks;
      }
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final encodableMap = state.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_bookmarksKey, jsonEncode(encodableMap));
  }

  Future<void> addOrUpdateBookmark(String name, Bookmark bookmark) async {
    final newState = {...state};
    newState[name] = bookmark;
    state = newState;
    await _saveBookmarks();
  }

  Future<void> removeBookmark(String name) async {
    final newState = {...state};
    newState.remove(name);
    state = newState;
    await _saveBookmarks();
  }
}

final bookmarkProvider =
    StateNotifierProvider<BookmarkNotifier, Map<String, Bookmark>>((ref) {
      return BookmarkNotifier();
    });
