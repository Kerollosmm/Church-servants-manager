import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppColorScheme {
  const AppColorScheme._();

  static ColorScheme light() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onPrimary,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onPrimary,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceContainerLow,
      surfaceContainerHighest: AppColors.surfaceContainerLow,
      outline: AppColors.outline,
    );
  }
}
