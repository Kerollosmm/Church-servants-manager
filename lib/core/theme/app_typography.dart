import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds the shared application type scale.
class AppTypography {
  const AppTypography._();

  /// Applies the Arabic companion family to an existing text style.
  static TextStyle notoSansArabic(TextStyle base) {
    return GoogleFonts.notoSansArabic(
      textStyle: base,
      fontSize: base.fontSize,
      fontWeight: base.fontWeight,
      height: base.height,
      color: base.color,
      letterSpacing: base.letterSpacing,
    );
  }

  /// Builds the bilingual Work Sans type scale for the app theme.
  static TextTheme buildTextTheme([TextTheme? base]) {
    final textTheme = base ?? const TextTheme();

    return textTheme.copyWith(
      displayLarge: GoogleFonts.workSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.onBackground,
      ),
      displayMedium: GoogleFonts.workSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: AppColors.onBackground,
      ),
      displaySmall: GoogleFonts.workSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.onBackground,
      ),
      headlineLarge: GoogleFonts.workSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.onBackground,
      ),
      headlineMedium: GoogleFonts.workSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.onBackground,
      ),
      headlineSmall: GoogleFonts.workSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.onBackground,
      ),
      titleLarge: GoogleFonts.workSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: AppColors.onBackground,
      ),
      titleMedium: GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onBackground,
      ),
      titleSmall: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onBackground,
      ),
      bodyLarge: GoogleFonts.workSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onBackground,
      ),
      bodyMedium: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurface,
      ),
      bodySmall: GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurface,
      ),
      labelLarge: GoogleFonts.workSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onBackground,
      ),
      labelMedium: GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onSurface,
      ),
      labelSmall: GoogleFonts.workSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: AppColors.onSurface,
      ),
    );
  }

  /// Preserves the previous theme API used across the app.
  static TextTheme getMainTextTheme(TextTheme base) => buildTextTheme(base);
}
