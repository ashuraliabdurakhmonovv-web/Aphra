import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/salon_summary.dart' show price;
import '../shop_cart.dart';
import '../shop_colors.dart';

const _pink = ShopColors.pink;
const _ink = ShopColors.ink;
const _muted = ShopColors.muted;
const _surface = Color(0xF9FFFFFF);

class ShopCartPage extends StatefulWidget {
  const ShopCartPage({super.key});

  @override
  State<ShopCartPage> createState() => _ShopCartPageState();
}

class _ShopCartPageState extends State<ShopCartPage> {
  final _cart = ShopCart.shared;

  @override
  void initState() {
    super.initState();
    _cart.addListener(_refresh);
  }

  @override
  void dispose() {
    _cart.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go('/cart');
    }
  }

  Future<void> _openPromo() async {
    final code = await showDialog<String>(
      context: context,
      builder: (context) => const _PromoDialog(),
    );
    if (!mounted || code == null) return;
    _showMessage('profile.promo_soon'.tr());
  }

  Future<void> _clearCart() async {
    if (_cart.isEmpty) return;
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('cart.clear_title'.tr()),
        content: Text('cart.clear_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cart.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'cart.clear'.tr(),
              style: const TextStyle(color: _pink),
            ),
          ),
        ],
      ),
    );
    if (clear == true) _cart.clear();
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final lines = _cart.lines;
    final total = _cart.total;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F9),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF8FB), Color(0xFFFFEDF4)],
                ),
              ),
            ),
          ),
          Positioned(
            top: -48,
            right: -76,
            width: 230,
            height: 230,
            child: IgnorePointer(
              child: Opacity(
                opacity: .5,
                child: Image.asset(
                  'assets/images/notifications/pink_lily.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -88,
            left: -90,
            width: 245,
            height: 230,
            child: IgnorePointer(
              child: Opacity(
                opacity: .42,
                child: Transform.rotate(
                  angle: 3.14159,
                  child: Image.asset(
                    'assets/images/notifications/pink_lily.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _CartHeader(
                  count: _cart.count,
                  canClear: !_cart.isEmpty,
                  onBack: _goBack,
                  onClear: _clearCart,
                ),
                Expanded(
                  child: lines.isEmpty
                      ? _EmptyCart(onBack: _goBack)
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            MediaQuery.viewPaddingOf(context).bottom + 28,
                          ),
                          children: [
                            for (final line in lines) ...[
                              _CartItemCard(
                                line: line,
                                onRemove: () => _cart.remove(line),
                                onQuantity: (quantity) =>
                                    _cart.setQuantity(line, quantity),
                              ),
                              const SizedBox(height: 12),
                            ],
                            const SizedBox(height: 7),
                            _PromoTile(onTap: _openPromo),
                            const SizedBox(height: 12),
                            _OrderSummary(
                              itemCount: lines.length,
                              total: total,
                            ),
                            const SizedBox(height: 22),
                            _CheckoutButton(
                              onTap: () =>
                                  _showMessage('cart.checkout_soon'.tr()),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartHeader extends StatelessWidget {
  const _CartHeader({
    required this.count,
    required this.canClear,
    required this.onBack,
    required this.onClear,
  });

  final int count;
  final bool canClear;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(
      children: [
        const SizedBox(height: 36),
        SizedBox(
          height: 42,
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              key: const Key('shop-cart-back'),
              onPressed: onBack,
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 32,
                color: _ink,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'cart.page_title'.tr(args: ['$count']),
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                key: const Key('shop-cart-clear'),
                onPressed: canClear ? onClear : null,
                tooltip: 'cart.clear'.tr(),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: canClear ? _ink : const Color(0xFFB8B0B5),
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.line,
    required this.onRemove,
    required this.onQuantity,
  });

  final ShopCartLine line;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantity;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x120E0820),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: ColoredBox(
            color: const Color(0xFFFCE5F0),
            child: Image.asset(
              line.product.image,
              width: 80,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      line.product.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.16,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: IconButton(
                      key: Key(
                        'shop-cart-remove-${line.product.id}-${line.shade?.id ?? 'default'}',
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onRemove,
                      tooltip: 'cart.remove_item'.tr(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF777780),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              if (line.shade case final shade?) ...[
                const SizedBox(height: 2),
                Text(
                  shade.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      price(line.product.price * line.quantity),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _CartQuantity(quantity: line.quantity, onChanged: onQuantity),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CartQuantity extends StatelessWidget {
  const _CartQuantity({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 31,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCFE),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF3CFE3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QuantityButton(
          icon: Icons.remove_rounded,
          enabled: quantity > 1,
          onTap: () => onChanged(quantity - 1),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        _QuantityButton(
          icon: Icons.add_rounded,
          enabled: quantity < 99,
          onTap: () => onChanged(quantity + 1),
          pink: true,
        ),
      ],
    ),
  );
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.pink = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool pink;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 30,
    child: IconButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? onTap : null,
      icon: Icon(
        icon,
        size: 17,
        color: enabled ? (pink ? _pink : _muted) : const Color(0xFFD6CDD2),
      ),
    ),
  );
}

class _PromoTile extends StatelessWidget {
  const _PromoTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _surface,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      key: const Key('shop-cart-promo'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
        child: Row(
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              color: _pink,
              size: 25,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'cart.promo_code'.tr(),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _muted, size: 24),
          ],
        ),
      ),
    ),
  );
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.itemCount, required this.total});

  final int itemCount;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 19, 18, 18),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      children: [
        _SummaryRow(
          label: 'cart.items_count'.tr(args: ['$itemCount']),
          value: price(total),
        ),
        const SizedBox(height: 12),
        _SummaryRow(label: 'cart.discount'.tr(), value: '—', muted: true),
        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF2D9E7)),
        const SizedBox(height: 12),
        _SummaryRow(
          label: 'cart.total_to_pay'.tr(),
          value: price(total),
          strong: true,
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
    this.muted = false,
  });

  final String label;
  final String value;
  final bool strong;
  final bool muted;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: muted ? _muted : _ink,
            fontSize: strong ? 16 : 14,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        value,
        style: TextStyle(
          color: muted ? _muted : _ink,
          fontSize: strong ? 17 : 14,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w400,
        ),
      ),
    ],
  );
}

class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: _pink,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          key: const Key('shop-cart-checkout'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 23),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'cart.go_to_payment'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PromoDialog extends StatefulWidget {
  const _PromoDialog();

  @override
  State<_PromoDialog> createState() => _PromoDialogState();
}

class _PromoDialogState extends State<_PromoDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('cart.promo_code'.tr()),
    content: TextField(
      key: const Key('shop-cart-promo-input'),
      controller: _controller,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(hintText: 'profile.promo_hint'.tr()),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('cart.cancel'.tr()),
      ),
      TextButton(
        onPressed: () {
          if (_controller.text.trim().isNotEmpty) {
            Navigator.pop(context, _controller.text.trim());
          }
        },
        child: Text('profile.promo_apply'.tr()),
      ),
    ],
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shopping_bag_outlined, color: _pink, size: 54),
          const SizedBox(height: 14),
          Text(
            'cart.cart_empty'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onBack, child: Text('cart.back_to_shop'.tr())),
        ],
      ),
    ),
  );
}
