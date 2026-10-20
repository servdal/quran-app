import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quran_app/repository/hadith_repository.dart';
import 'package:quran_app/services/hadith_translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
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
  test(
    'blank English uses server and survives a new service instance offline',
    () async {
      final missing = HadithEntry.fromRow({
        'book_id': 'muslim',
        'book_title': 'Muslim',
        'number': 10,
        'arabic': 'ع',
        'translation': 'Teks Indonesia',
        'english': '   ',
      });
      var requests = 0;
      final client = MockClient((_) async {
        requests++;
        return http.Response(
          '{"data":[{"translation":"English from server"}]}',
          200,
        );
      });
      final first = HadithTranslationService(client: client);
      expect(await first.translate(missing, 'en'), 'English from server');
      final reopened = HadithTranslationService(
        client: MockClient((_) async {
          fail('Saved translation must remain available offline');
        }),
      );
      expect(await reopened.translate(missing, 'en'), 'English from server');
      expect(requests, 1);
    },
  );

  test('concurrent missing translations share one request', () async {
    var requests = 0;
    final service = HadithTranslationService(
      client: MockClient((_) async {
        requests++;
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return http.Response('{"data":[{"translation":"English"}]}', 200);
      }),
    );
    expect(
      await Future.wait([
        service.translate(entry, 'en'),
        service.translate(entry, 'en'),
      ]),
      ['English', 'English'],
    );
    expect(requests, 1);
  });

  test('empty or mismatched server results are retried, never saved', () async {
    var requests = 0;
    final service = HadithTranslationService(
      client: MockClient((_) async {
        requests++;
        return http.Response(
          requests == 1
              ? '{"data":[{"translation":"   "}]}'
              : requests == 2
              ? '{"data":[{"book_id":"muslim","translation":"Wrong entry"}]}'
              : '{"data":[{"translation":"English"}]}',
          200,
        );
      }),
    );
    expect(await service.translate(entry, 'en'), isNull);
    expect(await service.translate(entry, 'en'), isNull);
    expect(await service.translate(entry, 'en'), 'English');
    expect(requests, 3);
  });

  test('a changed source text requests a new translation', () async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('{"data":[{"translation":"Result"}]}', 200);
    });
    await HadithTranslationService(client: client).translate(entry, 'en');
    final corrected = HadithEntry.fromRow({
      'book_id': entry.bookId,
      'book_title': entry.bookTitle,
      'number': entry.number,
      'arabic': entry.arabic,
      'translation': 'Teks diperbaiki',
    });
    await HadithTranslationService(client: client).translate(corrected, 'en');
    expect(requests, 2);
  });
}
