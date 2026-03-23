import 'package:church_management_system/core/theme/ochre_theme_extension.dart';
import 'package:flutter/material.dart';

/// Renders the shared filled primary action button.
class AppPrimaryButton extends StatelessWidget {
  /// Creates an [AppPrimaryButton].
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  /// Visible button label.
  final String label;

  /// Callback invoked when the button is pressed.
  final VoidCallback? onPressed;

  /// Whether the button should show a busy indicator.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isPressed = ValueNotifier<bool>(false);
    final ochreTheme =
        Theme.of(context).extension<OchreTheme>() ?? OchreTheme.light;

    return ValueListenableBuilder<bool>(
      valueListenable: isPressed,
      builder: (context, pressed, child) {
        return GestureDetector(
          onTapDown: onPressed == null || isLoading
              ? null
              : (_) => isPressed.value = true,
          onTapUp: onPressed == null || isLoading
              ? null
              : (_) => isPressed.value = false,
          onTapCancel: onPressed == null || isLoading
              ? null
              : () => isPressed.value = false,
          child: AnimatedScale(
            scale: pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: DecoratedBox(
              decoration: BoxDecoration(boxShadow: ochreTheme.buttonShadow),
              child: child,
            ),
          ),
        );
      },
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey<String>('loader'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label, key: const ValueKey<String>('label')),
        ),
      ),
    );
  }
}
