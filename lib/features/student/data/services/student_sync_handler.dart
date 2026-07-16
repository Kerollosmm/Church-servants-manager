import 'dart:developer' as developer;

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
      case 'CREATE_STUDENT_INVITATION':
      case 'CREATE_STUDENT_WITH_AUTH':
        final payload = Map<String, dynamic>.from(entry.payload);
        // Old queue entries written before the rename to CREATE_STUDENT_INVITATION
        // may still carry a `password` field under CREATE_STUDENT_WITH_AUTH. We
        // never want to send credentials through to the repo (sign-up happens on
        // the client via FirebaseAuth). Strip silently but log so operators can
        // see how many legacy entries are still draining from the queue.
        if (payload.containsKey('password')) {
          developer.log(
            'Stripping legacy `password` field from sync entry '
            '${entry.id} (actionType=${entry.actionType}). Auth accounts are '
            'provisioned client-side; the password is not used at sync time.',
            name: 'StudentSyncHandler',
          );
          payload.remove('password');
        }
        await _studentRepository.syncOfflineCreateWithAuth(payload);
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
    await _studentRepository.syncBatchedStudents(entries);
  }
}
