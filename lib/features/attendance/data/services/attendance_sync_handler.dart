import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_handler.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';

/// Handles synchronization of attendance mark mutations.
class AttendanceSyncHandler implements SyncHandler {
  final IAttendanceRepository _attendanceRepository;
  AttendanceSyncHandler(this._attendanceRepository);
  @override
  Future<void> execute(SyncEntry entry) async {
    if (entry.actionType == 'MARK_ATTENDANCE') {
      await _attendanceRepository.syncOfflineMark(entry.payload);
    } else if (entry.actionType == 'CLEAR_ATTENDANCE') {
      await _attendanceRepository.syncOfflineClear(entry.payload);
    } else {
      throw UnimplementedError(
        'Action type ${entry.actionType} not supported by AttendanceSyncHandler',
      );
    }
  }

  @override
  Future<void> executeBatch(List<SyncEntry> entries) async {
    if (entries.isEmpty) return;

    // Filter mark attendance entries for batch processing
    final markEntries = entries
        .where((e) => e.actionType == 'MARK_ATTENDANCE')
        .toList();
    final nonMarkEntries = entries
        .where((e) => e.actionType != 'MARK_ATTENDANCE')
        .toList();

    // Group mark entries by teamId and sessionId to execute batches together
    final groups = <String, List<SyncEntry>>{};
    for (final entry in markEntries) {
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

    // Process non-mark entries individually
    for (final entry in nonMarkEntries) {
      await execute(entry);
    }
  }
}
