import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextTheme getMainTextTheme(TextTheme base) {
    // Ochre Sanctuary uses a bilingual typographic rhythm that balances the geometric clarity of Work Sans
    // with the elegant, traditional calligraphic roots of Noto Sans Arabic.
    return GoogleFonts.notoSansArabicTextTheme(base).copyWith(
      displayLarge: GoogleFonts.workSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.workSans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineLarge: GoogleFonts.notoSansArabic(
        // Display / Headline 1: 1.5rem (24px). Bold and grounded. Used for page titles.
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.notoSansArabic(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.notoSansArabic(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.notoSansArabic(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.notoSansArabic(
        // Body / Content: 0.875rem (14px). Optimized for legibility in dense administrative forms.
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: GoogleFonts.notoSansArabic(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      labelMedium: GoogleFonts.notoSansArabic(
        // Labels / Small: 0.75rem (12px). Used for metadata and helper text.
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: GoogleFonts.notoSansArabic(
        fontSize: 11,
        color: AppColors.textTertiary,
      ),
    );
  }
}
