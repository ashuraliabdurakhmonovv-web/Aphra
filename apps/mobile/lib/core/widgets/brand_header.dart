import 'package:flutter/material.dart';

/// The top row of the APHRA designs: a back button, the logo in the middle
/// and an optional action on the right.
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    required this.backKey,
    this.onBack,
    this.action,
    super.key,
  });

  final Key backKey;

  /// Defaults to closing the page.
  final VoidCallback? onBack;
  final Widget? action;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 6,
          child: IconButton(
            key: backKey,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF111111),
              size: 22,
            ),
          ),
        ),
        Image.asset(
          'assets/images/brand/aphra_logo.png',
          height: 34,
          semanticLabel: 'APHRA',
        ),
        if (action case final action?) Positioned(right: 11, child: action),
      ],
    ),
  );
}
