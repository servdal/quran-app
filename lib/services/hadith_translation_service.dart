import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/repository/hadith_repository.dart';

final hadithTranslationServiceProvider = Provider(
  (ref) => HadithTranslationService(),
);

/// A separate endpoint keeps hadith identities out of the Quran translation cache.
/// Uses the Core backend with a separate hadith request contract.
class HadithTranslationService {
  final http.Client? client;
  final String endpoint;
  final Map<String, String> _cache = {};
  final Map<String, Future<String?>> _pending = {};

  HadithTranslationService({
    this.client,
    this.endpoint = const String.fromEnvironment(
      'HADITH_TRANSLATE_ENDPOINT',
      defaultValue: 'https://duidev.com/api/translate/hadiths',
    ),
  });

  bool get available => endpoint.isNotEmpty;

  Future<String?> translate(HadithEntry entry, String language) async {
    language = language.trim().toLowerCase();
    if (language == 'id' && entry.translation.trim().isNotEmpty) {
      return entry.translation;
    }
    if (language == 'en' && (entry.english?.trim().isNotEmpty ?? false)) {
      return entry.english;
    }
    if (entry.translation.trim().isEmpty) return null;
    final key =
        'hadith_translation_v1_${sha256.convert(utf8.encode(jsonEncode([endpoint, entry.bookId, entry.number, 'id', language, entry.translation])))}';
    if (_cache.containsKey(key)) return _cache[key];
    if (_pending.containsKey(key)) return _pending[key];
    final request = _translateRemote(entry, language, key);
    _pending[key] = request;
    try {
      return await request;
    } finally {
      _pending.remove(key);
    }
  }

  Future<String?> _translateRemote(
    HadithEntry entry,
    String language,
    String key,
  ) async {
    SharedPreferences? preferences;
    try {
      preferences = await SharedPreferences.getInstance();
      final saved = preferences.getString(key);
      if (saved != null && saved.trim().isNotEmpty) {
        _cache[key] = saved;
        return saved;
      }
    } catch (_) {
      // Local storage must not prevent translation through the server.
    }
    if (!available) return null;
    final uri = Uri.tryParse(endpoint);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    final transport = client ?? http.Client();
    try {
      final response = await transport
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (const String.fromEnvironment(
                'CORE_TRANSLATE_API_KEY',
              ).isNotEmpty)
                'X-API-Key': const String.fromEnvironment(
                  'CORE_TRANSLATE_API_KEY',
                ),
            },
            body: jsonEncode({
              'source_lang': 'id',
              'target_lang': language,
              'items': [
                {
                  'book_id': entry.bookId,
                  'hadith_number': entry.number,
                  'translation': entry.translation,
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final decoded = jsonDecode(response.body);
      final rows =
          decoded is List
              ? decoded
              : decoded is Map
              ? (decoded['data'] ?? decoded['items'] ?? decoded['results'])
              : null;
      if (rows is! List || rows.isEmpty || rows.first is! Map) return null;
      final row = rows.first as Map;
      if ((row['book_id'] != null && row['book_id'] != entry.bookId) ||
          (row['hadith_number'] != null &&
              row['hadith_number'].toString() != entry.number.toString()) ||
          (row['language'] != null && row['language'] != language))
        return null;
      final text = row['translation'] ?? row['translated_translation'];
      if (text is! String || text.trim().isEmpty) return null;
      _cache[key] = text.trim();
      try {
        await preferences?.setString(key, text.trim());
      } catch (_) {
        // The server cache and session result remain usable if the disk is full.
      }
      return _cache[key];
    } catch (_) {
      return null;
    } finally {
      if (client == null) transport.close();
    }
  }
}
