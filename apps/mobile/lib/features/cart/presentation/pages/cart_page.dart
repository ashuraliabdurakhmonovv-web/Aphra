import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_state.dart';
import '../../../home/presentation/widgets/salon_summary.dart' show price;
import '../../data/datasources/shop_preview_catalog.dart';

const _pink = Color(0xFFF51772);
const _deepPink = Color(0xFFDE1458);
const _ink = Color(0xFF111111);
const _muted = Color(0xFF6C757D);
const _hint = Color(0xFF9AA0AA);
const _background = Color(0xFFFEF9FB);
const _tileColor = Color(0xFFFDEDF2);
const _chipColor = Color(0xFFFDE7F2);
const _promoColor = Color(0xFFFDE9F0);
const _imageColor = Color(0xFFFEF6F9);
const _star = Color(0xFFFEC00E);
const _shadow = [
  BoxShadow(color: Color(0x129A1F55), blurRadius: 10, offset: Offset(0, 2)),
];

/// Side padding of the page.
const _side = 18.0;

const _categories = [
  'makeup',
  'hair',
  'manicure',
  'skin',
  'perfume',
  'body',
  'accessories',
  'sets',
  'salon_goods',
  'premium',
];

String _categoryLabel(String id) => 'cart.categories.$id'.tr();

ShopBrand _brand(String id) =>
    ShopPreviewCatalog.brands.firstWhere((brand) => brand.id == id);

enum _Sort { popular, priceUp, priceDown }

/// The shop tab: promo, categories, brands and products with filters.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _search = TextEditingController();
  final _productsKey = GlobalKey();
  final _favorites = <String>{};

  /// Quantities by product id.
  final _cart = <String, int>{};
  String? _categoryId;
  String? _brandId;
  var _sort = _Sort.popular;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ShopProduct> get _visibleProducts {
    final query = _search.text.trim().toLowerCase();
    final products = [
      for (final product in ShopPreviewCatalog.products)
        if ((_categoryId == null || product.categoryId == _categoryId) &&
            (_brandId == null || product.brandId == _brandId) &&
            '${product.brand.name} ${product.name}'.toLowerCase().contains(
              query,
            ))
          product,
    ];
    if (_sort != _Sort.popular) {
      final direction = _sort == _Sort.priceUp ? 1 : -1;
      products.sort((a, b) => direction * a.price.compareTo(b.price));
    }
    return products;
  }

  int get _cartCount => _cart.values.fold(0, (sum, count) => sum + count);

  void _showMessage(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _addToCart(ShopProduct product) {
    setState(
      () => _cart.update(product.id, (count) => count + 1, ifAbsent: () => 1),
    );
    _showMessage(
      'cart.added'.tr(args: ['${product.brand.name} ${product.name}']),
    );
  }

  void _showCart() {
    if (_cart.isEmpty) {
      _showMessage('cart.cart_empty'.tr());
      return;
    }
    final total = ShopPreviewCatalog.products.fold(
      0,
      (sum, product) => sum + product.price * (_cart[product.id] ?? 0),
    );
    _showMessage(
      '${'cart.cart_summary'.tr(args: ['$_cartCount', price(total)])}\n'
      '${'cart.checkout_soon'.tr()}',
    );
  }

  void _toggleFavorite(ShopProduct product) => setState(() {
    if (!_favorites.remove(product.id)) _favorites.add(product.id);
  });

  void _resetFilters() => setState(() {
    _categoryId = null;
    _brandId = null;
    _search.clear();
  });

  void _scrollToProducts() {
    final target = _productsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openFilters() => showModalBottomSheet<void>(
    context: context,
    // Above the floating bottom navigation.
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (sheetContext) => _FiltersSheet(
      categoryId: _categoryId,
      brandId: _brandId,
      onChanged: (categoryId, brandId) {
        Navigator.of(sheetContext).pop();
        setState(() {
          _categoryId = categoryId;
          _brandId = brandId;
        });
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final products = _visibleProducts;
    const side = EdgeInsets.symmetric(horizontal: _side);
    return Scaffold(
      backgroundColor: _background,
      body: DefaultTextStyle.merge(
        style: const TextStyle(color: _ink, height: 1.2, letterSpacing: 0),
        child: SafeArea(
          bottom: false,
          child: ListView(
            // Leaves room for the floating bottom navigation.
            padding: const EdgeInsets.only(top: 2, bottom: 120),
            children: [
              Padding(
                padding: side,
                child: _Header(count: _cartCount, onCart: _showCart),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: side,
                child: _SearchField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  onScan: () => _showMessage('cart.scanner_soon'.tr()),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: side,
                child: _Promo(onShop: _scrollToProducts),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: side,
                child: _SectionTitle(
                  title: 'cart.categories_title'.tr(),
                  action: 'cart.all_categories'.tr(),
                  actionKey: const Key('shop-all-categories'),
                  onAction: _openFilters,
                ),
              ),
              const SizedBox(height: 9),
              Padding(
                padding: side,
                child: _CategoryGrid(
                  selectedId: _categoryId,
                  onTap: (id) => setState(
                    () => _categoryId = _categoryId == id ? null : id,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: side,
                child: _SectionTitle(
                  title: 'cart.brands_title'.tr(),
                  action: 'cart.all_brands'.tr(),
                  actionKey: const Key('shop-all-brands'),
                  onAction: _openFilters,
                ),
              ),
              const SizedBox(height: 9),
              _Brands(
                selectedId: _brandId,
                onTap: (id) =>
                    setState(() => _brandId = _brandId == id ? null : id),
              ),
              const SizedBox(height: 18),
              Padding(
                key: _productsKey,
                padding: side,
                child: Row(
                  children: [
                    Expanded(child: _Title('cart.products_title'.tr())),
                    const SizedBox(width: 8),
                    // Long translations shrink the controls, not the title.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SortChip(
                              key: const Key('shop-sort-popular'),
                              label: 'cart.sort_popular'.tr(),
                              active: _sort == _Sort.popular,
                              onTap: () =>
                                  setState(() => _sort = _Sort.popular),
                            ),
                            const SizedBox(width: 6),
                            _SortChip(
                              key: const Key('shop-sort-price'),
                              label: 'cart.sort_price'.tr(),
                              active: _sort != _Sort.popular,
                              icon: switch (_sort) {
                                _Sort.priceUp => Icons.arrow_upward_rounded,
                                _Sort.priceDown => Icons.arrow_downward_rounded,
                                _Sort.popular =>
                                  Icons.keyboard_arrow_down_rounded,
                              },
                              onTap: () => setState(
                                () => _sort = _sort == _Sort.priceUp
                                    ? _Sort.priceDown
                                    : _Sort.priceUp,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _Surface(
                              key: const Key('shop-filters'),
                              radius: 9,
                              onTap: _openFilters,
                              child: const SizedBox.square(
                                dimension: 24,
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: _ink,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_categoryId != null || _brandId != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: side,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (_categoryId case final id?)
                        _FilterTag(
                          key: const Key('shop-active-category'),
                          label: _categoryLabel(id).replaceAll('\n', ' '),
                          onRemove: () => setState(() => _categoryId = null),
                        ),
                      if (_brandId case final id?)
                        _FilterTag(
                          key: const Key('shop-active-brand'),
                          label: _brand(id).name,
                          onRemove: () => setState(() => _brandId = null),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Padding(
                padding: side,
                child: ShopPreviewCatalog.products.isEmpty
                    ? AppEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'cart.unavailable_title'.tr(),
                        description: 'cart.unavailable_description'.tr(),
                      )
                    : products.isEmpty
                    ? Column(
                        children: [
                          AppEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'cart.nothing_found'.tr(),
                            description: 'cart.nothing_found_hint'.tr(),
                          ),
                          TextButton(
                            key: const Key('shop-reset'),
                            onPressed: _resetFilters,
                            style: TextButton.styleFrom(foregroundColor: _pink),
                            child: Text('cart.reset'.tr()),
                          ),
                        ],
                      )
                    : _ProductGrid(
                        products: products,
                        favorites: _favorites,
                        onFavorite: _toggleFavorite,
                        onAdd: _addToCart,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded surface with the soft shadow of the design.
class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.radius = 9,
    this.color = Colors.white,
    this.shadow = true,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final double radius;
  final Color color;
  final bool shadow;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        boxShadow: shadow ? _shadow : null,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 1.5),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: -.2,
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onCart});

  final int count;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 30,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Text(
          'cart.title'.tr(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        Positioned(
          right: -8,
          child: IconButton(
            key: const Key('shop-cart'),
            onPressed: onCart,
            icon: Badge(
              isLabelVisible: count > 0,
              backgroundColor: _pink,
              largeSize: 15,
              offset: const Offset(5, -6),
              textStyle: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
              label: Text('$count'),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: _ink,
                size: 25,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onScan,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.only(left: 14, right: 3),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(19)),
      boxShadow: _shadow,
    ),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, color: _ink, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            key: const Key('shop-search'),
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            cursorColor: _pink,
            style: const TextStyle(color: _ink, fontSize: 13, letterSpacing: 0),
            decoration: InputDecoration(
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'cart.search_hint'.tr(),
              hintMaxLines: 1,
              hintStyle: const TextStyle(
                color: _hint,
                fontSize: 12.5,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _Surface(
          key: const Key('shop-scan'),
          radius: 14,
          onTap: onScan,
          child: const SizedBox(
            width: 34,
            height: 32,
            child: Center(
              child: CustomPaint(
                size: Size.square(16),
                painter: _ScanPainter(),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Viewfinder corners with a scan line.
class _ScanPainter extends CustomPainter {
  const _ScanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final corner = s * .3;
    final path = Path()
      ..moveTo(0, corner)
      ..lineTo(0, 0)
      ..lineTo(corner, 0)
      ..moveTo(s - corner, 0)
      ..lineTo(s, 0)
      ..lineTo(s, corner)
      ..moveTo(s, s - corner)
      ..lineTo(s, s)
      ..lineTo(s - corner, s)
      ..moveTo(corner, s)
      ..lineTo(0, s)
      ..lineTo(0, s - corner)
      ..moveTo(s * .2, s / 2)
      ..lineTo(s * .8, s / 2);
    canvas.drawPath(
      path,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ScanPainter oldDelegate) => false;
}

class _Promo extends StatelessWidget {
  const _Promo({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: ColoredBox(
      color: _promoColor,
      child: SizedBox(
        height: 144,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 160,
              // The photo fades into the banner on its left edge.
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  colors: [Color(0x00000000), Color(0xFF000000)],
                  stops: [0, .2],
                ).createShader(rect),
                child: Image.asset(
                  'assets/images/shop/promo_art.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 0, 16),
              child: SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'cart.promo_title'.tr(),
                        style: const TextStyle(
                          color: _deepPink,
                          fontSize: 18.5,
                          letterSpacing: -.3,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _Highlighted(
                      'cart.promo_text'.tr(),
                      style: const TextStyle(
                        color: Color(0xFF5E5D6A),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('shop-promo-action'),
                      onPressed: onShop,
                      style: FilledButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          letterSpacing: 0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'cart.promo_action'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 15),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Text whose `*marked*` parts are pink.
class _Highlighted extends StatelessWidget {
  const _Highlighted(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('*');
    return Text.rich(
      TextSpan(
        children: [
          for (var index = 0; index < parts.length; index++)
            TextSpan(
              text: parts[index],
              style: index.isOdd ? const TextStyle(color: _deepPink) : null,
            ),
        ],
      ),
      style: style,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.actionKey,
    required this.onAction,
  });

  final String title;
  final String action;
  final Key actionKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _Title(title)),
      InkWell(
        key: actionKey,
        onTap: onAction,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: const TextStyle(
                  color: _pink,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_rounded, color: _pink, size: 13),
            ],
          ),
        ),
      ),
    ],
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selectedId, required this.onTap});

  final String? selectedId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var start = 0; start < _categories.length; start += 5) ...[
        if (start > 0) const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final id in _categories.skip(start).take(5))
              Expanded(
                child: _CategoryTile(
                  id: id,
                  selected: id == selectedId,
                  onTap: () => onTap(id),
                ),
              ),
          ],
        ),
      ],
    ],
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.id,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: Key('shop-category-$id'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: AspectRatio(
            aspectRatio: 1.145,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: _tileColor,
                borderRadius: BorderRadius.circular(11),
                // Always present so a selection does not shift the image.
                border: Border.all(
                  color: selected ? _pink : _tileColor,
                  width: 1.5,
                ),
              ),
              child: Image.asset(
                'assets/images/shop/cat_$id.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _categoryLabel(id),
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? _pink : _ink,
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _Brands extends StatelessWidget {
  const _Brands({required this.selectedId, required this.onTap});

  final String? selectedId;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final brands = [
      for (final brand in ShopPreviewCatalog.brands)
        if (brand.hasLogo) brand,
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: _side),
        clipBehavior: Clip.none,
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, index) {
          final brand = brands[index];
          return _Surface(
            key: Key('shop-brand-${brand.id}'),
            radius: 8,
            borderColor: brand.id == selectedId ? _pink : null,
            onTap: () => onTap(brand.id),
            child: SizedBox(
              width: 66,
              height: 34,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Image.asset(brand.logo, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon = Icons.keyboard_arrow_down_rounded,
    super.key,
  });

  final String label;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? _pink : _ink;
    return _Surface(
      radius: 10,
      color: active ? _chipColor : Colors.white,
      shadow: !active,
      onTap: onTap,
      child: SizedBox(
        height: 22,
        child: Padding(
          padding: const EdgeInsets.only(left: 9, right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 3),
              Icon(icon, color: color, size: 13),
            ],
          ),
        ),
      ),
    );
  }
}

/// An applied filter with a button that removes it.
class _FilterTag extends StatelessWidget {
  const _FilterTag({required this.label, required this.onRemove, super.key});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => _Surface(
    radius: 10,
    color: _chipColor,
    shadow: false,
    onTap: onRemove,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _pink,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.close_rounded, color: _pink, size: 13),
        ],
      ),
    ),
  );
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.favorites,
    required this.onFavorite,
    required this.onAdd,
  });

  final List<ShopProduct> products;
  final Set<String> favorites;
  final ValueChanged<ShopProduct> onFavorite;
  final ValueChanged<ShopProduct> onAdd;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var start = 0; start < products.length; start += 4) ...[
        if (start > 0) const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = start; index < start + 4; index++) ...[
              if (index > start) const SizedBox(width: 7),
              Expanded(
                child: index < products.length
                    ? _ProductCard(
                        product: products[index],
                        favorite: favorites.contains(products[index].id),
                        onFavorite: () => onFavorite(products[index]),
                        onAdd: () => onAdd(products[index]),
                      )
                    : const SizedBox(),
              ),
            ],
          ],
        ),
      ],
    ],
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.favorite,
    required this.onFavorite,
    required this.onAdd,
  });

  final ShopProduct product;
  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => _Surface(
    key: Key('shop-product-${product.id}'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1.12,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: _imageColor,
                child: Image.asset(product.image, fit: BoxFit.cover),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: InkResponse(
                  key: Key('shop-favorite-${product.id}'),
                  onTap: onFavorite,
                  radius: 15,
                  child: SizedBox.square(
                    dimension: 25,
                    child: Icon(
                      favorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: favorite ? _pink : const Color(0xFF7A7F88),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(7, 7, 5, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.brand.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              // Long names shrink to stay whole, as in the design; the fixed
              // height keeps the cards of a row equal.
              SizedBox(
                height: 12,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    product.name,
                    maxLines: 1,
                    style: const TextStyle(color: _muted, fontSize: 9.5),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: _star, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFFF2A60C),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      ' (${product.reviews})',
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: const TextStyle(color: _hint, fontSize: 9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        price(product.price),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Material(
                    color: _pink,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      key: Key('shop-add-${product.id}'),
                      onTap: onAdd,
                      borderRadius: BorderRadius.circular(6),
                      child: const SizedBox.square(
                        dimension: 22,
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet({
    required this.categoryId,
    required this.brandId,
    required this.onChanged,
  });

  final String? categoryId;
  final String? brandId;
  final void Function(String? categoryId, String? brandId) onChanged;

  @override
  Widget build(BuildContext context) {
    Widget choice(Key key, String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(
          key: key,
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => onTap(),
          backgroundColor: Colors.white,
          selectedColor: _chipColor,
          side: BorderSide(color: selected ? _pink : const Color(0xFFEDE7EB)),
          labelStyle: TextStyle(
            color: selected ? _pink : _ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'cart.filters'.tr(),
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (categoryId != null || brandId != null)
                  TextButton(
                    key: const Key('shop-filters-reset'),
                    onPressed: () => onChanged(null, null),
                    style: TextButton.styleFrom(foregroundColor: _pink),
                    child: Text('cart.reset'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _Title('cart.categories_title'.tr()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in _categories)
                  choice(
                    Key('shop-filter-category-$id'),
                    _categoryLabel(id).replaceAll('\n', ' '),
                    id == categoryId,
                    () => onChanged(id == categoryId ? null : id, brandId),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _Title('cart.brands'.tr()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final brand in ShopPreviewCatalog.brands)
                  choice(
                    Key('shop-filter-brand-${brand.id}'),
                    brand.name,
                    brand.id == brandId,
                    () => onChanged(
                      categoryId,
                      brand.id == brandId ? null : brand.id,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
