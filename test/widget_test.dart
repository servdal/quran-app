// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quran_app/main.dart';

void main() {
  testWidgets('App boots into permission gate', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp(initialLang: null)));
    await tester.pump();

    final hasLoading =
        find.text('Meminta izin perangkat…').evaluate().isNotEmpty;
    final hasGate = find.text('Izin Diperlukan').evaluate().isNotEmpty;

    expect(hasLoading || hasGate, isTrue);
  });
}
