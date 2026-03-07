import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.buttonLabel,
    required this.value,
    required this.onPressed,
  });

  final String label;
  final String buttonLabel;
  final DateTime? value;
  final VoidCallback onPressed;

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.cake_outlined),
            ),
            child: Text(
              value == null ? '—' : _formatDate(value!),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        AppSpacing.gapSm,
        FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
      ],
    );
  }
}
