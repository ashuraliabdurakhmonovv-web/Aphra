import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import '../../home/presentation/widgets/salon_summary.dart' show price;
import '../data/datasources/shop_preview_catalog.dart';

class ShopCartLine {
  const ShopCartLine({
    required this.product,
    required this.quantity,
    required this.shade,
  });

  final ShopProduct product;
  final int quantity;
  final ShopShade? shade;

  ({String productId, String? shadeId}) get key =>
      (productId: product.id, shadeId: shade?.id);
}

/// The shop cart, shared by the shop tab, the product page and the
/// favorites. It lives in memory until the server has a cart API.
class ShopCart extends ChangeNotifier {
  /// The cart of the app.
  static final shared = ShopCart();

  /// Quantities by product and shade.
  final _lines = <({String productId, String? shadeId}), int>{};

  /// Adds [quantity] of [product]; a product with shades gets its first shade
  /// when [shade] is not given.
  void add(ShopProduct product, {int quantity = 1, ShopShade? shade}) {
    final key = (
      productId: product.id,
      shadeId: (shade ?? product.shades.firstOrNull)?.id,
    );
    _lines.update(key, (count) => count + quantity, ifAbsent: () => quantity);
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }

  bool get isEmpty => _lines.isEmpty;

  List<ShopCartLine> get lines => [
    for (final entry in _lines.entries)
      ShopCartLine(
        product: ShopPreviewCatalog.product(entry.key.productId),
        quantity: entry.value,
        shade: entry.key.shadeId == null
            ? null
            : ShopPreviewCatalog.product(entry.key.productId).shades
                  .where((shade) => shade.id == entry.key.shadeId)
                  .firstOrNull,
      ),
  ];

  int get count => _lines.values.fold(0, (sum, count) => sum + count);

  int get total => _lines.entries.fold(
    0,
    (sum, line) =>
        sum + ShopPreviewCatalog.product(line.key.productId).price * line.value,
  );

  void setQuantity(ShopCartLine line, int quantity) {
    if (!_lines.containsKey(line.key)) return;
    if (quantity <= 0) {
      _lines.remove(line.key);
    } else {
      _lines[line.key] = quantity;
    }
    notifyListeners();
  }

  void remove(ShopCartLine line) {
    if (_lines.remove(line.key) != null) notifyListeners();
  }

  /// What the cart button says until there is a cart page.
  String get summary => isEmpty
      ? 'cart.cart_empty'.tr()
      : '${'cart.cart_summary'.tr(args: ['$count', price(total)])}\n'
            '${'cart.checkout_soon'.tr()}';
}
