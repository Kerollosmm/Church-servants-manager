import 'package:flutter/material.dart';

/// Defines shared spacing and sizing tokens.
class AppSpacing {
  const AppSpacing._();

  /// The smallest spacing step for tight layouts.
  static const double spacingXS = 4.0;

  /// Small spacing used between closely related elements.
  static const double spacingS = 8.0;

  /// Medium spacing used in most controls and rows.
  static const double spacingM = 16.0;

  /// Large spacing used between sections.
  static const double spacingL = 24.0;

  /// Extra-large spacing used for page gutters.
  static const double spacingXL = 32.0;

  /// The default page padding token.
  static const double paddingPage = 32.0;

  /// Corner radius used by cards.
  static const double radiusCard = 12.0;

  /// Corner radius used by inputs.
  static const double radiusInput = 8.0;

  /// Standard icon size for the design system.
  static const double iconSize = 20.0;

  /// Legacy alias for extra-small spacing.
  static const double xs = spacingXS;

  /// Legacy alias for small spacing.
  static const double sm = spacingS;

  /// Legacy alias for medium spacing.
  static const double md = spacingM;

  /// Legacy alias for large spacing.
  static const double lg = spacingL;

  /// Legacy alias for extra-large spacing.
  static const double xl = spacingXL;

  /// Larger spacing token retained for existing layouts.
  static const double xxl = 48.0;

  /// Default horizontal screen padding in legacy screens.
  static const double screenHorizontal = md;

  /// Default vertical screen padding in legacy screens.
  static const double screenVertical = md;

  /// Default margin for legacy cards.
  static const double cardMargin = sm;

  /// Default gap between list rows.
  static const double listGap = md;

  /// Default gap between page sections.
  static const double sectionGap = lg;

  /// Helper gap widget for extra-small spacing.
  static const SizedBox gapXs = SizedBox(height: xs, width: xs);

  /// Helper gap widget for small spacing.
  static const SizedBox gapSm = SizedBox(height: sm, width: sm);

  /// Helper gap widget for medium spacing.
  static const SizedBox gapMd = SizedBox(height: md, width: md);

  /// Helper gap widget for large spacing.
  static const SizedBox gapLg = SizedBox(height: lg, width: lg);

  /// Helper gap widget for extra-large spacing.
  static const SizedBox gapXl = SizedBox(height: xl, width: xl);
}

/// Exposes legacy radius aliases used by existing widgets.
class AppRadius {
  const AppRadius._();

  static const double sm = AppSpacing.radiusInput;
  static const double md = AppSpacing.radiusCard;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}
