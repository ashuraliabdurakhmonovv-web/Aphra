import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../explore/domain/entities/place.dart';
import '../../../home/presentation/widgets/salon_summary.dart'
    show openSalonPage, price;
import '../../../favorites/presentation/favorites.dart';
import '../../data/datasources/shop_preview_catalog.dart';
import '../shop_cart.dart';
import '../shop_colors.dart';

const _pink = ShopColors.pink;
const _ink = ShopColors.ink;
const _text = Color(0xFF5B616B);
const _maxQuantity = 99;

/// Opens [product] over the tab bar.
void openProductPage(BuildContext context, ShopProduct product) => Navigator.of(
  context,
  rootNavigator: true,
).push(MaterialPageRoute<void>(builder: (_) => ProductPage(product: product)));

/// Product details: photos, seller salon, description, shade and quantity.
class ProductPage extends StatefulWidget {
  const ProductPage({required this.product, super.key});

  final ShopProduct product;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  late ShopShade? _shade = widget.product.shades.firstOrNull;
  var _quantity = 1;

  final _favorites = Favorites.shared.products;

  ShopProduct get _product => widget.product;

  void _showMessage(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _addToCart() {
    ShopCart.shared.add(_product, quantity: _quantity, shade: _shade);
    final name = [
      _product.fullName,
      if (_shade case final shade?) shade.name,
    ].join(', ');
    _showMessage(
      'cart.added'.tr(args: [_quantity > 1 ? '$name × $_quantity' : name]),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFFF4F8),
    bottomNavigationBar: _Actions(
      total: price(_product.price * _quantity),
      onAdd: _addToCart,
    ),
    body: DefaultTextStyle.merge(
      style: const TextStyle(color: _ink, height: 1.2, letterSpacing: 0),
      child: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFE8F0), Color(0xFFFFF9FC)],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: math.min(
                    MediaQuery.sizeOf(context).height * .43,
                    360.0,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _Photos(photos: _product.photos),
                      Positioned(
                        top: MediaQuery.viewPaddingOf(context).top + 24,
                        left: 0,
                        right: 0,
                        child: ListenableBuilder(
                          listenable: _favorites,
                          builder: (context, _) => _TopBar(
                            favorite: _favorites.contains(_product),
                            onFavorite: () => _favorites.toggle(_product),
                            onShare: () =>
                                _showMessage('cart.product.share_soon'.tr()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFCFE),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Summary(product: _product),
                        const SizedBox(height: 14),
                        _Seller(
                          salon: _product.seller,
                          onOpen: () => openSalonPage(context, _product.seller),
                        ),
                        const SizedBox(height: 12),
                        _Description(
                          text: 'cart.product_descriptions.${_product.id}'.tr(),
                        ),
                        const SizedBox(height: 12),
                        _Specifications(
                          text: 'cart.product_descriptions.${_product.id}'.tr(),
                        ),
                        const SizedBox(height: 14),
                        _Options(
                          shades: _product.shades,
                          shade: _shade,
                          quantity: _quantity,
                          onShade: (shade) => setState(() => _shade = shade),
                          onQuantity: (quantity) =>
                              setState(() => _quantity = quantity),
                        ),
                        const SizedBox(height: 14),
                        const _Benefits(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.favorite,
    required this.onFavorite,
    required this.onShare,
  });

  final bool favorite;
  final VoidCallback onFavorite;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: SizedBox(
      height: 40,
      child: Row(
        children: [
          IconButton(
            key: const Key('product-back'),
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(Icons.arrow_back_rounded, color: _ink, size: 27),
          ),
          const Spacer(),
          IconButton(
            key: const Key('product-favorite'),
            onPressed: onFavorite,
            tooltip: 'cart.product.favorite'.tr(),
            icon: Icon(
              favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: favorite ? _pink : _ink,
              size: 27,
            ),
          ),
          IconButton(
            key: const Key('product-share'),
            onPressed: onShare,
            tooltip: 'cart.product.share'.tr(),
            icon: const Icon(Icons.ios_share_rounded, color: _ink, size: 25),
          ),
        ],
      ),
    ),
  );
}

class _Photos extends StatefulWidget {
  const _Photos({required this.photos});

  final List<String> photos;

  @override
  State<_Photos> createState() => _PhotosState();
}

class _PhotosState extends State<_Photos> {
  var _page = 0;

  @override
  Widget build(BuildContext context) => ClipRRect(
    child: AspectRatio(
      aspectRatio: 1.18,
      child: ColoredBox(
        color: const Color(0xFFFFE9F0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              key: const Key('product-photos'),
              itemCount: widget.photos.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (_, index) {
                final photo = widget.photos[index];
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.scale(
                    scale: 1.1,
                    child: Image.asset(photo, fit: BoxFit.contain),
                  ),
                );
              },
            ),
            if (widget.photos.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: _Dots(count: widget.photos.length, active: _page),
              ),
          ],
        ),
      ),
    ),
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var index = 0; index < count; index++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: index == active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: index == active ? _pink : const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
    ],
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.product});

  final ShopProduct product;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        product.fullName,
        style: const TextStyle(
          fontFamily: 'Georgia',
          fontFamilyFallback: ['Times New Roman', 'serif'],
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -.45,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        'cart.product_types.${product.typeId}'.tr(),
        style: const TextStyle(color: _text, fontSize: 15),
      ),
      const SizedBox(height: 3),
      Wrap(
        spacing: 9,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3F7),
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: ShopColors.star,
                  size: 21,
                ),
                const SizedBox(width: 4),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  'cart.product.reviews'.plural(product.reviews),
                  style: const TextStyle(color: _text, fontSize: 13),
                ),
              ],
            ),
          ),
          const _OriginalBadge(),
        ],
      ),
      const SizedBox(height: 3),
      Text(
        price(product.price),
        style: const TextStyle(
          color: Color(0xFF4A1635),
          fontSize: 25,
          fontWeight: FontWeight.w800,
          letterSpacing: -.4,
        ),
      ),
    ],
  );
}

class _OriginalBadge extends StatelessWidget {
  const _OriginalBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 4, 11, 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE5F5F0),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.verified_user_rounded,
          color: Color(0xFF13A071),
          size: 17,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'cart.product.original'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _Seller extends StatelessWidget {
  const _Seller({required this.salon, required this.onOpen});

  final Place salon;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(9, 5, 10, 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [Color(0xFFFBE8F4), Color(0xFFFDF4F9)],
      ),
    ),
    child: Row(
      children: [
        _Monogram(name: salon.name),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      salon.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (salon.isVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.check_circle_rounded,
                      key: Key('product-seller-verified'),
                      color: _pink,
                      size: 18,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    color: ShopColors.star,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    salon.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 178),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('product-salon'),
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 2, 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'cart.product.salon_page'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _pink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _pink,
                      size: 23,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// The salon's initials in a round badge, until salons have logos.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.name});

  final String name;

  String get _initials => name
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFFE9D3E2), width: 1.2),
    ),
    child: Text(
      _initials,
      style: const TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: ['Times New Roman', 'serif'],
        fontSize: 19,
        fontWeight: FontWeight.w400,
        letterSpacing: -.5,
        height: 1,
      ),
    ),
  );
}

class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  var _expanded = false;

  static const _style = TextStyle(color: _text, fontSize: 15, height: 1.3);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: _style),
            maxLines: 2,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final long = painter.didExceedMaxLines;
          painter.dispose();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.topCenter,
                child: Text(
                  widget.text,
                  key: const Key('product-description'),
                  maxLines: _expanded ? null : 2,
                  overflow: _expanded ? null : TextOverflow.ellipsis,
                  style: _style,
                ),
              ),
              if (long)
                InkWell(
                  key: const Key('product-description-toggle'),
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          (_expanded
                                  ? 'cart.product.less'
                                  : 'cart.product.more')
                              .tr(),
                          style: const TextStyle(
                            color: _pink,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _pink,
                          size: 21,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _Specifications extends StatefulWidget {
  const _Specifications({required this.text});

  final String text;

  @override
  State<_Specifications> createState() => _SpecificationsState();
}

class _SpecificationsState extends State<_Specifications> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFFFF9FC),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFF4DCE9)),
    ),
    child: Column(
      children: [
        InkWell(
          key: const Key('product-specifications'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.water_drop_outlined, color: _pink, size: 23),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'cart.product.specifications'.tr(),
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: _pink,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(50, 0, 16, 14),
            child: Text(
              widget.text,
              style: const TextStyle(color: _text, fontSize: 14, height: 1.35),
            ),
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 180),
        ),
      ],
    ),
  );
}

/// The shade swatches and the quantity stepper.
class _Options extends StatelessWidget {
  const _Options({
    required this.shades,
    required this.shade,
    required this.quantity,
    required this.onShade,
    required this.onQuantity,
  });

  final List<ShopShade> shades;
  final ShopShade? shade;
  final int quantity;
  final ValueChanged<ShopShade> onShade;
  final ValueChanged<int> onQuantity;

  static const _titleStyle = TextStyle(
    fontSize: 16.5,
    fontWeight: FontWeight.w800,
  );

  @override
  Widget build(BuildContext context) {
    final stepper = _Stepper(quantity: quantity, onChanged: onQuantity);
    if (shades.isEmpty) {
      return Center(child: SizedBox(width: 136, child: stepper));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'cart.product.shade'.tr(),
                  style: _titleStyle,
                  children: [
                    if (shade case final shade?)
                      TextSpan(
                        text: '  ${shade.name}',
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final item in shades)
                    _Swatch(
                      shade: item,
                      selected: item.id == shade?.id,
                      onTap: () => onShade(item),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: _Stepper.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('cart.product.quantity'.tr(), style: _titleStyle),
              ),
              const SizedBox(height: 3),
              stepper,
            ],
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.shade,
    required this.selected,
    required this.onTap,
  });

  final ShopShade shade;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(shade.color, Colors.white, .35)!;
    return Semantics(
      label: shade.name,
      selected: selected,
      button: true,
      child: Tooltip(
        message: shade.name,
        child: InkResponse(
          key: Key('product-shade-${shade.id}'),
          onTap: onTap,
          radius: 22,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? _pink : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              width: selected ? 29 : 32,
              height: selected ? 29 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-.35, -.45),
                  radius: .9,
                  colors: [light, shade.color],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14991A6A),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.quantity, required this.onChanged});

  static const width = 112.0;

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget button(Key key, IconData icon, Color color, int? value) => SizedBox(
      width: 38,
      height: 38,
      child: IconButton(
        key: key,
        onPressed: value == null ? null : () => onChanged(value),
        padding: EdgeInsets.zero,
        color: color,
        disabledColor: const Color(0xFFC9CDD3),
        icon: Icon(icon, size: 22),
      ),
    );

    return Container(
      width: width,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3D8EA), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            const Key('product-quantity-minus'),
            Icons.remove_rounded,
            _ink,
            quantity > 1 ? quantity - 1 : null,
          ),
          Expanded(
            child: Container(
              height: double.infinity,
              alignment: Alignment.center,
              color: const Color(0xFFFCF6FA),
              child: Text(
                '$quantity',
                key: const Key('product-quantity'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          button(
            const Key('product-quantity-plus'),
            Icons.add_rounded,
            _pink,
            quantity < _maxQuantity ? quantity + 1 : null,
          ),
        ],
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label) => Expanded(
      child: Row(
        children: [
          Icon(icon, color: _pink, size: 24),
          const SizedBox(width: 8),
          // Long translations shrink rather than lose their end.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(fontSize: 12, height: 1.25),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEAF4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          item(Icons.local_shipping_outlined, 'cart.product.delivery'.tr()),
          const SizedBox(width: 6),
          item(Icons.verified_user_outlined, 'cart.product.genuine'.tr()),
          const SizedBox(width: 6),
          item(Icons.undo_rounded, 'cart.product.returns'.tr()),
        ],
      ),
    );
  }
}

/// The add to cart button, pinned under the page.
class _Actions extends StatelessWidget {
  const _Actions({required this.total, required this.onAdd});

  final String total;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    // The buttons may come a little into the home indicator area, as in the
    // design.
    final bottom = math.max(MediaQuery.viewPaddingOf(context).bottom - 8, 10.0);
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFFFFCFE)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(18, 8, 18, bottom),
        child: SizedBox(
          height: 54,
          child: Material(
            color: _pink,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('product-add'),
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 25,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'cart.product.add'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      total,
                      key: const Key('product-total'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
