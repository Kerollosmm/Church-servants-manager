import 'package:flutter/material.dart';

/// Renders a lightweight ochre text action.
class AppTextButton extends StatelessWidget {
  /// Creates an [AppTextButton].
  const AppTextButton({super.key, required this.label, this.onPressed});

  /// Visible button label.
  final String label;

  /// Callback invoked on press.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
