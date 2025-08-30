import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum didefinisikan di SATU tempat saja, di sini.
enum BookmarkViewType { surah, page }

// Model untuk data bookmark
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

  // Method untuk mengubah objek Bookmark menjadi Map (untuk JSON)
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'surahId': surahId,
      'surahName': surahName,
      'ayahNumber': ayahNumber,
      'pageNumber': pageNumber,
    };
  }

  // Factory constructor untuk membuat objek Bookmark dari Map (dari JSON)
  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      type: json['type'],
      surahId: json['surahId'],
      surahName: json['surahName'],
      ayahNumber: json['ayahNumber'],
      pageNumber: json['pageNumber'],
    );
  }
}

// Notifier untuk mengelola state bookmark
class BookmarkNotifier extends StateNotifier<AsyncValue<Bookmark?>> {
  BookmarkNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadBookmark();
  }

  final Ref ref;

  Future<void> _loadBookmark() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarkString = prefs.getString('bookmark');

      if (bookmarkString != null) {
        final bookmark = Bookmark.fromJson(json.decode(bookmarkString));
        state = AsyncValue.data(bookmark);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  // Menyimpan bookmark baru menggunakan JSON
  Future<void> setBookmark(Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bookmark', json.encode(bookmark.toJson()));
    _loadBookmark();
  }

  // Menghapus bookmark
  Future<void> removeBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmark');
    state = const AsyncValue.data(null);
  }
}

final bookmarkProvider = StateNotifierProvider<BookmarkNotifier, AsyncValue<Bookmark?>>((ref) {
  return BookmarkNotifier(ref);
});

