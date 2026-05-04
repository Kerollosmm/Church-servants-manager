import 'package:church_management_system/core/theme/app_color_scheme.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_component_themes.dart';
import 'package:church_management_system/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = AppColorScheme.light();
    final baseTheme = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    final textTheme = AppTypography.getMainTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppComponentThemes.appBar(textTheme).copyWith(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: AppComponentThemes.card(),
      inputDecorationTheme: AppComponentThemes.inputDecoration(textTheme),
      filledButtonTheme: AppComponentThemes.filledButton(textTheme),
      elevatedButtonTheme: AppComponentThemes.elevatedButton(textTheme),
      outlinedButtonTheme: AppComponentThemes.outlinedButton(textTheme),
      textButtonTheme: AppComponentThemes.textButton(textTheme),
      snackBarTheme: AppComponentThemes.snackBar(textTheme),
      listTileTheme: AppComponentThemes.listTile,
      dividerTheme: AppComponentThemes.divider,
      iconTheme: AppComponentThemes.icon,
    );
  }
}
