import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object?> get props => [];
}

class StartSession extends AttendanceEvent {
  final String teamId;
  final String teamNameSnapshot;
  final DateTime startsAt;
  final int durationMinutes;
  final AuthUser createdBy;
  final List<String> studentIdsSnapshot;
  final Map<String, String> studentNameSnapshots;
  final String? title;

  const StartSession({
    required this.teamId,
    required this.teamNameSnapshot,
    required this.startsAt,
    required this.durationMinutes,
    required this.createdBy,
    required this.studentIdsSnapshot,
    required this.studentNameSnapshots,
    this.title,
  });

  @override
  List<Object?> get props => [
    teamId,
    teamNameSnapshot,
    startsAt,
    durationMinutes,
    createdBy,
    studentIdsSnapshot,
    studentNameSnapshots,
    title,
  ];
}

class ToggleAttendance extends AttendanceEvent {
  final String studentId;
  final AttendanceMarkStatus newStatus;
  final AuthUser markedBy;

  const ToggleAttendance({
    required this.studentId,
    required this.newStatus,
    required this.markedBy,
  });

  @override
  List<Object?> get props => [studentId, newStatus, markedBy];
}

class LoadSessionRoster extends AttendanceEvent {
  final String teamId;
  final String sessionId;

  const LoadSessionRoster({required this.teamId, required this.sessionId});

  @override
  List<Object?> get props => [teamId, sessionId];
}
