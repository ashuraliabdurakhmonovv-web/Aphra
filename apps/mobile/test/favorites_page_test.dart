import 'package:cosmetic_map/app/theme/app_theme.dart';
import 'package:cosmetic_map/features/cart/presentation/shop_cart.dart';
import 'package:cosmetic_map/features/favorites/presentation/favorites.dart';
import 'package:cosmetic_map/features/favorites/presentation/pages/favorites_page.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The preview favorites, newest first.
const _products = [
  'dior_lip_glow',
  'kerastase_chroma',
  'chanel_chance',
  'estee_night_repair',
  'estee_double_wear',
  'olaplex_no3',
];

void main() {
  setUp(() {
    // Counts use plurals, which need a locale.
    Localization.load(const Locale('ru'), ignorePluralRules: false);
    ShopCart.shared.clear();
    Favorites.shared
      ..clear()
      ..addPreview();
  });

  testWidgets('shows the tabs with counts and the newest products first', (
    tester,
  ) async {
    await _pumpFavorites(tester);

    expect(find.text('favorites.title'), findsOneWidget);
    expect(_tabCount('products'), '6');
    expect(_tabCount('salons'), '4');
    expect(_tabCount('services'), '7');
    expect(_tabCount('masters'), '3');
    expect(_cards(), _products);
    expect(find.byKey(const Key('favorites-filter')), findsOneWidget);
  });

  testWidgets('the sort menu orders by price', (tester) async {
    await _pumpFavorites(tester);

    await tester.tap(find.byKey(const Key('favorites-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('favorites-sort-price_up')));
    await tester.pumpAndSettle();
    expect(_cards(), [
      'olaplex_no3',
      'dior_lip_glow',
      'estee_double_wear',
      'kerastase_chroma',
      'estee_night_repair',
      'chanel_chance',
    ]);

    await tester.tap(find.byKey(const Key('favorites-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('favorites-sort-price_down')));
    await tester.pumpAndSettle();
    expect(_cards().first, 'chanel_chance');
  });

  testWidgets('a removed favorite comes back in its place on undo', (
    tester,
  ) async {
    await _pumpFavorites(tester);

    await tester.tap(
      find.byKey(const Key('favorites-remove-kerastase_chroma')),
    );
    await tester.pumpAndSettle();
    expect(_cards(), isNot(contains('kerastase_chroma')));
    expect(_tabCount('products'), '5');

    await tester.tap(find.text('favorites.undo'));
    await tester.pumpAndSettle();
    expect(_cards(), _products);
  });

  testWidgets('add to cart fills the cart badge', (tester) async {
    await _pumpFavorites(tester);
    expect(find.byKey(const Key('favorites-cart-count')), findsNothing);

    await tester.tap(find.byKey(const Key('favorites-action-dior_lip_glow')));
    await tester.tap(find.byKey(const Key('favorites-action-chanel_chance')));
    await tester.pump();

    expect(ShopCart.shared.count, 2);
    expect(ShopCart.shared.total, 520000 + 1890000);
    expect(
      tester.widget<Text>(find.byKey(const Key('favorites-cart-count'))).data,
      '2',
    );
  });

  testWidgets('the filter keeps the chosen category', (tester) async {
    await _pumpFavorites(tester);

    await tester.tap(find.byKey(const Key('favorites-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('favorites-filter-category-hair')));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();

    expect(_cards(), ['kerastase_chroma', 'olaplex_no3']);
    expect(find.text('favorites.count.products.other'), findsOneWidget);
  });

  testWidgets('each tab lists its favorites', (tester) async {
    await _pumpFavorites(tester);

    await tester.tap(find.byKey(const Key('favorites-tab-salons')));
    await tester.pumpAndSettle();
    expect(_cards(), ['salon-1', 'salon-2', 'salon-7', 'salon-14']);
    expect(find.byKey(const Key('favorites-filter')), findsNothing);

    await tester.tap(find.byKey(const Key('favorites-tab-services')));
    await tester.pumpAndSettle();
    expect(_cards().first, 'service-1-manicure');
    expect(_cards(), hasLength(7));

    await tester.tap(find.byKey(const Key('favorites-tab-masters')));
    await tester.pumpAndSettle();
    expect(_cards(), [
      'master-1-nail-0',
      'master-1-hair-0',
      'master-2-hair-second-1',
    ]);
  });

  testWidgets('opens the tab it is given', (tester) async {
    await _pumpFavorites(tester, initialTab: 'masters');

    expect(_cards(), hasLength(3));
  });

  testWidgets('an empty tab says how to save', (tester) async {
    Favorites.shared.clear();
    await _pumpFavorites(tester);

    expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
    expect(find.text('favorites.empty.products'), findsOneWidget);
    expect(find.byKey(const Key('favorites-sort')), findsNothing);
    expect(_tabCount('products'), isNull);
  });
}

/// Card ids in the order they are shown.
List<String> _cards() {
  const prefix = 'favorites-card-';
  final cards = find.byWidgetPredicate(
    (widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith(prefix),
  );
  return [
    for (final element in cards.evaluate())
      (element.widget.key! as ValueKey<String>).value.substring(prefix.length),
  ];
}

String? _tabCount(String tab) {
  final count = find.byKey(Key('favorites-tab-count-$tab'));
  return count.evaluate().isEmpty
      ? null
      : (count.evaluate().single.widget as Text).data;
}

Future<void> _pumpFavorites(WidgetTester tester, {String? initialTab}) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: FavoritesPage(initialTab: initialTab),
    ),
  );
  await tester.pumpAndSettle();
}
