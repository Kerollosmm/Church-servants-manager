import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:equatable/equatable.dart';

class StudentAttendanceHistoryItem extends Equatable {
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
  List<Object?> get props => [
    sessionId,
    teamId,
    teamNameSnapshot,
    title,
    dateKey,
    sessionStartsAt,
    sessionEndsAt,
    effectiveStatus,
    isSessionClosed,
    markedAt,
    markedByName,
  ];
}
