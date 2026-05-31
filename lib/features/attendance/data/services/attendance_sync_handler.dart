import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';

/// Handles synchronization of attendance mark mutations.
class AttendanceSyncHandler implements SyncHandler {
  final IAttendanceRepository _attendanceRepository;
  AttendanceSyncHandler(this._attendanceRepository);
  @override
  Future<void> execute(SyncEntry entry) async {
    if (entry.actionType == 'MARK_ATTENDANCE') {
      await _attendanceRepository.syncOfflineMark(entry.payload);
    } else if (entry.actionType == 'CLEAR_ATTENDANCE') {
      final teamId = entry.payload['teamId'] as String;
      final sessionId = entry.payload['sessionId'] as String;
      final studentId = entry.payload['studentId'] as String;
      final requestedByUid = entry.payload['requestedByUid'] as String;
      await _attendanceRepository.clearStudentMark(
        teamId: teamId,
        sessionId: sessionId,
        studentId: studentId,
        requestedBy: AuthUser(
          uid: requestedByUid,
          name: 'System',
          email: '',
          role: UserRole.servant,
        ),
      );
    } else {
      throw UnimplementedError(
        'Action type ${entry.actionType} not supported by AttendanceSyncHandler',
      );
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    if (entries.isEmpty) return;
    // Group entries by teamId and sessionId to execute batches together
    final groups = <String, List<SyncEntry>>{};
    for (final entry in entries) {
      final teamId = entry.payload['teamId'] as String? ?? '';
      final sessionId = entry.payload['sessionId'] as String? ?? '';
      final key = '${teamId}_$sessionId';
      groups.putIfAbsent(key, () => []).add(entry);
    }
    for (final group in groups.values) {
      if (group.isEmpty) continue;
      final first = group.first;
      final teamId = first.payload['teamId'] as String;
      final sessionId = first.payload['sessionId'] as String;
      await _attendanceRepository.syncBatchedMarks(
        teamId: teamId,
        sessionId: sessionId,
        payloads: group.map((e) => e.payload).toList(),
      );
    }
  }
}
