import 'package:cosmetic_map/features/profile/presentation/pages/support_page.dart';
import 'package:cosmetic_map/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _launcher = MethodChannel('plugins.flutter.io/url_launcher');

void main() {
  /// The URLs the page asked to open.
  late List<String> opened;
  var opens = false;

  setUp(() {
    opened = [];
    opens = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, (call) async {
          if (call.method != 'launch') return null;
          opened.add((call.arguments as Map)['url'] as String);
          return opens;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_launcher, null),
  );

  testWidgets('shows the sections of the design', (tester) async {
    await _pumpSupport(tester);

    expect(find.text('support.title'), findsOneWidget);
    expect(find.text('support.banner_title'), findsOneWidget);
    for (final key in ['chat', 'call', 'telegram']) {
      expect(find.byKey(Key('support-$key')), findsOneWidget);
    }
    expect(find.text(SupportContacts.phone), findsOneWidget);
    expect(find.text('@${SupportContacts.telegram}'), findsOneWidget);
    for (final faq in ['reschedule', 'credits', 'cancel', 'productReturn']) {
      expect(find.byKey(Key('support-faq-$faq')), findsOneWidget);
    }
    // The payment question is only in the full list.
    expect(find.byKey(const Key('support-faq-payment')), findsNothing);
    expect(find.byKey(const Key('support-write')), findsOneWidget);
  });

  testWidgets('a question opens its answer', (tester) async {
    await _pumpSupport(tester);

    await tester.tap(find.byKey(const Key('support-faq-credits')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('support-answer-credits')), findsOneWidget);
    expect(find.text('support.questions.credits.answer'), findsOneWidget);
  });

  testWidgets('all questions lists every question', (tester) async {
    await _pumpSupport(tester);

    await tester.tap(find.byKey(const Key('support-all-questions')));
    await tester.pumpAndSettle();
    for (final faq in [
      'reschedule',
      'credits',
      'cancel',
      'productReturn',
      'payment',
    ]) {
      expect(find.byKey(Key('support-faq-$faq')), findsOneWidget);
    }

    await tester.tap(find.byKey(const Key('support-back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('support-faq-payment')), findsNothing);
  });

  testWidgets('the chat offers Telegram until the app has a chat', (
    tester,
  ) async {
    await _pumpSupport(tester);

    await tester.tap(find.byKey(const Key('support-write')));
    await tester.pump();
    expect(find.text('support.chat_soon'), findsOneWidget);
    expect(find.widgetWithText(SnackBarAction, 'support.telegram'), findsOne);
  });

  testWidgets('call and Telegram open the support contacts', (tester) async {
    opens = true;
    await _pumpSupport(tester);

    await tester.tap(find.byKey(const Key('support-call')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('support-telegram')));
    await tester.pumpAndSettle();
    expect(opened, ['tel:+998712000000', 'https://t.me/aphra_support']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a call that cannot start shows the number', (tester) async {
    await _pumpSupport(tester);

    await tester.tap(find.byKey(const Key('support-call')));
    await tester.pumpAndSettle();
    expect(find.text('support.call_failed'), findsOneWidget);
  });
}

Future<void> _pumpSupport(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: const SupportPage()),
  );
  await tester.pumpAndSettle();
}
