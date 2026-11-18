import 'package:flutter/material.dart';

/// Colors of the shop designs, shared by the shop tab and the product page.
///
/// The pink is the app's magenta of the bottom navigation, not the red-pink
/// of the shop mockups.
abstract final class ShopColors {
  static const pink = Color(0xFFCC1F8D);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF6C757D);
  static const hint = Color(0xFF9AA0AA);
  static const background = Color(0xFFFDF7F9);
  static const tile = Color(0xFFFAEAF4);
  static const image = Color(0xFFFCF4F9);
  static const star = Color(0xFFFEC00E);
  static const shadow = [
    BoxShadow(color: Color(0x12991A6A), blurRadius: 10, offset: Offset(0, 2)),
  ];
}
