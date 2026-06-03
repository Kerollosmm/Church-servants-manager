import 'package:church_management_system/core/blocs/sync/sync_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        if (state is Syncing) {
          return Container(
            color: Colors.blueAccent,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'جاري المزامنة (${state.pendingCount}/${state.totalCount})...',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          );
        } else if (state is SyncFailure) {
          return Container(
            color: Colors.orangeAccent,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sync_problem, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.errorMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        } else if (state is SyncSuccess) {
          return Container(
            color: Colors.green,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'تمت المزامنة بنجاح',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
