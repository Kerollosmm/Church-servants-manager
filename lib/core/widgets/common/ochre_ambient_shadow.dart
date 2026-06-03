import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class OchreAmbientShadow {
  /// Level 1: A broad, diffused shadow for cards.
  static final List<BoxShadow> level1 = [
    BoxShadow(
      color: AppColors.black.withValues(alpha: 0.05),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];

  /// Level 2: A color-tinted cast for buttons (glow effect).
  static final List<BoxShadow> level2 = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -2,
    ),
  ];
}
