import 'dart:convert';

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

  HadithTranslationService({
    this.client,
    this.endpoint = const String.fromEnvironment(
      'HADITH_TRANSLATE_ENDPOINT',
      defaultValue: 'https://duidev.com/api/translate/hadiths',
    ),
  });

  bool get available => endpoint.isNotEmpty;

  Future<String?> translate(HadithEntry entry, String language) async {
    if (language == 'id') return entry.translation;
    if (language == 'en' && (entry.english?.trim().isNotEmpty ?? false)) {
      return entry.english;
    }
    final key =
        '${entry.bookId}:${entry.number}:$language:${entry.translation}';
    if (_cache.containsKey(key)) return _cache[key];
    if (!available) return null;
    final uri = Uri.parse(endpoint);
    if (uri.scheme != 'https') return null;
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
      final text = row['translation'] ?? row['translated_translation'];
      if (text is! String || text.trim().isEmpty) return null;
      _cache[key] = text.trim();
      return _cache[key];
    } catch (_) {
      return null;
    } finally {
      if (client == null) transport.close();
    }
  }
}
