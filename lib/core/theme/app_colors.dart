import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors — Warm Gold/Brown/Burgundy Palette
  static const Color primary = Color(0xFFA58255); // Light Brown
  static const Color primaryDark = Color(0xFF795548); // Brown
  static const Color primaryLight = Color(0xFFC9A96E); // Lighter Brown

  static const Color secondary = Color(0xFFFAD375); // Gold / Ocur
  static const Color tertiary = Color(0xFF8B2323); // Burgundy

  // State Colors
  static const Color error = Color(0xFFB42318); // Red 700
  static const Color errorContainer = Color(0xFFFECACA);
  static const Color success = Color(0xFF15803D); // Green 700
  static const Color warning = Color(0xFFB45309); // Amber 700

  // Neutral Colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  static const Color surface = Colors.white;
  static const Color background = Color(0xFFFEFAE9); // Paige / Cream
  static const Color surfaceContainer = Color(0xFFF5EEDC); // Warm grey
  static const Color outline = Color(0xFFC9B896); // Warm outline

  // Text Colors
  static const Color textPrimary = Color(0xFF3E2723); // Brown 900
  static const Color textSecondary = Color(0xFF795548); // Brown 600
  static const Color textTertiary = Color(0xFFA1887F); // Brown 300
  static const Color textInverse = Colors.white;

  // Gradient Colors
  static const List<Color> primaryGradient = [secondary, primaryDark];
  static const List<Color> buttonGradient = [primaryDark, primary];
}
