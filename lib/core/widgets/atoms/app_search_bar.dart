import 'package:flutter/material.dart';

/// Renders a compact search input styled from the app theme.
class AppSearchBar extends StatelessWidget {
  /// Creates an [AppSearchBar].
  const AppSearchBar({
    super.key,
    this.controller,
    this.hint = 'Search',
    this.onChanged,
  });

  /// Controller bound to the search field.
  final TextEditingController? controller;

  /// Placeholder text shown when the field is empty.
  final String hint;

  /// Callback invoked as the query changes.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: const Icon(Icons.search),
      ),
    );
  }
}
