import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';

/// Handles synchronization of student-related mutations.
class StudentSyncHandler implements SyncHandler {
  final IStudentRepository _studentRepository;
  StudentSyncHandler(this._studentRepository);
  @override
  Future<void> execute(SyncEntry entry) async {
    switch (entry.actionType) {
      case 'UPSERT_STUDENT':
        await _studentRepository.syncOfflineUpsert(entry.payload);
        break;
      case 'UPDATE_STUDENT':
        await _studentRepository.syncOfflineUpdate(entry.payload);
        break;
      case 'ARCHIVE_STUDENT':
        await _studentRepository.syncOfflineArchive(entry.payload);
        break;
      case 'RESTORE_STUDENT':
        await _studentRepository.syncOfflineRestore(entry.payload);
        break;
      default:
        throw UnimplementedError(
          'Action type ${entry.actionType} not supported by StudentSyncHandler',
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
