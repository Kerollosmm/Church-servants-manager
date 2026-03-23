import 'package:church_management_system/core/widgets/search/live_search_panel.dart';
import 'package:flutter/material.dart';

class ServantSearchBar extends StatelessWidget {
  const ServantSearchBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LiveSearchPanel(
      controller: controller,
      label: 'البحث عن خادم',
      hint: 'الاسم',
      clearTooltip: 'مسح',
      liveLabel: 'متصل بـ Firestore',
      isLoading: isLoading,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onClear: onClear,
    );
  }
}
