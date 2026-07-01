import 'package:church_management_system/core/blocs/sync/sync_cubit.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A global, animated banner that displays the current offline sync status.
/// It automatically slides down when syncing, shows success, and then slides up.
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        final bool isDlq = state is SyncDlqWarning;
        final bool isVisible =
            state is Syncing ||
            state is SyncSuccess ||
            state is SyncFailure ||
            isDlq;

        Color backgroundColor = AppColors.primary;
        IconData icon = Icons.cloud_upload_outlined;
        String message = 'جاري مزامنة البيانات...';
        bool showProgress = false;

        if (state is Syncing) {
          backgroundColor = AppColors.primary.withValues(alpha: 0.9);
          icon = Icons.sync;
          message = 'جاري مزامنة البيانات (${state.pendingCount} متبقي)...';
          showProgress = true;
        } else if (state is SyncSuccess) {
          backgroundColor = Colors.green.shade600;
          icon = Icons.cloud_done;
          message = 'تمت مزامنة جميع البيانات بنجاح!';
        } else if (state is SyncFailure) {
          backgroundColor = Colors.red.shade600;
          icon = Icons.cloud_off;
          message = state.errorMessage;
        } else if (state is SyncDlqWarning) {
          backgroundColor = Colors.red.shade800;
          icon = Icons.warning_amber_rounded;
          message = 'بعض البيانات لم تتم مزامنتها. اضغط لإعادة المحاولة';
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: isVisible ? kToolbarHeight : 0,
          color: backgroundColor,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: SizedBox(
              height: kToolbarHeight,
              child: SafeArea(
                bottom: false,
                child: InkWell(
                  onTap: isDlq
                      ? () => context.read<SyncCubit>().retryDlq()
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showProgress) ...[
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                        ] else ...[
                          Icon(icon, color: Colors.white, size: 20),
                        ],
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
