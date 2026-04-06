import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';

/// Orchestrates attendance session lifecycle operations that span
/// session creation with roster snapshots and session state management.
/// This service coordinates between AttendanceSessionRepository and
/// StudentQueryService to ensure data consistency.
class AttendanceSessionService {
  AttendanceSessionService({
    required AttendanceSessionRepository sessionRepository,
    required StudentQueryService studentQueryService,
  }) : _sessionRepository = sessionRepository,
       _studentQueryService = studentQueryService;

  final AttendanceSessionRepository _sessionRepository;
  final StudentQueryService _studentQueryService;

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
    final trimmedTeamId = teamId.trim();
    final rosterStudents = await _studentQueryService.getStudentsByClass(
      trimmedTeamId,
    );

    final activeStudents = rosterStudents
        .where((s) => !s.isArchived)
        .toList(growable: false);

    if (activeStudents.isEmpty) {
      throw const AttendanceValidationFailure(
        'لا يمكن إنشاء جلسة بدون مخدومين نشطين في الفريق.',
      );
    }

    activeStudents.sort((a, b) => a.name.compareTo(b.name));

    final trimmedTitle = title?.trim();
    if (trimmedTitle == null || trimmedTitle.isEmpty) {
      throw const AttendanceValidationFailure('عنوان الجلسة مطلوب.');
    }

    return _sessionRepository.createSession(
      teamId: trimmedTeamId,
      teamNameSnapshot: teamNameSnapshot,
      startsAt: startsAt,
      durationMinutes: durationMinutes,
      createdBy: createdBy,
      title: trimmedTitle,
      studentIdsSnapshot: activeStudents
          .map((s) => s.docID)
          .toList(growable: false),
      studentNameSnapshots: {for (final s in activeStudents) s.docID: s.name},
    );
  }

  /// Closes a session. Admin only.
  Future<void> closeSession({
    required String teamId,
    required String sessionId,
  }) async {
    await _sessionRepository.closeSession(teamId: teamId, sessionId: sessionId);
  }

  /// Reopens a closed session for admin editing.
  /// Records who reopened and when.
  Future<void> reopenSession({
    required String teamId,
    required String sessionId,
    required String reopenedByUserId,
    required String reopenedByName,
  }) async {
    await _sessionRepository.reopenSession(
      teamId: teamId,
      sessionId: sessionId,
      reopenedByUserId: reopenedByUserId,
      reopenedByName: reopenedByName,
    );
  }
}
