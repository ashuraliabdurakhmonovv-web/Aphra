import 'package:cosmetic_map/features/cart/presentation/pages/cart_page.dart';
import 'package:cosmetic_map/features/cart/presentation/shop_cart.dart';
import 'package:cosmetic_map/features/favorites/presentation/favorites.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _products = [
  'dior_lip_glow',
  'estee_double_wear',
  'kerastase_chroma',
  'olaplex_no3',
  'chanel_chance',
  'estee_night_repair',
];

void main() {
  testWidgets('shows the sections of the design', (tester) async {
    await _pumpShop(tester);

    expect(find.text('cart.title'), findsOneWidget);
    expect(find.byKey(const Key('shop-search')), findsOneWidget);
    expect(find.byKey(const Key('shop-promo-action')), findsOneWidget);
    for (final id in ['makeup', 'perfume', 'salon_goods', 'premium']) {
      expect(find.byKey(Key('shop-category-$id')), findsOneWidget);
    }
    expect(find.byKey(const Key('shop-brand-dior')), findsOneWidget);
    expect(_visibleProducts(), _products);
  });

  testWidgets('a category and a brand filter the products', (tester) async {
    await _pumpShop(tester);

    await tester.tap(find.byKey(const Key('shop-category-hair')));
    await tester.pumpAndSettle();
    expect(_visibleProducts(), ['kerastase_chroma', 'olaplex_no3']);
    expect(find.byKey(const Key('shop-active-category')), findsOneWidget);

    await tester.tap(find.byKey(const Key('shop-brand-kerastase')));
    await tester.pumpAndSettle();
    expect(_visibleProducts(), ['kerastase_chroma']);

    await tester.tap(find.byKey(const Key('shop-category-makeup')));
    await tester.pumpAndSettle();
    expect(_visibleProducts(), isEmpty);
    expect(find.text('cart.nothing_found'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('shop-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shop-reset')));
    await tester.pumpAndSettle();
    expect(_visibleProducts(), _products);
  });

  testWidgets('the price chip sorts up, then down', (tester) async {
    await _pumpShop(tester);

    await tester.tap(find.byKey(const Key('shop-sort-price')));
    await tester.pumpAndSettle();
    expect(_visibleProducts(), [
      'olaplex_no3',
      'dior_lip_glow',
      'estee_double_wear',
      'kerastase_chroma',
      'estee_night_repair',
      'chanel_chance',
    ]);

    await tester.tap(find.byKey(const Key('shop-sort-price')));
    await tester.pumpAndSettle();
    expect(_visibleProducts().first, 'chanel_chance');

    await tester.tap(find.byKey(const Key('shop-sort-popular')));
    await tester.pumpAndSettle();
    expect(_visibleProducts(), _products);
  });

  testWidgets('search matches the brand and the product name', (tester) async {
    await _pumpShop(tester);

    await tester.enterText(find.byKey(const Key('shop-search')), 'hair');
    await tester.pumpAndSettle();
    expect(_visibleProducts(), ['olaplex_no3']);

    await tester.enterText(find.byKey(const Key('shop-search')), 'dior');
    await tester.pumpAndSettle();
    expect(_visibleProducts(), ['dior_lip_glow']);
  });

  testWidgets('adding to the cart shows the count on the cart', (tester) async {
    await _pumpShop(tester);
    Finder badge() => find.descendant(
      of: find.byKey(const Key('shop-cart')),
      matching: find.text('2'),
    );

    expect(badge(), findsNothing);
    await tester.tap(find.byKey(const Key('shop-add-dior_lip_glow')));
    await tester.tap(find.byKey(const Key('shop-add-olaplex_no3')));
    await tester.pump();
    expect(badge(), findsOneWidget);
  });

  testWidgets('the filter sheet selects a brand without a logo', (
    tester,
  ) async {
    await _pumpShop(tester);

    await tester.tap(find.byKey(const Key('shop-filters')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('shop-filter-brand-olaplex')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shop-filter-brand-olaplex')));
    await tester.pumpAndSettle();

    expect(_visibleProducts(), ['olaplex_no3']);
    expect(find.byKey(const Key('shop-active-brand')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-active-brand')));
    await tester.pumpAndSettle();
    expect(_visibleProducts(), _products);
  });

  testWidgets('a favorite toggles', (tester) async {
    await _pumpShop(tester);
    final heart = find.byKey(const Key('shop-favorite-dior_lip_glow'));

    await tester.tap(heart);
    await tester.pump();
    expect(
      find.descendant(of: heart, matching: find.byIcon(Icons.favorite_rounded)),
      findsOneWidget,
    );
    await tester.tap(heart);
    await tester.pump();
    expect(
      find.descendant(of: heart, matching: find.byIcon(Icons.favorite_rounded)),
      findsNothing,
    );
  });
}

/// Product ids in the order they are shown.
List<String> _visibleProducts() {
  final cards = find.byWidgetPredicate(
    (widget) =>
        widget.key is ValueKey<String> &&
        (widget.key! as ValueKey<String>).value.startsWith('shop-product-'),
  );
  return [
    for (final element in cards.evaluate())
      (element.widget.key! as ValueKey<String>).value.substring(
        'shop-product-'.length,
      ),
  ];
}

Future<void> _pumpShop(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  ShopCart.shared.clear();
  Favorites.shared.clear();
  await tester.pumpWidget(const MaterialApp(home: CartPage()));
  await tester.pumpAndSettle();
}
