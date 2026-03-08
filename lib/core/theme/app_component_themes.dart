import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppComponentThemes {
  const AppComponentThemes._();

  static AppBarTheme appBar(TextTheme textTheme) {
    return AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        color: AppColors.white,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: AppColors.white),
    );
  }

  static CardThemeData card() {
    return CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgRadius,
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
    );
  }

  static InputDecorationTheme inputDecoration(TextTheme textTheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 18,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.textSecondary,
      ),
      floatingLabelStyle: textTheme.bodySmall?.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
      border: _inputBorder(AppColors.outline),
      enabledBorder: _inputBorder(AppColors.outline),
      focusedBorder: _inputBorder(AppColors.primary, width: 2),
      errorBorder: _inputBorder(AppColors.error),
      focusedErrorBorder: _inputBorder(AppColors.error, width: 2),
    );
  }

  static FilledButtonThemeData filledButton(TextTheme textTheme) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        elevation: 0,
      ),
    );
  }

  static ElevatedButtonThemeData elevatedButton(TextTheme textTheme) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        surfaceTintColor: AppColors.primary,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        elevation: 2,
      ),
    );
  }

  static OutlinedButtonThemeData outlinedButton(TextTheme textTheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(64, 56),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  static TextButtonThemeData textButton(TextTheme textTheme) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static SnackBarThemeData snackBar(TextTheme textTheme) {
    return SnackBarThemeData(
      backgroundColor: AppColors.tertiary,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdRadius),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.all(AppSpacing.md),
    );
  }

  static const ListTileThemeData listTile = ListTileThemeData(
    iconColor: AppColors.primary,
    textColor: AppColors.textPrimary,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 4,
    ),
    minVerticalPadding: 16,
  );

  static const DividerThemeData divider = DividerThemeData(
    color: AppColors.surfaceContainer,
    thickness: 1,
    space: 24,
  );

  static const IconThemeData icon = IconThemeData(
    size: 24,
    color: AppColors.textPrimary,
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.lgRadius,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
