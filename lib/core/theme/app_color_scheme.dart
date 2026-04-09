import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppColorScheme {
  const AppColorScheme._();

  static ColorScheme light() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.secondary,
      onSecondary: AppColors.white,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.textInverse,
      surfaceContainerHighest: AppColors.surfaceContainer,
      outline: AppColors.outline,
    );
  }
}
