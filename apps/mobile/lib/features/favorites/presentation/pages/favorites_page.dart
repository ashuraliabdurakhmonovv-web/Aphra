import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/brand_header.dart';
import '../../../cart/data/datasources/shop_preview_catalog.dart';
import '../../../cart/presentation/pages/product_page.dart';
import '../../../cart/presentation/shop_cart.dart';
import '../../../cart/presentation/shop_colors.dart';
import '../../../explore/data/datasources/salon_preview_catalog.dart';
import '../../../explore/domain/entities/place.dart';
import '../../../explore/presentation/widgets/service_photo.dart';
import '../../../home/presentation/widgets/salon_summary.dart'
    show openBooking, openSalonPage, price, priceFrom, salonCardImage;
import '../favorites.dart';

const _background = Color(0xFFFDF7F9);

/// The pink of the app, as in the bottom navigation; the mockup's red-pink
/// stands out from the other tabs.
const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF151515);
const _muted = Color(0xFF6B6570);
const _hint = Color(0xFF8F8A94);
const _tile = Color(0xFFFAEAF4);
const _actionColor = Color(0xFFF9E3F1);
const _cardShadow = [
  BoxShadow(color: Color(0x129A1F55), blurRadius: 12, offset: Offset(0, 3)),
];

/// Side padding of the cards; the mockup is 2 px per point.
const _side = 9.5;

enum _Tab {
  products(Icons.shopping_bag_outlined),
  salons(Icons.storefront_outlined),
  services(Icons.spa_outlined),
  masters(Icons.person_outline_rounded);

  const _Tab(this.icon);

  final IconData icon;

  List<_Sort> get sorts => switch (this) {
    products || services => _Sort.values,
    salons || masters => const [_Sort.added, _Sort.rating],
  };
}

enum _Sort {
  added('added'),
  priceUp('price_up'),
  priceDown('price_down'),
  rating('rating');

  const _Sort(this.key);

  final String key;
}

/// Orders [items], which come newest first, by [sort]; equal items stay
/// newest first.
List<T> _sorted<T>(
  List<T> items,
  _Sort sort, {
  int Function(T item)? priceOf,
  required double Function(T item) ratingOf,
}) {
  final int Function(T a, T b)? compare = switch (sort) {
    _Sort.added => null,
    _Sort.priceUp => (a, b) => priceOf!(a).compareTo(priceOf(b)),
    _Sort.priceDown => (a, b) => priceOf!(b).compareTo(priceOf(a)),
    _Sort.rating => (a, b) => ratingOf(b).compareTo(ratingOf(a)),
  };
  if (compare == null) return items;
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final order = compare(a.$2, b.$2);
      return order != 0 ? order : a.$1.compareTo(b.$1);
    });
  return [for (final (_, item) in indexed) item];
}

/// Saved products, salons, services and masters, one kind per tab.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({this.initialTab, super.key});

  /// The name of the tab to open: products, salons, services or masters.
  final String? initialTab;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _favorites = Favorites.shared;
  final _cart = ShopCart.shared;
  late var _tab = _Tab.values.firstWhere(
    (tab) => tab.name == widget.initialTab,
    orElse: () => _Tab.products,
  );
  final _sorts = {for (final tab in _Tab.values) tab: _Sort.added};
  String? _categoryId;
  String? _brandId;

  _Sort get _sort => _sorts[_tab]!;

  int _count(_Tab tab) => switch (tab) {
    _Tab.products => _favorites.products.length,
    _Tab.salons => _favorites.salons.length,
    _Tab.services => _favorites.services.length,
    _Tab.masters => _favorites.masters.length,
  };

  void _showMessage(String text, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text), action: action));

  void _remove<T>(FavoriteList<T> list, T item) {
    final undo = list.remove(item);
    _showMessage(
      'favorites.removed'.tr(),
      action: SnackBarAction(label: 'favorites.undo'.tr(), onPressed: undo),
    );
  }

  void _addToCart(ShopProduct product) {
    _cart.add(product);
    _showMessage('cart.added'.tr(args: [product.fullName]));
  }

  void _back() => context.canPop() ? context.pop() : context.go('/profile');

  List<ShopProduct> get _products => _sorted(
    [
      for (final product in _favorites.products.newestFirst)
        if ((_categoryId == null || product.categoryId == _categoryId) &&
            (_brandId == null || product.brandId == _brandId))
          product,
    ],
    _sort,
    priceOf: (product) => product.price,
    ratingOf: (product) => product.rating,
  );

  Future<void> _openFilters() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) {
        void apply(String? categoryId, String? brandId) {
          setState(() {
            _categoryId = categoryId;
            _brandId = brandId;
          });
          setSheetState(() {});
        }

        return _FiltersSheet(
          products: _favorites.products.newestFirst,
          categoryId: _categoryId,
          brandId: _brandId,
          onChanged: apply,
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: DefaultTextStyle.merge(
      style: const TextStyle(color: _ink, height: 1.2, letterSpacing: 0),
      child: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _favorites.changes,
          builder: (context, _) => ListView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              _Top(
                cart: ListenableBuilder(
                  listenable: _cart,
                  builder: (context, _) => _CartButton(
                    count: _cart.count,
                    onTap: () => _showMessage(_cart.summary),
                  ),
                ),
                onBack: _back,
                tabs: _Tabs(
                  selected: _tab,
                  countOf: _count,
                  onSelected: (tab) => setState(() => _tab = tab),
                ),
              ),
              const SizedBox(height: 12),
              ..._content(),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _content() {
    final filtered =
        _tab == _Tab.products && (_categoryId != null || _brandId != null);
    final cards = switch (_tab) {
      _Tab.products => [
        for (final product in _products)
          _ProductCard(
            product: product,
            onRemove: () => _remove(_favorites.products, product),
            onAdd: () => _addToCart(product),
          ),
      ],
      _Tab.salons => [
        for (final salon in _sorted(
          _favorites.salons.newestFirst,
          _sort,
          ratingOf: (salon) => salon.rating,
        ))
          _SalonCard(
            salon: salon,
            onRemove: () => _remove(_favorites.salons, salon),
          ),
      ],
      _Tab.services => [
        for (final saved in _sorted(
          _favorites.services.newestFirst,
          _sort,
          priceOf: (saved) => saved.service.price,
          ratingOf: (saved) => saved.salon.rating,
        ))
          _ServiceCard(
            saved: saved,
            onRemove: () => _remove(_favorites.services, saved),
          ),
      ],
      _Tab.masters => [
        for (final saved in _sorted(
          _favorites.masters.newestFirst,
          _sort,
          ratingOf: (saved) => saved.master.rating,
        ))
          _MasterCard(
            saved: saved,
            onRemove: () => _remove(_favorites.masters, saved),
          ),
      ],
    };

    if (cards.isEmpty && !filtered) return [_Empty(tab: _tab)];
    return [
      _Toolbar(
        count: 'favorites.count.${_tab.name}'.plural(cards.length),
        sorts: _tab.sorts,
        sort: _sort,
        onSort: (sort) => setState(() => _sorts[_tab] = sort),
        filtered: filtered,
        onFilter: _tab == _Tab.products ? _openFilters : null,
      ),
      const SizedBox(height: 12),
      if (cards.isEmpty)
        _NothingFound(
          onReset: () => setState(() {
            _categoryId = null;
            _brandId = null;
          }),
        )
      else
        _Grid(cards: cards),
    ];
  }
}

/// Header, title and tabs, with the hearts of the design behind them.
class _Top extends StatelessWidget {
  const _Top({required this.cart, required this.onBack, required this.tabs});

  final Widget cart;
  final VoidCallback onBack;
  final Widget tabs;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        top: 25.5,
        right: 0,
        child: Image.asset(
          'assets/images/favorites/hearts.png',
          width: 134,
          excludeFromSemantics: true,
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandHeader(
            backKey: const Key('favorites-back'),
            onBack: onBack,
            action: cart,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 4, 130, 0),
            child: Text(
              'favorites.title'.tr(),
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -.2,
              ),
            ),
          ),
          Padding(
            // Keeps clear of the hearts, as in the design.
            padding: const EdgeInsets.fromLTRB(21, 3, 100, 0),
            child: Text(
              'favorites.subtitle'.tr(),
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 11),
          tabs,
        ],
      ),
    ],
  );
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    shadowColor: const Color(0x339A1F55),
    elevation: 1.5,
    child: InkWell(
      key: const Key('favorites-cart'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Tooltip(
        message: 'favorites.cart'.tr(),
        child: SizedBox(
          width: 36,
          height: 32,
          child: Center(
            child: Badge(
              isLabelVisible: count > 0,
              backgroundColor: _pink,
              largeSize: 16,
              offset: const Offset(9, -10),
              textStyle: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
              label: Text('$count', key: const Key('favorites-cart-count')),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: _ink,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.selected,
    required this.countOf,
    required this.onSelected,
  });

  final _Tab selected;
  final int Function(_Tab tab) countOf;
  final ValueChanged<_Tab> onSelected;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 9),
    padding: const EdgeInsets.all(7),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D9A1F55),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        for (final tab in _Tab.values) ...[
          if (tab.index > 0) const SizedBox(width: 8),
          Expanded(
            child: _TabTile(
              tab: tab,
              count: countOf(tab),
              selected: tab == selected,
              onTap: () => onSelected(tab),
            ),
          ),
        ],
      ],
    ),
  );
}

class _TabTile extends StatelessWidget {
  const _TabTile({
    required this.tab,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final _Tab tab;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : _pink;
    return Semantics(
      selected: selected,
      button: true,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: selected ? null : _tile,
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDC3A9F), Color(0xFFC0177F)],
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x40CC1F8D),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('favorites-tab-${tab.name}'),
            onTap: onTap,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tab.icon, color: color, size: 19),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'favorites.tabs.${tab.name}'.tr(),
                            style: TextStyle(
                              color: selected ? Colors.white : _ink,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 4,
                    right: 6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 17),
                      height: 17,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '$count',
                        key: Key('favorites-tab-count-${tab.name}'),
                        style: const TextStyle(
                          color: _pink,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.count,
    required this.sorts,
    required this.sort,
    required this.onSort,
    required this.filtered,
    required this.onFilter,
  });

  final String count;
  final List<_Sort> sorts;
  final _Sort sort;
  final ValueChanged<_Sort> onSort;
  final bool filtered;

  /// Null hides the filter button.
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 17.5, right: 11.5),
    child: SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: Text(
              count,
              key: const Key('favorites-count'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          PopupMenuButton<_Sort>(
            key: const Key('favorites-sort'),
            initialValue: sort,
            onSelected: onSort,
            tooltip: '',
            position: PopupMenuPosition.under,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            itemBuilder: (context) => [
              for (final option in sorts)
                PopupMenuItem(
                  key: Key('favorites-sort-${option.key}'),
                  value: option,
                  height: 40,
                  child: Text(
                    'favorites.sort.${option.key}'.tr(),
                    style: TextStyle(
                      color: option == sort ? _pink : _ink,
                      fontSize: 13,
                      fontWeight: option == sort
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
            child: Container(
              height: 25,
              padding: const EdgeInsets.only(left: 11, right: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: _cardShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'favorites.sort.${sort.key}'.tr(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(Icons.expand_more_rounded, size: 16, color: _ink),
                ],
              ),
            ),
          ),
          if (onFilter != null) ...[
            const SizedBox(width: 9),
            Material(
              color: filtered ? _pink : Colors.white,
              shape: const CircleBorder(),
              elevation: 1,
              shadowColor: const Color(0x339A1F55),
              child: InkWell(
                key: const Key('favorites-filter'),
                customBorder: const CircleBorder(),
                onTap: onFilter,
                child: SizedBox.square(
                  dimension: 30,
                  child: Tooltip(
                    message: 'favorites.filters'.tr(),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 16,
                      color: filtered ? Colors.white : _ink,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Two cards per row; cards of a row have the same height.
class _Grid extends StatelessWidget {
  const _Grid({required this.cards});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _side),
    child: Column(
      children: [
        for (var start = 0; start < cards.length; start += 2) ...[
          if (start > 0) const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cards[start]),
              const SizedBox(width: 10.5),
              Expanded(
                child: start + 1 < cards.length
                    ? cards[start + 1]
                    : const SizedBox(),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

/// The card layout shared by all tabs: a photo with a heart to remove the
/// favorite, two lines of text, a rating row and an amount with an action.
class _Card extends StatelessWidget {
  const _Card({
    required this.id,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.rating,
    required this.amount,
    required this.actionIcon,
    required this.actionLabel,
    required this.onOpen,
    required this.onRemove,
    required this.onAction,
    this.ratingNote,
    this.mark,
  });

  /// Makes the keys of the card: `favorites-card-<id>` and so on.
  final String id;
  final Widget image;
  final String title;
  final String subtitle;
  final double rating;
  final String? ratingNote;

  /// Shown at the end of the rating row, like a brand logo.
  final Widget? mark;
  final String amount;
  final IconData actionIcon;
  final String actionLabel;
  final VoidCallback onOpen;
  final VoidCallback onRemove;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(11),
      boxShadow: _cardShadow,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('favorites-card-$id'),
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 374 / 203,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: ShopColors.image, child: image),
                  Positioned(
                    top: 4.5,
                    right: 6.5,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 1,
                      shadowColor: const Color(0x33000000),
                      child: InkWell(
                        key: Key('favorites-remove-$id'),
                        customBorder: const CircleBorder(),
                        onTap: onRemove,
                        child: Tooltip(
                          message: 'favorites.remove'.tr(),
                          child: const SizedBox.square(
                            dimension: 24,
                            child: Icon(
                              Icons.favorite_rounded,
                              color: _pink,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9.5, 8, 9.5, 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _hint, fontSize: 9.5),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 15,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: ShopColors.star,
                          size: 13,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            ratingNote == null ? '' : ' $ratingNote',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _hint, fontSize: 9.5),
                          ),
                        ),
                        if (mark case final mark?) ...[
                          const SizedBox(width: 4),
                          mark,
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            amount,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: _actionColor,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          key: Key('favorites-action-$id'),
                          onTap: onAction,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            constraints: const BoxConstraints(maxWidth: 96),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(actionIcon, color: _pink, size: 13),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      actionLabel,
                                      style: const TextStyle(
                                        color: _pink,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onRemove,
    required this.onAdd,
  });

  final ShopProduct product;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => _Card(
    id: product.id,
    image: Image.asset(product.wideImage, fit: BoxFit.cover),
    title: product.fullName,
    subtitle: 'cart.product_types.${product.typeId}'.tr(),
    rating: product.rating,
    ratingNote: '(${'cart.product.reviews'.plural(product.reviews)})',
    mark: _BrandMark(brand: product.brand),
    amount: price(product.price),
    actionIcon: Icons.shopping_cart_outlined,
    actionLabel: 'favorites.add_to_cart'.tr(),
    onOpen: () => openProductPage(context, product),
    onRemove: onRemove,
    onAction: onAdd,
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.brand});

  final ShopBrand brand;

  @override
  Widget build(BuildContext context) => brand.hasLogo
      ? Image.asset(brand.logo, height: 15, semanticLabel: brand.name)
      : Text(
          brand.name.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 7.5,
            letterSpacing: .2,
          ),
        );
}

class _SalonCard extends StatelessWidget {
  const _SalonCard({required this.salon, required this.onRemove});

  final Place salon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final catalog = SalonPreviewCatalog.forPlace(salon);
    return _Card(
      id: 'salon${salon.id}',
      image: salonCardImage(salon),
      title: salon.name,
      subtitle: salon.address,
      rating: salon.rating,
      ratingNote: catalog == null
          ? null
          : '(${'cart.product.reviews'.plural(catalog.reviewCount)})',
      mark: salon.isVerified
          ? const Icon(Icons.verified_rounded, color: _pink, size: 14)
          : null,
      amount: catalog == null ? '' : priceFrom(catalog.minPrice),
      actionIcon: Icons.calendar_today_outlined,
      actionLabel: 'favorites.book'.tr(),
      onOpen: () => openSalonPage(context, salon),
      onRemove: onRemove,
      onAction: () => openBooking(context, salon),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.saved, required this.onRemove});

  final SavedService saved;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final (:salon, :service) = saved;
    void book() => openBooking(context, salon, serviceId: service.id);
    return _Card(
      id: 'service${salon.id}-${service.id}',
      image: Image.asset(ServicePhoto.of(service), fit: BoxFit.cover),
      title: service.name,
      subtitle: salon.name,
      rating: salon.rating,
      ratingNote:
          '· ${'home.minutes'.tr(args: ['${service.durationMinutes}'])}',
      amount: price(service.price),
      actionIcon: Icons.calendar_today_outlined,
      actionLabel: 'favorites.book'.tr(),
      onOpen: book,
      onRemove: onRemove,
      onAction: book,
    );
  }
}

class _MasterCard extends StatelessWidget {
  const _MasterCard({required this.saved, required this.onRemove});

  final SavedMaster saved;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final (:salon, :master) = saved;
    final service = SalonPreviewCatalog.forPlace(salon)?.services
        .where((service) => master.serviceIds.contains(service.id))
        .firstOrNull;
    void book() => openBooking(
      context,
      salon,
      serviceId: service?.id,
      specialistId: master.id,
    );
    return _Card(
      id: 'master${salon.id}-${master.id}',
      image: _MasterPhoto(master: master),
      title: master.name,
      subtitle: master.role,
      rating: master.rating,
      ratingNote: '· ${salon.name}',
      amount: 'favorites.experience'.plural(master.experienceYears),
      actionIcon: Icons.calendar_today_outlined,
      actionLabel: 'favorites.book'.tr(),
      onOpen: book,
      onRemove: onRemove,
      onAction: book,
    );
  }
}

/// The master's round portrait on a soft background; the portraits are too
/// small to fill the card.
class _MasterPhoto extends StatelessWidget {
  const _MasterPhoto({required this.master});

  final SalonSpecialist master;

  @override
  Widget build(BuildContext context) {
    final photo = master.photoAsset;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFCEFF7), Color(0xFFF5D9EA)],
        ),
      ),
      child: Center(
        child: Container(
          width: 74,
          height: 74,
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: _cardShadow,
          ),
          child: ClipOval(
            child: photo == null
                ? ColoredBox(
                    color: _tile,
                    child: Center(
                      child: Text(
                        master.name.characters.first,
                        style: const TextStyle(
                          color: _pink,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                : Image.asset(photo, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.tab});

  final _Tab tab;

  @override
  Widget build(BuildContext context) {
    final shop = tab == _Tab.products;
    return Padding(
      key: const Key('favorites-empty'),
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _tile,
              shape: BoxShape.circle,
            ),
            child: Icon(tab.icon, color: _pink, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'favorites.empty.${tab.name}'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'favorites.empty_hint'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('favorites-empty-action'),
            onPressed: () => context.go(shop ? '/cart' : '/search'),
            style: FilledButton.styleFrom(
              // The app theme makes filled buttons full width.
              minimumSize: const Size(0, 42),
              backgroundColor: _pink,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 22),
            ),
            child: Text(
              (shop ? 'favorites.to_shop' : 'favorites.to_salons').tr(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NothingFound extends StatelessWidget {
  const _NothingFound({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 36),
    child: Column(
      children: [
        Text(
          'favorites.nothing_found'.tr(),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('favorites-reset'),
          onPressed: onReset,
          style: TextButton.styleFrom(foregroundColor: _pink),
          child: Text('cart.reset'.tr()),
        ),
      ],
    ),
  );
}

/// Categories and brands of the saved products.
class _FiltersSheet extends StatelessWidget {
  const _FiltersSheet({
    required this.products,
    required this.categoryId,
    required this.brandId,
    required this.onChanged,
  });

  final List<ShopProduct> products;
  final String? categoryId;
  final String? brandId;
  final void Function(String? categoryId, String? brandId) onChanged;

  @override
  Widget build(BuildContext context) {
    final categories = {for (final product in products) product.categoryId};
    final brands = {for (final product in products) product.brand};

    Widget choice(
      String key,
      String label,
      bool selected,
      VoidCallback onTap,
    ) => ChoiceChip(
      key: Key(key),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: _actionColor,
      side: BorderSide(color: selected ? _pink : const Color(0xFFEDE7EB)),
      labelStyle: TextStyle(
        color: selected ? _pink : _ink,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );

    Widget title(String text) => Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                    'favorites.filters'.tr(),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (categoryId != null || brandId != null)
                  TextButton(
                    key: const Key('favorites-filters-reset'),
                    onPressed: () => onChanged(null, null),
                    style: TextButton.styleFrom(foregroundColor: _pink),
                    child: Text('cart.reset'.tr()),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            title('cart.categories_title'.tr()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in categories)
                  choice(
                    'favorites-filter-category-$id',
                    'cart.categories.$id'.tr().replaceAll('\n', ' '),
                    id == categoryId,
                    () => onChanged(id == categoryId ? null : id, brandId),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            title('cart.brands'.tr()),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final brand in brands)
                  choice(
                    'favorites-filter-brand-${brand.id}',
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
