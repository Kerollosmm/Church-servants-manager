import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/features/student/domain/repos/i_pastoral_repository.dart';

/// Handles synchronization of pastoral records mutations.
class PastoralSyncHandler implements SyncHandler {
  final IPastoralRepository _pastoralRepository;
  PastoralSyncHandler(this._pastoralRepository);
  @override
  Future<void> execute(SyncEntry entry) async {
    if (entry.actionType == 'CREATE_PASTORAL_RECORD') {
      await _pastoralRepository.syncOfflineCreate(entry.payload);
    } else {
      throw UnimplementedError(
        'Action type ${entry.actionType} not supported by PastoralSyncHandler',
      );
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    for (final entry in entries) {
      await execute(entry);
    }
  }
}
