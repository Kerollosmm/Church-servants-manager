import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';

/// Handles synchronization of attendance session mutations (creation/closing).
class AttendanceSessionSyncHandler implements SyncHandler {
  final AttendanceSessionRepository _sessionRepository;
  AttendanceSessionSyncHandler(this._sessionRepository);
  @override
  Future<void> execute(SyncEntry entry) async {
    switch (entry.actionType) {
      case 'CREATE_SESSION':
        await _sessionRepository.syncOfflineSessionCreation(entry.payload);
        break;
      case 'CLOSE_SESSION':
        await _sessionRepository.syncOfflineCloseSession(entry.payload);
        break;
      default:
        throw UnimplementedError(
          'Action type ${entry.actionType} not supported by AttendanceSessionSyncHandler',
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
