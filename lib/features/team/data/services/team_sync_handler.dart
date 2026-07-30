import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';

/// Handles synchronization of team-related mutations.
class TeamSyncHandler implements SyncHandler {
  final ITeamRepository _teamRepository;

  TeamSyncHandler(this._teamRepository);

  @override
  Future<void> execute(SyncEntry entry) async {
    switch (entry.actionType) {
      case 'CREATE_TEAM':
        await _teamRepository.syncOfflineCreate(entry.payload);
        break;
      case 'UPDATE_TEAM':
        await _teamRepository.syncOfflineUpdate(entry.payload);
        break;
      case 'DELETE_TEAM':
        await _teamRepository.syncOfflineDelete(entry.payload);
        break;
      case 'RESTORE_TEAM':
        await _teamRepository.syncOfflineRestore(entry.payload);
        break;
      default:
        throw UnimplementedError(
          'Action type ${entry.actionType} not supported by TeamSyncHandler',
        );
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    await Future.wait(entries.map(execute));
  }
}
