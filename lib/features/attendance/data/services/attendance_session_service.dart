import 'package:church_management_system/features/attendance/data/services/attendance_command_service.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';

/// Orchestrates attendance session lifecycle operations that span
/// session creation with roster snapshots and session state management.
class AttendanceSessionService {
  AttendanceSessionService({required AttendanceCommandService commandService})
    : _commandService = commandService;

  final AttendanceCommandService _commandService;

  /// Creates a session with a frozen roster snapshot of active students.
  /// Validates: team is active, no overlapping sessions, roster is non-empty.
  Future<AttendanceSession> createSessionWithRosterSnapshot({
    required String teamId,
    required String teamNameSnapshot,
    required DateTime startsAt,
    required int durationMinutes,
    required AuthUser createdBy,
    String? title,
  }) async {
    return _commandService.createSession(
      teamId: teamId,
      teamNameSnapshot: teamNameSnapshot,
      startsAt: startsAt,
      durationMinutes: durationMinutes,
      createdBy: createdBy,
      title: title,
    );
  }

  /// Closes a session. Admin only.
  Future<void> closeSession({
    required String teamId,
    required String sessionId,
    required AuthUser closedBy,
  }) async {
    await _commandService.closeSession(
      teamId: teamId,
      sessionId: sessionId,
      closedBy: closedBy,
    );
  }
}
