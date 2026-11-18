import 'package:flutter/material.dart';

/// The top row of the profile designs: a back button and a centered title.
class TitleHeader extends StatelessWidget {
  const TitleHeader({
    required this.title,
    required this.backKey,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w600,
    super.key,
  });

  final String title;
  final Key backKey;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 44,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          left: 12,
          child: IconButton(
            key: backKey,
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF151515),
              size: 22,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                color: const Color(0xFF151515),
                fontSize: fontSize,
                fontWeight: fontWeight,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
