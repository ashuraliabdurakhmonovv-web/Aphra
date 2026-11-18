import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/title_header.dart';

/// The pink of the app, as in the bottom navigation.
const _pink = Color(0xFFCC1F8D);
const _ink = Color(0xFF151515);
const _muted = Color(0xFF7A6F78);
const _glass = Color(0xC7FFFFFF);
const _glassShadow = [
  BoxShadow(color: Color(0x1AB2416F), blurRadius: 18, offset: Offset(0, 6)),
];

/// Side padding of the cards.
const _side = 17.0;

/// The user's promo codes, until promo codes have an API.
const _promoCodes = [
  (code: 'BEAUTY20', description: 'profile.promo_beauty'),
  (code: 'WELCOME', description: 'profile.promo_welcome'),
];

/// Bonus points and promo codes, on the flowers of the design.
class BonusesPage extends StatefulWidget {
  const BonusesPage({super.key});

  @override
  State<BonusesPage> createState() => _BonusesPageState();
}

class _BonusesPageState extends State<BonusesPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _showMessage(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));

  void _apply() {
    FocusScope.of(context).unfocus();
    final code = _code.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMessage('profile.promo_enter'.tr());
    } else if (_promoCodes.any((promo) => promo.code == code)) {
      _showMessage('profile.promo_have'.tr(args: [code]));
    } else {
      _showMessage('profile.promo_soon'.tr());
    }
  }

  Future<void> _copy(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) _showMessage('profile.code_copied'.tr());
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    // Outside the scaffold, so the keyboard does not resize the flowers.
    decoration: const BoxDecoration(
      color: Color(0xFFFCEFF4),
      image: DecorationImage(
        image: AssetImage('assets/images/bonuses/background.jpg'),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      ),
    ),
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: DefaultTextStyle.merge(
        style: const TextStyle(color: _ink, height: 1.2, letterSpacing: 0),
        child: SafeArea(
          bottom: false,
          child: ListView(
            // Leaves room for the floating bottom navigation.
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: TitleHeader(
                  title: 'profile.bonuses'.tr(),
                  backKey: const Key('bonuses-back'),
                ),
              ),
              const SizedBox(height: 14),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: _side),
                child: _PointsCard(points: '1 900'),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'profile.promo_codes'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 17),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _side),
                child: _CodeField(controller: _code, onApply: _apply),
              ),
              const SizedBox(height: 18),
              for (final promo in _promoCodes)
                Padding(
                  padding: const EdgeInsets.fromLTRB(_side, 0, _side, 10),
                  child: _PromoCard(
                    code: promo.code,
                    description: promo.description.tr(),
                    onCopy: () => _copy(promo.code),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.points});

  final String points;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('bonuses-points'),
    height: 112,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xCCFFFFFF), width: 1.2),
      image: const DecorationImage(
        image: AssetImage('assets/images/bonuses/points_card.jpg'),
        fit: BoxFit.cover,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x29D2669E),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    padding: const EdgeInsets.only(left: 23, right: 16),
    child: Row(
      children: [
        Container(
          width: 61,
          height: 61,
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
            Icons.card_giftcard_outlined,
            color: _pink,
            size: 27,
          ),
        ),
        const SizedBox(width: 19),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  points,
                  style: const TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'profile.bonus_points'.tr(),
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller, required this.onApply});

  final TextEditingController controller;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: _glass,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: Colors.white, width: 1.2),
      boxShadow: _glassShadow,
    ),
    padding: const EdgeInsets.only(left: 19, right: 6),
    child: Row(
      children: [
        const Icon(Icons.confirmation_number_outlined, color: _pink, size: 24),
        const SizedBox(width: 18),
        Expanded(
          child: TextField(
            key: const Key('bonuses-code'),
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onApply(),
            style: const TextStyle(color: _ink, fontSize: 14.5),
            decoration: InputDecoration(
              hintText: 'profile.promo_hint'.tr(),
              hintStyle: const TextStyle(color: _muted, fontSize: 14.5),
              isCollapsed: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Long translations shrink instead of pushing out the field.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: FilledButton(
            key: const Key('bonuses-apply'),
            onPressed: onApply,
            style: FilledButton.styleFrom(
              // The app theme makes filled buttons full width.
              minimumSize: const Size(0, 38),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: _pink,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('profile.promo_apply'.tr()),
            ),
          ),
        ),
      ],
    ),
  );
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.code,
    required this.description,
    required this.onCopy,
  });

  final String code;
  final String description;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('bonuses-promo-$code'),
    constraints: const BoxConstraints(minHeight: 71),
    decoration: BoxDecoration(
      color: _glass,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white, width: 1.2),
      boxShadow: _glassShadow,
    ),
    padding: const EdgeInsets.fromLTRB(19, 12, 10, 12),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: const TextStyle(
                  color: _pink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: Key('bonuses-copy-$code'),
          onPressed: onCopy,
          tooltip: 'profile.copy_code'.tr(),
          icon: const Icon(Icons.copy_outlined, color: _ink, size: 22),
        ),
      ],
    ),
  );
}
