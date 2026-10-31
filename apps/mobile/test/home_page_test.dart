import 'package:cosmetic_map/core/error/failures.dart';
import 'package:cosmetic_map/features/explore/data/datasources/place_preview_data.dart';
import 'package:cosmetic_map/features/explore/data/datasources/salon_preview_catalog.dart';
import 'package:cosmetic_map/features/explore/domain/entities/place.dart';
import 'package:cosmetic_map/features/explore/domain/repositories/place_repository.dart';
import 'package:cosmetic_map/features/explore/domain/usecases/get_places.dart';
import 'package:cosmetic_map/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:cosmetic_map/features/explore/presentation/pages/salon_profile_page.dart';
import 'package:cosmetic_map/features/explore/presentation/pages/salon_details_page.dart';
import 'package:cosmetic_map/features/home/presentation/pages/home_page.dart';
import 'package:cosmetic_map/features/home/presentation/pages/popular_salons_page.dart';
import 'package:cosmetic_map/features/home/presentation/pages/popular_services_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final class _PreviewPlaces implements PlaceRepository {
  @override
  Future<Either<Failure, List<Place>>> getPlaces() async =>
      Right(PlacePreviewData.models.map((model) => model.toEntity()).toList());
}

void main() {
  test('demo catalog reports its cheapest service and nearest slot', () {
    final place = PlacePreviewData.models.first.toEntity();
    final catalog = SalonPreviewCatalog.forPlace(place)!;
    final dates = SalonPreviewCatalog.bookingDates(DateTime(2026, 10, 27));

    expect(dates.first, DateTime(2026, 10, 28));
    expect(catalog.minPrice, 100000);
    final (date, time) = catalog.nearestSlot(dates)!;
    expect(date, dates.first);
    expect(
      catalog.specialists.any(
        (specialist) =>
            SalonPreviewCatalog.slotsFor(specialist, date).first == time,
      ),
      isTrue,
    );
  });

  test('services are grouped across salons with their lowest price', () {
    final places = PlacePreviewData.models
        .map((model) => model.toEntity())
        .toList();
    final offers = SalonPreviewCatalog.offersFor(places);
    final lashes = offers.singleWhere((offer) => offer.service.id == 'lashes');

    expect(offers, hasLength(7));
    expect(lashes.salons, hasLength(places.length));
    expect(lashes.minPrice, 120000);
  });

  testWidgets('see all salons opens the salon list, not the map', (
    tester,
  ) async {
    await _pumpHome(tester);

    await _tapSeeAll(tester, 'home-salons-all');

    expect(find.byType(PopularSalonsPage), findsOneWidget);
    // Two salons per row.
    final first = find.byKey(const Key('salon-tile--1'));
    final second = find.byKey(const Key('salon-tile--2'));
    final third = find.byKey(const Key('salon-tile--3'));
    expect(tester.getTopLeft(second).dy, tester.getTopLeft(first).dy);
    expect(
      tester.getTopLeft(second).dx,
      greaterThan(tester.getTopLeft(first).dx),
    );
    expect(tester.getTopLeft(third).dx, tester.getTopLeft(first).dx);
    expect(
      tester.getTopLeft(third).dy,
      greaterThan(tester.getTopLeft(first).dy),
    );
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.byType(SalonProfilePage), findsOneWidget);
  });

  testWidgets('see all services opens the service list', (tester) async {
    await _pumpHome(tester);

    await _tapSeeAll(tester, 'home-services-all');

    expect(find.byType(PopularServicesPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('service-tile-lashes')));
    await tester.pumpAndSettle();
    expect(find.byType(ServiceSalonsPage), findsOneWidget);
    expect(find.text('Наращивание ресниц'), findsWidgets);
  });

  testWidgets('a service card lists salons and books that service', (
    tester,
  ) async {
    await _pumpHome(tester);
    final manicure = find.byKey(const Key('home-service-manicure'));

    await _scrollTo(tester, manicure);
    await tester.tap(manicure);
    await tester.pumpAndSettle();
    expect(find.byType(ServiceSalonsPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('salon-row-book--1')));
    await tester.pumpAndSettle();
    expect(find.byType(SalonDetailsPage), findsOneWidget);
    expect(find.text('Шаг 2 из 3 · Выбор времени'), findsOneWidget);
  });

  testWidgets('salons keep the data order and open the salon page', (
    tester,
  ) async {
    await _pumpHome(tester);

    final first = find.byKey(const Key('home-salon--1'));
    final second = find.byKey(const Key('home-salon--2'));
    expect(first, findsOneWidget);
    expect(tester.getTopLeft(first).dx, lessThan(tester.getTopLeft(second).dx));

    await tester.ensureVisible(first);
    await tester.pumpAndSettle();
    await tester.tap(first);
    await tester.pumpAndSettle();
    expect(find.byType(SalonProfilePage), findsOneWidget);
  });

  testWidgets('hero carousel has the promo plus three salon slides', (
    tester,
  ) async {
    await _pumpHome(tester);

    for (var index = 0; index < 4; index++) {
      expect(find.byKey(Key('home-hero-dot-$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('home-hero-dot-4')), findsNothing);
  });

  testWidgets('category shortcut opens search filtered by that service', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('home-category-home.nails')));
    await tester.pumpAndSettle();
    expect(find.text('search: Маникюр'), findsOneWidget);
  });

  testWidgets('search field opens search without a filter', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const Key('home-search')));
    await tester.pumpAndSettle();
    expect(find.text('search: '), findsOneWidget);
  });
}

Future<void> _tapSeeAll(WidgetTester tester, String key) async {
  final seeAll = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(InkWell),
  );
  await _scrollTo(tester, seeAll);
  await tester.tap(seeAll);
  await tester.pumpAndSettle();
}

/// Scrolls the home page until [finder] is built and on screen; sections
/// below the fold are built lazily.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(HomePage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (_, __) => BlocProvider(
          create: (_) =>
              ExploreBloc(GetPlaces(_PreviewPlaces()))
                ..add(const ExploreEvent.started()),
          child: const HomePage(),
        ),
      ),
      GoRoute(
        path: '/search',
        builder: (_, state) =>
            Text('search: ${state.uri.queryParameters['category'] ?? ''}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}
