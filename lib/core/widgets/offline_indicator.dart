import 'package:church_management_system/core/presentation/bloc/connectivity/connectivity_cubit.dart';
import 'package:church_management_system/core/presentation/bloc/connectivity/connectivity_state.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// FIX [008]: Global offline indicator banner, integrated in ChurchApp builder. (T013)

/// Wraps [child] and slides in an offline banner at the top of the screen
/// whenever [ConnectivityCubit] emits an offline state.
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<ConnectivityCubit, ConnectivityState>(
          buildWhen: (prev, curr) => prev.isOffline != curr.isOffline,
          builder: (context, state) {
            return AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              offset: state.isOffline ? Offset.zero : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: state.isOffline ? 1.0 : 0.0,
                child: state.isOffline
                    ? Container(
                        width: double.infinity,
                        color: AppColors.errorContainer,
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_outlined,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You are offline. Showing cached data.',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),
        Expanded(child: child),
      ],
    );
  }
}
