import 'package:flutter/material.dart';

/// A styled text form field that uses the app's theme tokens.
///
/// Supports labels, icons, password visibility toggling,
/// and custom validation. Inherits border/color styles
/// from the app's [InputDecorationTheme].
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.prefixIcon,
    this.errorText,
    this.obscureText = false,
    this.suffixIcon,
    this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  final String label;
  final IconData? prefixIcon;
  final String? errorText;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      validator:
          validator ??
          (value) {
            if (errorText != null &&
                errorText!.isNotEmpty &&
                (value == null || value.isEmpty)) {
              return errorText;
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
