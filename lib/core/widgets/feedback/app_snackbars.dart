import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppSnackbars {
  const AppSnackbars._();

  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarBehavior? behavior,
  }) {
    _show(
      context,
      message,
      backgroundColor: Theme.of(context).colorScheme.error,
      duration: duration,
      behavior: behavior,
    );
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarBehavior? behavior,
    Color? backgroundColor,
  }) {
    _show(
      context,
      message,
      backgroundColor: backgroundColor ?? AppColors.success,
      duration: duration,
      behavior: behavior,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarBehavior? behavior,
    Color? backgroundColor,
  }) {
    _show(
      context,
      message,
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: behavior,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
    SnackBarBehavior? behavior,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration ?? const Duration(seconds: 4),
          behavior: behavior ?? SnackBarBehavior.floating,
        ),
      );
  }
}
