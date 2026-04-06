import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static TextTheme getMainTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Merriweather',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'SourceSans3',
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'SourceSans3',
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'SourceSans3',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
