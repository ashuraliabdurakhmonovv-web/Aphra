import 'package:cosmetic_map/app/theme/app_theme.dart';
import 'package:cosmetic_map/features/profile/presentation/pages/payments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows credits, the card and the history', (tester) async {
    await _pumpPayments(tester);

    expect(find.text('profile.payments'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.byKey(const Key('payments-card-4821')), findsOneWidget);
    expect(find.text('profile.main_card'), findsOneWidget);
    expect(find.byKey(const Key('payments-add-card')), findsOneWidget);
    expect(find.text('profile.payment_history'), findsOneWidget);
    expect(find.text('-14'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    expect(find.byKey(const Key('payments-operation-2')), findsOneWidget);
  });

  testWidgets('actions explain they wait for a payment system', (tester) async {
    await _pumpPayments(tester);
    Future<void> tap(String key) async {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    await tap('payments-buy');
    expect(find.text('profile.credits_soon'), findsOneWidget);

    for (final key in [
      'payments-manage',
      'payments-add-card',
      'payments-methods',
    ]) {
      await tap(key);
      expect(find.text('profile.cards_soon'), findsOneWidget, reason: key);
    }
  });

  testWidgets('fits a small screen', (tester) async {
    await _pumpPayments(tester, size: const Size(960, 1704));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('payments-card-4821')), findsOneWidget);
  });
}

Future<void> _pumpPayments(
  WidgetTester tester, {
  Size size = const Size(1206, 2622),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const PaymentsPage()),
  );
  await tester.pumpAndSettle();
}
