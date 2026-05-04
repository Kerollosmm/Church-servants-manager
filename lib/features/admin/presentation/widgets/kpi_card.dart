import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum TrendType { positive, negative, neutral }

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final TrendType trendType;

  const KpiCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    this.trendType = TrendType.positive,
  });

  @override
  Widget build(BuildContext context) {
    final trendColor = _getTrendColor();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12), // rounded-xl (0.75rem = 12px)
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // subtle shadow-sm
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    trend,
                    style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (trendType != TrendType.neutral) ...[
                    const SizedBox(width: 4),
                    Icon(
                      trendType == TrendType.positive
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: trendColor,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade500, // text-slate-500
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A), // slate-900
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    switch (trendType) {
      case TrendType.positive:
        return Colors.green.shade600;
      case TrendType.negative:
        return Colors.red.shade600;
      case TrendType.neutral:
        return Colors.grey.shade400; // slate-400
    }
  }
}
