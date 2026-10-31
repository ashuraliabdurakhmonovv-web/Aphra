import 'package:cosmetic_map/core/error/failures.dart';
import 'package:cosmetic_map/features/catalog/presentation/pages/catalog_page.dart';
import 'package:cosmetic_map/features/explore/data/datasources/place_preview_data.dart';
import 'package:cosmetic_map/features/explore/domain/entities/place.dart';
import 'package:cosmetic_map/features/explore/domain/repositories/place_repository.dart';
import 'package:cosmetic_map/features/explore/domain/usecases/get_places.dart';
import 'package:cosmetic_map/features/explore/presentation/bloc/explore_bloc.dart';
import 'package:cosmetic_map/features/home/presentation/pages/popular_services_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final class _PreviewPlaces implements PlaceRepository {
  @override
  Future<Either<Failure, List<Place>>> getPlaces() async =>
      Right(PlacePreviewData.models.map((model) => model.toEntity()).toList());
}

void main() {
  testWidgets('shows the 25 catalog tiles of the design', (tester) async {
    await _pumpCatalog(tester);

    expect(find.text('catalog.title'), findsOneWidget);
    expect(find.byKey(const Key('catalog-city')), findsNothing);
    expect(find.byKey(const Key('catalog-favorites')), findsOneWidget);
    for (final id in ['nails', 'hair', 'makeup', 'brows_lashes']) {
      expect(find.byKey(Key('catalog-category-$id')), findsOneWidget);
    }
    await _scrollTo(tester, find.byKey(const Key('catalog-category-new')));
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'catalog-category-',
            ),
      ),
      findsNWidgets(25),
    );
  });

  testWidgets('a category with several services opens their grid', (
    tester,
  ) async {
    await _pumpCatalog(tester);

    await tester.tap(find.byKey(const Key('catalog-category-nails')));
    await tester.pumpAndSettle();

    expect(find.byType(PopularServicesPage), findsOneWidget);
    expect(find.text('catalog.categories.nails'), findsOneWidget);
    expect(find.byKey(const Key('service-tile-manicure')), findsOneWidget);
    expect(find.byKey(const Key('service-tile-pedicure')), findsOneWidget);
    expect(find.byKey(const Key('service-tile-haircut')), findsNothing);
  });

  testWidgets('a single-service category opens its salons', (tester) async {
    await _pumpCatalog(tester);

    await tester.tap(find.byKey(const Key('catalog-category-cosmetology')));
    await tester.pumpAndSettle();

    expect(find.byType(ServiceSalonsPage), findsOneWidget);
    expect(find.text('Чистка лица'), findsOneWidget);
  });

  testWidgets('a category without salons says it is coming soon', (
    tester,
  ) async {
    await _pumpCatalog(tester);

    await tester.tap(find.byKey(const Key('catalog-category-makeup')));
    await tester.pumpAndSettle();

    expect(find.byType(CatalogSoonPage), findsOneWidget);
    expect(find.text('catalog.soon_title'), findsOneWidget);
    await tester.tap(find.byKey(const Key('list-back')));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogPage), findsOneWidget);
  });
}

Future<void> _pumpCatalog(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        lazy: false,
        create: (_) =>
            ExploreBloc(GetPlaces(_PreviewPlaces()))
              ..add(const ExploreEvent.started()),
        child: const CatalogPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find
        .descendant(
          of: find.byType(CatalogPage),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}
