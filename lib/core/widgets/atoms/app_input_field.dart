import 'package:flutter/material.dart';

/// Wraps [TextFormField] with the shared filled Ochre style.
class AppInputField extends StatelessWidget {
  /// Creates an [AppInputField].
  const AppInputField({
    super.key,
    required this.label,
    this.hint,
    this.leadingIcon,
    this.suffixIcon,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.textInputAction,
  });

  /// Input label shown by the form field.
  final String label;

  /// Optional hint shown inside the field.
  final String? hint;

  /// Leading icon shown in the decorated field.
  final IconData? leadingIcon;

  /// Optional trailing widget shown in the decorated field.
  final Widget? suffixIcon;

  /// Controller bound to the field.
  final TextEditingController? controller;

  /// Validator used by an ancestor [Form].
  final String? Function(String?)? validator;

  /// Keyboard type for the input.
  final TextInputType? keyboardType;

  /// Whether the input should obscure its value.
  final bool obscureText;

  /// Optional change callback.
  final ValueChanged<String>? onChanged;

  /// Preferred input action for the keyboard.
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: leadingIcon == null ? null : Icon(leadingIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
