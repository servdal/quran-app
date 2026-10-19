import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_app/repository/hadith_repository.dart';
import 'package:quran_app/services/hadith_translation_service.dart';

void main() {
  final entry = HadithEntry.fromRow({
    'book_id': 'bukhari',
    'book_title': 'Bukhari',
    'number': 1,
    'arabic': 'ع',
    'translation': 'Semua amal tergantung niat.',
  });

  test(
    'local Indonesian needs no request; unavailable backend returns null',
    () async {
      final service = HadithTranslationService(endpoint: '');
      expect(await service.translate(entry, 'id'), entry.translation);
      expect(await service.translate(entry, 'en'), isNull);
    },
  );

  test(
    'remote translations use hadith identities and language-specific cache',
    () async {
      var requests = 0;
      final service = HadithTranslationService(
        endpoint: 'https://example.com/hadiths',
        client: MockClient((request) async {
          requests++;
          final body = jsonDecode(request.body) as Map;
          final item = body['items'][0] as Map;
          expect(item['book_id'], 'bukhari');
          expect(item['hadith_number'], 1);
          expect(item.containsKey('ayah_id'), isFalse);
          return http.Response(
            jsonEncode({
              'data': [
                {'translation': 'Translated ${body['target_lang']}'},
              ],
            }),
            200,
          );
        }),
      );
      expect(await service.translate(entry, 'en'), 'Translated en');
      expect(await service.translate(entry, 'en'), 'Translated en');
      expect(await service.translate(entry, 'fr'), 'Translated fr');
      expect(requests, 2);
    },
  );

  test('verified English is available offline without backend calls', () async {
    final enriched = HadithEntry.fromRow({
      'book_id': 'bukhari',
      'book_title': 'Bukhari',
      'number': 1,
      'arabic': 'ع',
      'translation': 'Indonesia',
      'english': 'Verified English',
    });
    final service = HadithTranslationService(
      endpoint: '',
      client: MockClient((_) async {
        fail('Local English must not request the network');
      }),
    );
    expect(await service.translate(enriched, 'en'), 'Verified English');
    expect(await service.translate(enriched, 'id'), 'Indonesia');
  });

  test('errors do not poison the translation cache', () async {
    var requests = 0;
    final service = HadithTranslationService(
      endpoint: 'https://example.com/hadiths',
      client: MockClient(
        (_) async =>
            ++requests == 1
                ? http.Response('unavailable', 503)
                : http.Response(
                  '{"items":[{"translated_translation":"English"}]}',
                  200,
                ),
      ),
    );
    expect(await service.translate(entry, 'en'), isNull);
    expect(await service.translate(entry, 'en'), 'English');
  });
}
