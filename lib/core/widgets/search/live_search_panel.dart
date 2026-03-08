import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class LiveSearchPanel extends StatelessWidget {
  const LiveSearchPanel({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.clearTooltip,
    required this.liveLabel,
    this.bottom,
    this.isLoading = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final String clearTooltip;
  final String liveLabel;
  final Widget? bottom;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_done, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    liveLabel,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (isLoading)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        AppSpacing.gapMd,
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.gapSm,
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            return TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              decoration: InputDecoration(
                hintText: hint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: value.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: clearTooltip,
                        onPressed: onClear,
                      ),
              ),
            );
          },
        ),
        if (bottom != null) ...[AppSpacing.gapSm, bottom!],
      ],
    );
  }
}
