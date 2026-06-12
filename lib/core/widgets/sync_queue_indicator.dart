import 'dart:math' as math;

import 'package:church_management_system/core/blocs/sync/sync_cubit.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A dashboard widget placed in the AppBar to display the number of pending
/// offline edits. Tapping it initiates an immediate sync process if connected.
class SyncQueueIndicator extends StatefulWidget {
  const SyncQueueIndicator({super.key});

  @override
  State<SyncQueueIndicator> createState() => _SyncQueueIndicatorState();
}

class _SyncQueueIndicatorState extends State<SyncQueueIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _handleSync(BuildContext context) async {
    final connectivity = getIt<Connectivity>();
    final results = await connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'لا يوجد اتصال بالإنترنت حالياً. سيتم المزامنة تلقائياً عند عودة الاتصال.',
            style: TextStyle(fontFamily: 'Outfit'),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'جاري بدء مزامنة البيانات المعلقة...',
            style: TextStyle(fontFamily: 'Outfit'),
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      await context.read<SyncCubit>().forceSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncService = getIt<SyncService>();

    return BlocConsumer<SyncCubit, SyncState>(
      listener: (context, state) {
        if (state is Syncing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      },
      builder: (context, state) {
        final pendingCount = syncService.pendingCount;
        final isSyncing = state is Syncing;

        if (pendingCount == 0 && !isSyncing) {
          return const SizedBox.shrink();
        }

        final displayText = '$pendingCount تعديلات بانتظار المزامنة';

        return Semantics(
          label: displayText,
          button: true,
          child: Tooltip(
            message: displayText,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationController.value * 2 * math.pi,
                      child: child,
                    );
                  },
                  child: IconButton(
                    icon: Icon(
                      isSyncing ? Icons.sync : Icons.cloud_upload_outlined,
                      color: const Color(0xFF334155),
                      size: 24,
                    ),
                    onPressed: () => _handleSync(context),
                  ),
                ),
                if (pendingCount > 0 && !isSyncing)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.tertiary, // Burgundy
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
