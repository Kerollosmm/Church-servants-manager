import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: AppRadius.mdRadius),
      ),
      validator: validator,
    );
  }
}
