import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/screens/language_selector_screen.dart';
import 'package:quran_app/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings tiles paint and respond inside decorated cards', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LanguageSelectorScreen())),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final dark = find.widgetWithText(RadioListTile<AppThemeType>, 'Dark');
    await tester.ensureVisible(dark);
    await tester.tap(dark);
    await tester.pumpAndSettle();
    expect(tester.widget<RadioListTile<AppThemeType>>(dark).groupValue, AppThemeType.dark);
    expect(tester.takeException(), isNull);
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
