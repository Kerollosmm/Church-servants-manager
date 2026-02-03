import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
      surface: Colors.white,
    ).copyWith(
      primary: const Color(0xFF0F766E),
      onPrimary: Colors.white,
      secondary: const Color(0xFF14B8A6),
      onSecondary: Colors.white,
      tertiary: const Color(0xFF334155),
      onTertiary: Colors.white,
      error: const Color(0xFFB42318),
      onError: Colors.white,
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      outline: const Color(0xFF94A3B8),
    );

    final base = ThemeData(useMaterial3: true, colorScheme: colorScheme);
    final bodyTextTheme = GoogleFonts.sourceSans3TextTheme(base.textTheme);
    final headingTextTheme = GoogleFonts.merriweatherTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      textTheme: bodyTextTheme.copyWith(
        displayLarge: headingTextTheme.displayLarge,
        displayMedium: headingTextTheme.displayMedium,
        displaySmall: headingTextTheme.displaySmall,
        headlineLarge: headingTextTheme.headlineLarge,
        headlineMedium: headingTextTheme.headlineMedium,
        headlineSmall: headingTextTheme.headlineSmall,
        titleLarge: headingTextTheme.titleLarge,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: headingTextTheme.titleLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: bodyTextTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.onSurface,
        contentTextStyle: bodyTextTheme.bodyMedium?.copyWith(
          color: colorScheme.surface,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.surfaceContainerHighest,
        thickness: 1,
      ),
    );
  }
}
