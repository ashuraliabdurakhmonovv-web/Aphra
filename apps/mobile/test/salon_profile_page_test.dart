import 'package:cosmetic_map/features/explore/data/datasources/salon_preview_catalog.dart';
import 'package:cosmetic_map/features/explore/domain/entities/place.dart';
import 'package:cosmetic_map/features/explore/presentation/pages/salon_details_page.dart';
import 'package:cosmetic_map/features/explore/presentation/pages/salon_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _place = Place(
  id: -1,
  name: 'Nur Beauty',
  address: 'ул. Шахрисабз, 12, Ташкент',
  latitude: 41.3225,
  longitude: 69.2639,
  rating: 4.8,
  isVerified: true,
);

void main() {
  testWidgets('shows the salon summary from the demo catalog', (tester) async {
    await _pumpSalon(tester);

    expect(find.text('Nur Beauty'), findsWidgets);
    expect(find.text('Маникюр · Педикюр · Брови'), findsOneWidget);
    expect(find.text('  (126 отзывов)'), findsOneWidget);
    expect(find.text('ул. Шахрисабз, 12 · Ташкент'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);
    expect(find.text('150 000 сум'), findsOneWidget);
  });

  testWidgets('adding a service opens booking on the time step', (
    tester,
  ) async {
    await _pumpSalon(tester);

    await tester.tap(find.byKey(const Key('salon-service-add-manicure')));
    await tester.pumpAndSettle();

    expect(find.byType(SalonDetailsPage), findsOneWidget);
    expect(find.text('Шаг 2 из 3 · Выбор времени'), findsOneWidget);
    expect(find.text('Маникюр'), findsOneWidget);
    expect(_bookingAction(tester).onPressed, isNull);
  });

  testWidgets('choosing a master preselects them and their service', (
    tester,
  ) async {
    await _pumpSalon(tester);
    final master = SalonPreviewCatalog.forPlace(_place)!.specialists.first;

    await tester.tap(find.byKey(Key('salon-master-${master.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Шаг 2 из 3 · Выбор времени'), findsOneWidget);
    expect(find.text('Nur Beauty · ${master.name}'), findsOneWidget);
  });

  testWidgets('book button starts booking from the service list', (
    tester,
  ) async {
    await _pumpSalon(tester);

    await tester.tap(find.byKey(const Key('salon-book')));
    await tester.pumpAndSettle();

    expect(find.text('Шаг 1 из 3 · Выбор услуги'), findsOneWidget);
  });

  testWidgets('tabs scroll to their section', (tester) async {
    await _pumpSalon(tester);
    final reviews = find.text('Отзывы').last;
    final before = tester.getTopLeft(reviews).dy;

    await tester.tap(find.byKey(const Key('salon-tab-reviews')));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(reviews).dy, lessThan(before));
  });
}

FilledButton _bookingAction(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('booking-action')));

Future<void> _pumpSalon(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: SalonProfilePage(place: _place)),
  );
  await tester.pumpAndSettle();
}
