import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/app_state_card.dart';
import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  const AppErrorState({
    super.key,
    required this.message,
    this.title = 'حدث خطأ ما',
    this.onRetry,
    this.retryLabel = 'إعادة المحاولة',
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return AppStateCard(
      icon: icon,
      iconColor: AppColors.error,
      title: title,
      description: message,
      actions: [
        if (onRetry != null)
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(retryLabel),
          ),
      ],
    );
  }
}
