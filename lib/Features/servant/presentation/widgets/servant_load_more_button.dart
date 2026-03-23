import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class ServantLoadMoreButton extends StatelessWidget {
  const ServantLoadMoreButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more),
        label: Text(isLoading ? 'جاري تحميل المزيد...' : 'تحميل المزيد'),
      ),
    );
  }
}
