import 'dart:async';

import 'package:church_management_system/core/blocs/sync/sync_state.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'sync_state.dart';

/// Cubit responsible for bridging the background [SyncService] to the UI.
class SyncCubit extends Cubit<SyncState> {
  final SyncService _syncService;
  StreamSubscription<SyncStatus>? _syncSubscription;
  Timer? _resetTimer;

  SyncCubit({required SyncService syncService})
    : _syncService = syncService,
      super(const SyncIdle()) {
    _monitorSync();
  }

  void _monitorSync() {
    _syncSubscription = _syncService.statusStream.listen((status) {
      if (status.isSyncing) {
        emit(
          Syncing(
            pendingCount: status.pendingCount,
            totalCount: status.totalCount,
          ),
        );
      } else if (status.hasError) {
        emit(
          SyncFailure(
            errorMessage: status.errorMessage ?? 'حدث خطأ في المزامنة.',
          ),
        );
      } else {
        // Must be success or idle
        // If it was syncing and now it's not and no error, it's a success
        if (state is Syncing) {
          emit(const SyncSuccess());
          // Optionally reset to idle after a few seconds so the success banner hides
          _resetTimer?.cancel();
          _resetTimer = Timer(const Duration(seconds: 3), () {
            if (!isClosed) emit(const SyncIdle());
          });
        } else {
          emit(const SyncIdle());
        }
      }
    });
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    _resetTimer?.cancel();
    return super.close();
  }
}
