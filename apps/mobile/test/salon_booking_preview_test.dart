import 'package:cosmetic_map/core/di/service_locator.dart';
import 'package:cosmetic_map/features/appointments/data/datasources/appointment_mock_data_source.dart';
import 'package:cosmetic_map/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cosmetic_map/features/appointments/domain/entities/appointment.dart';
import 'package:cosmetic_map/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:cosmetic_map/features/explore/data/datasources/place_preview_data.dart';
import 'package:cosmetic_map/features/explore/data/datasources/salon_preview_catalog.dart';
import 'package:cosmetic_map/features/explore/domain/entities/place.dart';
import 'package:cosmetic_map/features/explore/presentation/pages/salon_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  setUp(() {
    sl.registerLazySingleton<AppointmentRepository>(
      () => AppointmentRepositoryImpl(AppointmentMockDataSourceImpl()),
    );
  });
  tearDown(sl.reset);

  test('every preview salon offers multiple services and specialists', () {
    for (final model in PlacePreviewData.models) {
      final place = Place(
        id: model.id,
        name: model.name,
        address: model.address,
        latitude: model.latitude,
        longitude: model.longitude,
        rating: model.rating,
        isVerified: model.isVerified,
      );
      final catalog = SalonPreviewCatalog.forPlace(place)!;
      expect(catalog.services.length, greaterThanOrEqualTo(5));
      for (final service in catalog.services) {
        expect(catalog.specialistsFor(service).length, greaterThanOrEqualTo(2));
        expect(service.deposit + service.remaining, service.price);
        expect(service.deposit, service.price * 50 ~/ 100);
      }
    }
    expect(
      SalonPreviewCatalog.forPlace(
        const Place(
          id: 42,
          name: 'API salon',
          address: 'Tashkent',
          latitude: 41.3,
          longitude: 69.2,
          rating: 4.5,
          isVerified: true,
        ),
      ),
      isNull,
    );
  });

  test('demo source rejects duplicate specialist time', () async {
    final source = AppointmentMockDataSourceImpl();
    final appointment = Appointment(
      id: 'new-demo',
      serviceName: 'Укладка',
      salonName: 'Nur Beauty',
      masterName: 'Дилноза',
      imageAsset: 'assets/images/salons/nur_beauty.jpg',
      startsAtUtc: DateTime.now().toUtc().add(const Duration(days: 2)),
      salonUtcOffset: const Duration(hours: 5),
      durationMinutes: 60,
      price: 220000,
      priceIsCredits: false,
      status: AppointmentStatus.awaitingPayment,
      depositPercent: 30,
      isDemoBooking: true,
    );
    await source.createDemoBooking(appointment);
    expect((await source.getAppointments()).contains(appointment), isTrue);
    expect(
      () => source.createDemoBooking(appointment),
      throwsA(isA<Exception>()),
    );
    final repeated = await source.repeat(
      appointmentId: appointment.id,
      startsAtUtc: appointment.startsAtUtc.add(const Duration(days: 1)),
    );
    expect(repeated.depositPercent, 30);
    expect(repeated.isDemoBooking, isTrue);
  });

  test('credit price follows the design: 34 by day, 41 in the evening', () {
    final manicure = SalonPreviewCatalog.forPlace(_place)!.services.first;

    expect(manicure.creditsAt('10:00'), 34);
    expect(manicure.creditsAt('17:00'), 34);
    expect(manicure.creditsAt('18:00'), 41);
  });

  testWidgets('client books styling with credits and gets a QR ticket', (
    tester,
  ) async {
    await _pumpBookingPage(tester);
    expect(find.text('Шаг 1 из 3 · Выбор услуги'), findsOneWidget);

    await _reveal(tester, find.byKey(const Key('service-styling')));
    await tester.tap(find.byKey(const Key('service-styling')));
    await tester.pumpAndSettle();
    expect(find.text('Шаг 2 из 3 · Выбор времени'), findsOneWidget);
    expect(_action(tester).onPressed, isNull);

    final catalog = SalonPreviewCatalog.forPlace(_place)!;
    final styling = catalog.services.firstWhere((item) => item.id == 'styling');
    final stylist = catalog.specialistsFor(styling).first;
    await _reveal(tester, find.byKey(Key('specialist-${stylist.id}')));
    await tester.tap(find.byKey(Key('specialist-${stylist.id}')));
    await tester.pumpAndSettle();

    final tomorrow = _tomorrow();
    final slot = SalonPreviewCatalog.slotsFor(stylist, tomorrow).first;
    await _reveal(tester, find.byKey(Key('slot-$slot')));
    await tester.tap(find.byKey(Key('slot-$slot')));
    await tester.pumpAndSettle();

    final credits = styling.creditsAt(slot);
    expect(find.text('Подтвердить запись · $credits кр.'), findsOneWidget);
    await _tapAction(tester);

    final day = tomorrow.day.toString().padLeft(2, '0');
    expect(find.text('Шаг 3 из 3 · Подтверждение'), findsOneWidget);
    expect(find.text('Запись подтверждена'), findsOneWidget);
    expect(find.text('Оплачено кредитами'), findsOneWidget);
    expect(
      find.text('Билет #NB-$day${slot.replaceAll(':', '')}'),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Мои записи'), findsOneWidget);

    final appointment = await _demoBooking(tester);
    expect(appointment.status, AppointmentStatus.confirmed);
    expect(appointment.priceIsCredits, isTrue);
    expect(appointment.price, credits);
    expect(appointment.masterName, stylist.name);
  });

  testWidgets('online payment books any free master with a 50% test deposit', (
    tester,
  ) async {
    await _pumpBookingPage(tester, serviceId: 'manicure');
    expect(find.text('Nur Beauty · Любой мастер'), findsOneWidget);

    final tomorrow = _tomorrow();
    final catalog = SalonPreviewCatalog.forPlace(_place)!;
    final nailMasters = catalog.specialistsFor(catalog.services.first);
    final slot = ({
      for (final master in nailMasters)
        ...SalonPreviewCatalog.slotsFor(master, tomorrow),
    }.toList()..sort()).first;
    await _reveal(tester, find.byKey(Key('slot-$slot')));
    await tester.tap(find.byKey(Key('slot-$slot')));
    await tester.pumpAndSettle();
    await _reveal(tester, find.byKey(const Key('method-online')));
    await tester.tap(find.byKey(const Key('method-online')));
    await tester.pumpAndSettle();

    expect(find.text('Подтвердить и оплатить · 75 000 сум'), findsOneWidget);
    await _tapAction(tester);

    expect(find.text('Запись подтверждена'), findsOneWidget);
    expect(find.text('75 000 сум'), findsWidgets);
    final appointment = await _demoBooking(tester);
    expect(appointment.depositPercent, 50);
    expect(appointment.priceIsCredits, isFalse);
    expect(
      nailMasters
          .where(
            (master) =>
                SalonPreviewCatalog.slotsFor(master, tomorrow).contains(slot),
          )
          .map((master) => master.name),
      contains(appointment.masterName),
    );
  });

  testWidgets('paying at the salon books without a prepayment', (tester) async {
    await _pumpBookingPage(tester, serviceId: 'brows');

    await tester.tap(find.byKey(Key('slot-${_firstSlot('brows')}')));
    await tester.pumpAndSettle();
    await _reveal(tester, find.byKey(const Key('method-atSalon')));
    await tester.tap(find.byKey(const Key('method-atSalon')));
    await tester.pumpAndSettle();
    expect(find.text('Подтвердить запись · 100 000 сум'), findsOneWidget);
    await _tapAction(tester);

    expect(find.text('К оплате в салоне'), findsOneWidget);
    final appointment = await _demoBooking(tester);
    expect(appointment.canPayAtSalon, isTrue);
    expect(appointment.depositPercent, 0);
  });

  testWidgets('picking a busy master clears the chosen time', (tester) async {
    await _pumpBookingPage(tester, serviceId: 'manicure');
    final tomorrow = _tomorrow();
    final catalog = SalonPreviewCatalog.forPlace(_place)!;
    final nailMasters = catalog.specialistsFor(catalog.services.first);
    final union = {
      for (final master in nailMasters)
        ...SalonPreviewCatalog.slotsFor(master, tomorrow),
    };
    final (slot, busy) = [
      for (final slot in union)
        for (final master in nailMasters)
          if (!SalonPreviewCatalog.slotsFor(master, tomorrow).contains(slot))
            (slot, master),
    ].first;

    await _reveal(tester, find.byKey(Key('slot-$slot')));
    await tester.tap(find.byKey(Key('slot-$slot')));
    await tester.pumpAndSettle();
    expect(_action(tester).onPressed, isNotNull);

    await _reveal(tester, find.byKey(Key('specialist-${busy.id}')));
    await tester.tap(find.byKey(Key('specialist-${busy.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Nur Beauty · ${busy.name}'), findsOneWidget);
    expect(_action(tester).onPressed, isNull);
  });
}

DateTime _tomorrow() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 1);
}

String _firstSlot(String serviceId) {
  final catalog = SalonPreviewCatalog.forPlace(_place)!;
  final service = catalog.services.firstWhere((item) => item.id == serviceId);
  return ({
    for (final master in catalog.specialistsFor(service))
      ...SalonPreviewCatalog.slotsFor(master, _tomorrow()),
  }.toList()..sort()).first;
}

FilledButton _action(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byKey(const Key('booking-action')));

/// The demo booking just created. The mock source waits on a real timer,
/// outside the fake test clock.
Future<Appointment> _demoBooking(WidgetTester tester) async {
  final booked = (await tester.runAsync(
    () => sl<AppointmentRepository>().getAppointments(),
  ))!;
  return booked
      .getOrElse(() => const [])
      .singleWhere(
        (item) => item.isDemoBooking && item.salonName == 'Nur Beauty',
      );
}

/// Opens the booking page on an iPhone-sized surface; the default 800x600
/// test view leaves too little list height above the sticky booking bar.
Future<void> _pumpBookingPage(WidgetTester tester, {String? serviceId}) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: SalonDetailsPage(place: _place, serviceId: serviceId),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls [finder] fully into view. scrollUntilVisible alone stops as soon as
/// the item is built, which may still leave it under the booking bar.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapAction(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('booking-action')));
  await tester.pumpAndSettle();
}
