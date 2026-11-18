import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/brand_header.dart';

/// The pink of the app, as in the bottom navigation.
const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF111111);
const _text = Color(0xFF5E5862);
const _background = Color(0xFFFDF7F9);
const _shadow = [
  BoxShadow(color: Color(0x0F9A1F55), blurRadius: 12, offset: Offset(0, 3)),
];

/// Support contacts, as in the design. Check them before a release: the app
/// calls and opens them as they are.
abstract final class SupportContacts {
  static const phone = '+998 71 200 00 00';
  static const telegram = 'aphra_support';
}

enum _Faq {
  reschedule(Icons.edit_calendar_outlined),
  credits(Icons.credit_card_outlined),
  cancel(Icons.undo_rounded),
  productReturn(null),
  payment(Icons.payments_outlined);

  const _Faq(this.icon);

  /// Null draws a parcel.
  final IconData? icon;

  String get _key => switch (this) {
    _Faq.productReturn => 'return',
    _ => name,
  };
  String get question => 'support.questions.$_key.question'.tr();
  String get answer => 'support.questions.$_key.answer'.tr();

  /// The questions on the support page; the rest are under "All questions".
  static const featured = [reschedule, credits, cancel, productReturn];
}

/// Support: contacts and frequent questions.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static void _showMessage(
    BuildContext context,
    String text, {
    SnackBarAction? action,
  }) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), action: action));

  static Future<bool> _launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }

  static Future<void> _call(BuildContext context) async {
    final digits = SupportContacts.phone.replaceAll(' ', '');
    if (await _launch(Uri(scheme: 'tel', path: digits))) return;
    if (!context.mounted) return;
    _showMessage(
      context,
      'support.call_failed'.tr(args: [SupportContacts.phone]),
    );
  }

  static Future<void> _openTelegram(BuildContext context) async {
    final uri = Uri.https('t.me', '/${SupportContacts.telegram}');
    if (await _launch(uri)) return;
    if (!context.mounted) return;
    _showMessage(
      context,
      'support.telegram_failed'.tr(args: [SupportContacts.telegram]),
    );
  }

  /// There is no in-app chat yet, so the message offers Telegram.
  static void _openChat(BuildContext context) => _showMessage(
    context,
    'support.chat_soon'.tr(),
    action: SnackBarAction(
      label: 'support.telegram'.tr(),
      textColor: const Color(0xFFF29BD0),
      onPressed: () => _openTelegram(context),
    ),
  );

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(21, 8, 21, 0),
        child: Text(
          'support.title'.tr(),
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 10),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: _Banner(),
      ),
      const SizedBox(height: 14),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ContactCard(
                key: const Key('support-chat'),
                icon: Icons.chat_bubble_outline_rounded,
                title: 'support.chat'.tr(),
                subtitle: 'support.chat_hint'.tr(),
                onTap: () => _openChat(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ContactCard(
                key: const Key('support-call'),
                icon: Icons.call_outlined,
                title: 'support.call'.tr(),
                subtitle: SupportContacts.phone,
                onTap: () => _call(context),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ContactCard(
                key: const Key('support-telegram'),
                icon: Icons.send_outlined,
                iconAngle: -math.pi / 7,
                title: 'support.telegram'.tr(),
                subtitle: '@${SupportContacts.telegram}',
                onTap: () => _openTelegram(context),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'support.faq'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              key: const Key('support-all-questions'),
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => const _FaqPage())),
              style: TextButton.styleFrom(
                foregroundColor: _pink,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('support.all_questions'.tr()),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 4),
      for (final faq in _Faq.featured)
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 0, 13, 6),
          child: _FaqRow(faq: faq),
        ),
      const SizedBox(height: 18),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: _NotFoundCard(onWrite: () => _openChat(context)),
      ),
    ],
  );
}

/// The pink page with the logo header shared by the support pages.
class _SupportScaffold extends StatelessWidget {
  const _SupportScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    body: DefaultTextStyle.merge(
      style: const TextStyle(color: _ink, height: 1.2, letterSpacing: 0),
      child: SafeArea(
        bottom: false,
        child: ListView(
          // Leaves room for the floating bottom navigation.
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const BrandHeader(backKey: Key('support-back')),
            ...children,
          ],
        ),
      ),
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: AspectRatio(
      aspectRatio: 788 / 225,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/support/support_banner.jpg',
            fit: BoxFit.cover,
          ),
          // The text keeps clear of the headphones on the right.
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: .62,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 8, 4, 10),
              // Lines keep the breaks of the translation; a long one shrinks
              // the text instead of wrapping.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'support.banner_title'.tr(),
                      softWrap: false,
                      style: const TextStyle(
                        color: _pink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'support.banner_text'.tr(),
                      softWrap: false,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14,
                        height: 1.25,
                        letterSpacing: -.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The light pink square behind an icon.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(size * .28),
    ),
    child: child,
  );
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconAngle = 0,
    super.key,
  });

  final IconData icon;
  final double iconAngle;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFBEAF4),
      borderRadius: BorderRadius.circular(16),
      boxShadow: _shadow,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 5, 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(
                size: 29,
                color: const Color(0xFFF8DCEE),
                child: Transform.rotate(
                  angle: iconAngle,
                  child: Icon(icon, color: _pink, size: 18),
                ),
              ),
              const SizedBox(height: 5),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.1,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        style: const TextStyle(color: _text, fontSize: 11.5),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _pink,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.faq});

  final _Faq faq;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFFEFAFB),
      borderRadius: BorderRadius.circular(19),
      boxShadow: _shadow,
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('support-faq-${faq.name}'),
        onTap: () => _showAnswer(context, faq),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 38),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 2, 14, 2),
            child: Row(
              children: [
                _IconTile(
                  size: 33,
                  color: const Color(0xFFFBE8F4),
                  child: faq.icon == null
                      ? const CustomPaint(
                          size: Size.square(19),
                          painter: _ParcelPainter(),
                        )
                      : Icon(faq.icon, color: _pink, size: 19),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    faq.question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF55505A),
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _showAnswer(BuildContext context, _Faq faq) =>
    showModalBottomSheet<void>(
      context: context,
      // Above the floating bottom navigation.
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Padding(
          key: Key('support-answer-${faq.name}'),
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq.question,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                faq.answer,
                style: const TextStyle(color: _text, fontSize: 15, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );

class _NotFoundCard extends StatelessWidget {
  const _NotFoundCard({required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 58),
    padding: const EdgeInsets.fromLTRB(11, 8, 9, 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFAE6F2),
      borderRadius: BorderRadius.circular(16),
      boxShadow: _shadow,
    ),
    child: Row(
      children: [
        const _IconTile(
          size: 38,
          color: Color(0xFFF5D2EA),
          child: Icon(Icons.mail_outline_rounded, color: _pink, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'support.not_found'.tr(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'support.not_found_hint'.tr(),
                  style: const TextStyle(color: _text, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: FilledButton(
            key: const Key('support-write'),
            onPressed: onWrite,
            style: FilledButton.styleFrom(
              // The app theme makes filled buttons full width.
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.only(left: 15, right: 8),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('support.write'.tr()),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// Every question, opened by "All questions".
class _FaqPage extends StatelessWidget {
  const _FaqPage();

  @override
  Widget build(BuildContext context) => _SupportScaffold(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(21, 8, 21, 12),
        child: Text(
          'support.faq'.tr(),
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
      ),
      for (final faq in _Faq.values)
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 0, 13, 6),
          child: _FaqRow(faq: faq),
        ),
    ],
  );
}

/// A parcel seen from a corner, as in the design.
class _ParcelPainter extends CustomPainter {
  const _ParcelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset at(double x, double y) => Offset(w * x, h * y);
    final top = at(.5, .06);
    final right = at(.93, .28);
    final bottomRight = at(.93, .74);
    final bottom = at(.5, .96);
    final bottomLeft = at(.07, .74);
    final left = at(.07, .28);
    final centre = at(.5, .5);
    final path = Path()
      ..addPolygon([top, right, bottomRight, bottom, bottomLeft, left], true)
      ..moveTo(left.dx, left.dy)
      ..lineTo(centre.dx, centre.dy)
      ..lineTo(right.dx, right.dy)
      ..moveTo(centre.dx, centre.dy)
      ..lineTo(bottom.dx, bottom.dy)
      // The tape across the lid and down the front.
      ..moveTo(w * .285, h * .17)
      ..lineTo(w * .715, h * .39)
      ..lineTo(w * .715, h * .6);
    canvas.drawPath(
      path,
      Paint()
        ..color = _pink
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .095
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ParcelPainter oldDelegate) => false;
}
