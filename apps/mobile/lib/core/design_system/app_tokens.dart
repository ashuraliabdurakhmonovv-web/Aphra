import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFFC12391);
  static const primaryHover = Color(0xFFAC1F7D);
  static const cashback = Color(0xFFE60093);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F7F8);
  static const softPink = Color(0xFFF8EAF1);
  static const roseSurface = Color(0xFFE8BCD1);
  static const input = Color(0xFFF3F3F3);
  static const textPrimary = Color(0xFF151515);
  static const textSecondary = Color(0xFF898989);
  static const border = Color(0xFFE6E6E6);
  static const success = Color(0xFF24A46D);
  static const error = Color(0xFFDC4545);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}
