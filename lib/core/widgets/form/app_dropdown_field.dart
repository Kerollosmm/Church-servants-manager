import 'package:flutter/material.dart';

class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    this.fieldKey,
    required this.initialValue,
    required this.labelText,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
    this.validator,
    this.isExpanded = false,
  });

  final Key? fieldKey;
  final T? initialValue;
  final String labelText;
  final IconData prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? Function(T?)? validator;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: fieldKey,
      value: initialValue,
      isExpanded: isExpanded,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
