import 'package:flutter/material.dart';

/// Defines the shared Ochre Sanctuary color tokens.
class AppColors {
  const AppColors._();

  /// Brand ochre used for primary actions and icons.
  static const Color primary = Color(0xFFA58255);

  /// Main application canvas color.
  static const Color background = Color(0xFFF7F7F6);

  /// Elevated surface color used by cards and sheets.
  static const Color surface = Color(0xFFFFFFFF);

  /// Soft recessed fill used for inputs and subtle containers.
  static const Color surfaceContainerLow = Color(0xFFF7F7F6);

  /// Primary readable text color on light backgrounds.
  static const Color onBackground = Color(0xFF1C1C1E);

  /// Secondary readable text color on surfaces.
  static const Color onSurface = Color(0xFF3D3D3D);

  /// Foreground color placed on top of primary surfaces.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Soft ochre tint used for headers and grouped surfaces.
  static const Color primaryContainer = Color(0x1AA58255);

  /// Low-contrast outline used for inputs and separators.
  static const Color outline = Color(0x33A58255);

  /// Tinted shadow used for buttons and atmospheric depth.
  static const Color shadow = Color(0x4DA58255);

  /// Default error color.
  static const Color error = Color(0xFFB42318);

  /// Error container surface.
  static const Color errorContainer = Color(0xFFFDECEC);

  /// Success accent color.
  static const Color success = Color(0xFF2E7D32);

  /// Warning accent color.
  static const Color warning = Color(0xFFB45309);

  /// White helper alias for legacy code.
  static const Color white = onPrimary;

  /// Warm near-black helper alias for legacy code.
  static const Color black = onBackground;

  /// Transparent helper alias.
  static const Color transparent = Colors.transparent;

  /// Legacy darker primary accent.
  static const Color primaryDark = Color(0xFF8A6B45);

  /// Legacy lighter primary accent.
  static const Color primaryLight = Color(0xFFD1B089);

  /// Legacy secondary accent retained for compatibility.
  static const Color secondary = Color(0xFFD8C19D);

  /// Legacy tertiary accent retained for compatibility.
  static const Color tertiary = Color(0xFF7D6242);

  /// Legacy surface container alias.
  static const Color surfaceContainer = surfaceContainerLow;

  /// Legacy primary text alias.
  static const Color textPrimary = onBackground;

  /// Legacy secondary text alias.
  static const Color textSecondary = onSurface;

  /// Legacy tertiary text alias.
  static const Color textTertiary = Color(0xFF7E7E80);

  /// Legacy inverse text alias.
  static const Color textInverse = onPrimary;

  /// Shared ochre gradient for decorative accents.
  static const List<Color> primaryGradient = <Color>[
    Color(0xFFA58255),
    Color(0x66A58255),
    Color(0x33A58255),
  ];

  /// Stronger ochre gradient for emphasized controls.
  static const List<Color> buttonGradient = <Color>[Color(0xFF8A6B45), primary];
}
