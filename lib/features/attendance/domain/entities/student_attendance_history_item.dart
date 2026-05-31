import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';

class StudentAttendanceHistoryItem {
  const StudentAttendanceHistoryItem({
    required this.sessionId,
    required this.teamId,
    required this.teamNameSnapshot,
    required this.title,
    required this.dateKey,
    required this.sessionStartsAt,
    required this.sessionEndsAt,
    required this.effectiveStatus,
    required this.isSessionClosed,
    this.markedAt,
    this.markedByName,
  });

  final String sessionId;
  final String teamId;
  final String? teamNameSnapshot;
  final String? title;
  final String dateKey;
  final DateTime sessionStartsAt;
  final DateTime sessionEndsAt;
  final AttendanceEffectiveStatus effectiveStatus;
  final bool isSessionClosed;
  final DateTime? markedAt;
  final String? markedByName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAttendanceHistoryItem &&
          runtimeType == other.runtimeType &&
          sessionId == other.sessionId &&
          teamId == other.teamId &&
          effectiveStatus == other.effectiveStatus &&
          isSessionClosed == other.isSessionClosed;

  @override
  int get hashCode =>
      sessionId.hashCode ^
      teamId.hashCode ^
      effectiveStatus.hashCode ^
      isSessionClosed.hashCode;
}
