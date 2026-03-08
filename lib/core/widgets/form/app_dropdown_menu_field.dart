import 'package:flutter/material.dart';

class AppDropdownMenuField<T> extends StatelessWidget {
  const AppDropdownMenuField({
    super.key,
    required this.initialSelection,
    required this.label,
    required this.leadingIcon,
    required this.dropdownMenuEntries,
    required this.onSelected,
    this.enabled = true,
  });

  final T? initialSelection;
  final Widget label;
  final IconData leadingIcon;
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;
  final ValueChanged<T?> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<T>(
      initialSelection: initialSelection,
      enabled: enabled,
      dropdownMenuEntries: dropdownMenuEntries,
      onSelected: onSelected,
      label: label,
      leadingIcon: Icon(leadingIcon),
    );
  }
}
