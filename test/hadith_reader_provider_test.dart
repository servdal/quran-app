import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/providers/hadith_reader_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'bookmarks distinguish collections, survive reload, and remove only one identity',
    () async {
      final reader = HadithReaderNotifier();
      await Future.wait([
        reader.toggleBookmark('bukhari', 1),
        reader.toggleBookmark('muslim', 1),
      ]);
      expect(reader.state.bookmarks, {'bukhari:1', 'muslim:1'});
      reader.dispose();
      final reopened = HadithReaderNotifier();
      await reopened.ready;
      expect(reopened.state.bookmarks, {'bukhari:1', 'muslim:1'});
      await reopened.toggleBookmark('bukhari', 1);
      expect(reopened.state.bookmarks, {'muslim:1'});
      reopened.dispose();
    },
  );

  test(
    'updates before initial load preserve saved bookmarks and display settings',
    () async {
      SharedPreferences.setMockInitialValues({
        HadithReaderNotifier.storageKey: jsonEncode({
          'bookmarks': ['nasai:9'],
          'font': 'KFGQPC',
          'mode': 'both',
          'arabic_size': 42,
        }),
      });
      final reader = HadithReaderNotifier();
      await reader.toggleBookmark('bukhari', 2);
      expect(reader.state.bookmarks, {'nasai:9', 'bukhari:2'});
      expect(reader.state.font, 'KFGQPC');
      expect(reader.state.mode, HadithTextMode.both);
      await reader.setDisplay(translationSize: 25);
      reader.dispose();
      final reopened = HadithReaderNotifier();
      await reopened.ready;
      expect(reopened.state.arabicSize, 42);
      expect(reopened.state.translationSize, 25);
      expect(reopened.state.bookmarks, {'nasai:9', 'bukhari:2'});
      reopened.dispose();
    },
  );

  test(
    'invalid persisted choices fall back and sizes stay within supported ranges',
    () async {
      final state = HadithReaderState.fromJson({
        'bookmarks': ['unknown:1', 'muslim:0', 'bukhari:3', null],
        'mode': 'invalid',
        'font': 'invalid',
        'arabic_size': 999,
        'translation_size': 2,
      });
      expect(state.bookmarks, {'bukhari:3'});
      expect(state.mode, HadithTextMode.tabs);
      expect(state.font, 'LPMQ');
      expect(state.arabicSize, 60);
      expect(state.translationSize, 12);
      SharedPreferences.setMockInitialValues({
        HadithReaderNotifier.storageKey: 'not json',
      });
      final reader = HadithReaderNotifier();
      await reader.ready;
      await reader.toggleBookmark('muslim', 1);
      expect(reader.state.bookmarks, {'muslim:1'});
      reader.dispose();
    },
  );
}
