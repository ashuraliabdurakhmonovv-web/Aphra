import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/title_header.dart';

/// The pink of the app, as in the bottom navigation.
const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF151515);
const _muted = Color(0xFF8A8290);
const _green = Color(0xFF1E9E68);
const _tint = Color(0xFFFADDEF);

/// The flat color the background picture fades into at its edges.
const _background = Color(0xFFFEF2FB);
const _shadow = [
  BoxShadow(color: Color(0x14B2416F), blurRadius: 16, offset: Offset(0, 6)),
];

/// The background picture and where the credits card sits in it, in the
/// picture's pixels. The card is drawn by the picture, so the flower behind
/// it lines up on every screen width.
const _picture = Size(672, 1384);
const _cardInPicture = Rect.fromLTWH(28, 194, 616, 161);

/// Side padding of the cards.
const _side = 17.0;

/// Side padding of the headings and the history.
const _textSide = 18.0;
const _headerHeight = 44.0;
const _cardTop = _headerHeight + 14;

/// Demo data until payments have an API.
const _credits = 86;
const _history = [
  (title: 'profile.premium', date: '12.10.2026', amount: -14),
  (title: 'profile.credit_topup', date: '01.10.2026', amount: 100),
  (title: 'profile.credit_purchase', date: '27.09.2026', amount: 50),
];

/// Credits, saved bank cards and the history of operations.
class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  static void _soon(BuildContext context, String key) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(key.tr())));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: DefaultTextStyle.merge(
      style: const TextStyle(color: _ink, height: 1.2, letterSpacing: 0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale =
              (constraints.maxWidth - 2 * _side) / _cardInPicture.width;
          return SingleChildScrollView(
            // Leaves room for the floating bottom navigation.
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top,
              bottom: 120,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: _side - _cardInPicture.left * scale,
                  top: _cardTop - _cardInPicture.top * scale,
                  width: _picture.width * scale,
                  height: _picture.height * scale,
                  child: Image.asset(
                    'assets/images/payments/background.jpg',
                    fit: BoxFit.fill,
                    excludeFromSemantics: true,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TitleHeader(
                      title: 'profile.payments'.tr(),
                      backKey: const Key('payments-back'),
                      fontSize: 19.5,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: _cardTop - _headerHeight),
                    SizedBox(
                      height: _cardInPicture.height * scale,
                      child: const _CreditsCard(credits: _credits),
                    ),
                    const SizedBox(height: 19),
                    _Heading(
                      'profile.my_cards'.tr(),
                      action: _ManageLink(
                        onTap: () => _soon(context, 'profile.cards_soon'),
                      ),
                    ),
                    const SizedBox(height: 11),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: _side),
                      child: SizedBox(
                        height: 94,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Expanded(
                              flex: 186,
                              child: _BankCard(last4: '4821'),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              flex: 172,
                              child: _AddCard(
                                onTap: () =>
                                    _soon(context, 'profile.cards_soon'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    _BuyButton(
                      onTap: () => _soon(context, 'profile.credits_soon'),
                    ),
                    const SizedBox(height: 15),
                    _MethodsTile(
                      onTap: () => _soon(context, 'profile.cards_soon'),
                    ),
                    const SizedBox(height: 16),
                    _Heading('profile.payment_history'.tr()),
                    const SizedBox(height: 7),
                    for (final (index, item) in _history.indexed)
                      _Operation(
                        key: Key('payments-operation-$index'),
                        title: item.title.tr(),
                        date: item.date,
                        amount: item.amount,
                        divider: index < _history.length - 1,
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// The content of the credits card; the card itself is in the picture.
class _CreditsCard extends StatelessWidget {
  const _CreditsCard({required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(_side + 25, 0, _side + 16, 0),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x14B2416F),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: _pink,
            size: 28,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$credits',
                  key: const Key('payments-credits'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'profile.available_credits'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.action});

  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _textSide),
    child: Row(
      // Keeps the action at the right edge when it is narrower than its
      // share of the row.
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ),
        if (action case final action?) Flexible(child: action),
      ],
    ),
  );
}

class _ManageLink extends StatelessWidget {
  const _ManageLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('payments-manage'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'profile.manage_cards'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _pink,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _pink, size: 19),
        ],
      ),
    ),
  );
}

class _BankCard extends StatelessWidget {
  const _BankCard({required this.last4});

  final String last4;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('payments-card-$last4'),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xCCFFFFFF)),
      image: const DecorationImage(
        image: AssetImage('assets/images/payments/visa_card.jpg'),
        fit: BoxFit.cover,
      ),
      boxShadow: _shadow,
    ),
    padding: const EdgeInsets.fromLTRB(16, 11, 11, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'VISA',
              style: TextStyle(
                color: Color(0xFF1F3A93),
                fontSize: 16,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -.2,
              ),
            ),
            const Spacer(),
            Flexible(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8D3EA),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  'profile.main_card'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _pink,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '**** ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .8,
                      ),
                    ),
                    TextSpan(
                      text: last4,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
              ),
            ),
            const CustomPaint(
              size: Size(16, 22),
              painter: _ContactlessWaves(color: Color(0xCCCC1F8D)),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ],
    ),
  );
}

class _AddCard extends StatelessWidget {
  const _AddCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: const _DashedBorder(
      color: Color(0xFFEDB5D8),
      radius: 18,
    ),
    child: Material(
      color: const Color(0x66FFFFFF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('payments-add-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: const BoxDecoration(
                  color: _tint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: _pink, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                'profile.add_card'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.6),
          Radius.circular(radius),
        ),
      );
    for (final metric in border.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 9) {
        canvas.drawPath(
          metric.extractPath(start, math.min(start + 5, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Three arcs of a contactless card.
class _ContactlessWaves extends CustomPainter {
  const _ContactlessWaves({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    final center = Offset(0, size.height / 2);
    for (final radius in [size.width * .4, size.width * .7, size.width]) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        -math.pi / 4,
        math.pi / 2,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ContactlessWaves oldDelegate) =>
      oldDelegate.color != color;
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        gradient: LinearGradient(
          colors: [Color(0xFFDA35A0), Color(0xFFC71A89)],
        ),
        shadows: [
          BoxShadow(
            color: Color(0x40CC1F8D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('payments-buy'),
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                'profile.buy_credits'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MethodsTile extends StatelessWidget {
  const _MethodsTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _side),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFCF1F9), Color(0xFFFBE8F4)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xB3FFFFFF)),
        boxShadow: _shadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const Key('payments-methods'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 59,
            child: Padding(
              padding: const EdgeInsets.only(left: 18, right: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: _tint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.credit_card_outlined,
                      color: _pink,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 19),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'profile.payment_methods'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Shrinks rather than cutting "secure payment".
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'profile.bank_cards'.tr()),
                                const TextSpan(text: ' • '),
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Icon(
                                    Icons.verified_user_outlined,
                                    color: _green,
                                    size: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${'profile.secure_payment'.tr()}',
                                ),
                              ],
                            ),
                            maxLines: 1,
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _muted,
                    size: 24,
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

class _Operation extends StatelessWidget {
  const _Operation({
    required this.title,
    required this.date,
    required this.amount,
    required this.divider,
    super.key,
  });

  final String title;
  final String date;
  final int amount;
  final bool divider;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 20, right: _textSide),
    child: SizedBox(
      height: 51,
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: const BoxDecoration(
              color: _tint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: _pink,
              size: 21,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: divider
                    ? const Border(bottom: BorderSide(color: Color(0xFFF1E1EC)))
                    : null,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          date,
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    amount > 0 ? '+$amount' : '$amount',
                    style: TextStyle(
                      color: amount > 0 ? _green : _ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
