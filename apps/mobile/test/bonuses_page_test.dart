import 'package:cosmetic_map/app/theme/app_theme.dart';
import 'package:cosmetic_map/features/profile/presentation/pages/bonuses_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the points and the promo codes', (tester) async {
    await _pumpBonuses(tester);

    expect(find.text('profile.bonuses'), findsOneWidget);
    expect(find.text('1 900'), findsOneWidget);
    expect(find.text('profile.bonus_points'), findsOneWidget);
    expect(find.byKey(const Key('bonuses-code')), findsOneWidget);
    expect(find.byKey(const Key('bonuses-promo-BEAUTY20')), findsOneWidget);
    expect(find.byKey(const Key('bonuses-promo-WELCOME')), findsOneWidget);
  });

  testWidgets('copy puts the code on the clipboard', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await _pumpBonuses(tester);

    await tester.tap(find.byKey(const Key('bonuses-copy-BEAUTY20')));
    await tester.pumpAndSettle();

    expect(copied, ['BEAUTY20']);
    expect(find.text('profile.code_copied'), findsOneWidget);
  });

  testWidgets('apply checks the entered code', (tester) async {
    await _pumpBonuses(tester);
    Future<void> apply(String code) async {
      await tester.enterText(find.byKey(const Key('bonuses-code')), code);
      await tester.tap(find.byKey(const Key('bonuses-apply')));
      await tester.pumpAndSettle();
    }

    await apply('  ');
    expect(find.text('profile.promo_enter'), findsOneWidget);

    await apply('welcome');
    expect(find.text('profile.promo_have'), findsOneWidget);

    await apply('SPRING');
    expect(find.text('profile.promo_soon'), findsOneWidget);
  });
}

Future<void> _pumpBonuses(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const BonusesPage()),
  );
  await tester.pumpAndSettle();
}
