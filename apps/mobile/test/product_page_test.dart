import 'dart:convert';
import 'dart:io';

import 'package:cosmetic_map/features/cart/data/datasources/shop_preview_catalog.dart';
import 'package:cosmetic_map/features/cart/presentation/pages/cart_page.dart';
import 'package:cosmetic_map/features/cart/presentation/pages/product_page.dart';
import 'package:cosmetic_map/features/cart/presentation/shop_cart.dart';
import 'package:cosmetic_map/features/favorites/presentation/favorites.dart';
import 'package:easy_localization/easy_localization.dart'
    show StringTranslateExtension;
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:cosmetic_map/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    // Review counts use plurals, which need a locale.
    Localization.load(const Locale('ru'), ignorePluralRules: false);
    ShopCart.shared.clear();
    Favorites.shared.clear();
  });

  test('review counts use the Russian plural forms', () {
    _loadRussian();

    expect('cart.product.reviews'.plural(1), '1 отзыв');
    expect('cart.product.reviews'.plural(21), '21 отзыв');
    expect('cart.product.reviews'.plural(74), '74 отзыва');
    expect('cart.product.reviews'.plural(112), '112 отзывов');
    expect('cart.product.reviews'.plural(128), '128 отзывов');
  });

  testWidgets('a product card opens its page over the shop', (tester) async {
    _setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const CartPage()),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('shop-product-olaplex_no3')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shop-product-olaplex_no3')));
    await tester.pumpAndSettle();

    expect(find.byType(ProductPage), findsOneWidget);
    expect(find.text('Olaplex No.3 Hair Perfector'), findsOneWidget);
    expect(find.text('Mira Hair'), findsOneWidget);
    // Mira Hair is not verified, and Olaplex has no shades.
    expect(find.byKey(const Key('product-seller-verified')), findsNothing);
    expect(find.byKey(const Key('product-shade-001')), findsNothing);

    await tester.tap(find.byKey(const Key('product-back')));
    await tester.pumpAndSettle();
    expect(find.byType(ProductPage), findsNothing);
  });

  testWidgets('shows the sections of the design', (tester) async {
    await _pumpProduct(tester);

    expect(find.text('Dior Addict Lip Glow'), findsOneWidget);
    expect(find.text('cart.product_types.lip_balm'), findsOneWidget);
    // Without translations a plural falls back to its `other` key.
    expect(find.text('(cart.product.reviews.other)'), findsOneWidget);
    expect(find.text('cart.product.original'), findsOneWidget);
    expect(find.text('Nur Beauty'), findsOneWidget);
    expect(find.text('NB'), findsOneWidget);
    expect(find.byKey(const Key('product-seller-verified')), findsOneWidget);
    expect(find.byKey(const Key('product-salon')), findsOneWidget);
    for (final shade in ['001', '004', '012', '015']) {
      expect(find.byKey(Key('product-shade-$shade')), findsOneWidget);
    }
    expect(find.text('cart.product.delivery'), findsOneWidget);
    expect(find.byKey(const Key('product-buy')), findsOneWidget);
  });

  testWidgets('the quantity changes the total and the cart', (tester) async {
    final cart = ShopCart.shared;
    await _pumpProduct(tester);
    final minus = find.byKey(const Key('product-quantity-minus'));
    final plus = find.byKey(const Key('product-quantity-plus'));

    expect(tester.widget<IconButton>(minus).onPressed, isNull);
    await tester.tap(plus);
    await tester.pump();
    await tester.tap(plus);
    await tester.pump();
    expect(_text(tester, 'product-quantity'), '3');

    await tester.tap(minus);
    await tester.pump();
    expect(_text(tester, 'product-quantity'), '2');

    await tester.tap(find.byKey(const Key('product-shade-015')));
    await tester.pump();
    expect(find.textContaining('015 Cherry'), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-add')));
    await tester.pump();
    expect(cart.count, 2);
    expect(cart.total, 1040000);
  });

  testWidgets('the heart toggles the shared favorite', (tester) async {
    await _pumpProduct(tester);
    final dior = ShopPreviewCatalog.product('dior_lip_glow');
    final favorites = Favorites.shared.products;

    await tester.tap(find.byKey(const Key('product-favorite')));
    await tester.pump();
    expect(favorites.contains(dior), isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.tap(find.byKey(const Key('product-favorite')));
    await tester.pump();
    expect(favorites.contains(dior), isFalse);
  });

  testWidgets('a long description expands', (tester) async {
    _loadRussian();
    await _pumpProduct(tester);
    Text description() =>
        tester.widget<Text>(find.byKey(const Key('product-description')));

    expect(description().maxLines, 2);
    await tester.tap(find.byKey(const Key('product-description-toggle')));
    await tester.pumpAndSettle();
    expect(description().maxLines, isNull);
    expect(find.text('Свернуть'), findsOneWidget);
  });
}

void _loadRussian() {
  final ru = File('assets/translations/ru.json').readAsStringSync();
  Localization.load(
    const Locale('ru'),
    translations: Translations(jsonDecode(ru) as Map<String, dynamic>),
    ignorePluralRules: false,
  );
}

String _text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(Key(key))).data!;

void _setPhoneSize(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pumpProduct(WidgetTester tester) async {
  _setPhoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: ProductPage(product: ShopPreviewCatalog.product('dior_lip_glow')),
    ),
  );
  await tester.pumpAndSettle();
}
