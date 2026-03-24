import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/timer/attendance_session_timer_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/timer/attendance_session_timer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// FIX [008]: Widget that renders the countdown banner from the timer cubit. (T017)

/// Displays a warning banner when the attendance session is about to expire.
///
/// - Invisible when [AttendanceSessionTimerState.showWarning] is false.
/// - Shows MM:SS countdown with warning colors when ≤ 10 mins remain.
/// - Changes to an error style with "Session Expired" text on expiry.
class SessionExpiryBanner extends StatelessWidget {
  const SessionExpiryBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      AttendanceSessionTimerCubit,
      AttendanceSessionTimerState
    >(
      buildWhen: (prev, curr) =>
          prev.showWarning != curr.showWarning ||
          prev.isExpired != curr.isExpired ||
          prev.formattedRemaining != curr.formattedRemaining,
      builder: (context, state) {
        if (!state.showWarning) return const SizedBox.shrink();

        final isExpired = state.isExpired;
        final bgColor = isExpired
            ? AppColors.errorContainer
            : AppColors.warningContainer;
        final borderColor = isExpired ? AppColors.error : AppColors.warning;
        final textColor = isExpired ? AppColors.error : AppColors.warning;
        final icon = isExpired
            ? Icons.timer_off_outlined
            : Icons.timer_outlined;
        final message = isExpired
            ? 'انتهت الجلسة' // "Session Expired"
            : 'تنتهي الجلسة خلال ${state.formattedRemaining}'; // "Session expires in MM:SS"

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: textColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
