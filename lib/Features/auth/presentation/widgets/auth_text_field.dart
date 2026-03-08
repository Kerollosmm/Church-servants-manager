import 'package:church_management_system/core/widgets/form/app_text_form_field.dart';
import 'package:flutter/material.dart';

/// Reusable styled text field for auth forms
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextFormField(
      controller: controller,
      labelText: label,
      prefixIcon: prefixIcon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      suffixIcon: suffixIcon,
    );
  }
}
