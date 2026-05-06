import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:equatable/equatable.dart';

abstract class AttendanceSessionAdminEvent extends Equatable {
  const AttendanceSessionAdminEvent();

  @override
  List<Object?> get props => [];
}

class CreateSessionEvent extends AttendanceSessionAdminEvent {
  final AuthUser actor;
  final String teamId;
  final String teamNameSnapshot;
  final DateTime startsAt;
  final int durationMinutes;
  final String? title;

  const CreateSessionEvent({
    required this.actor,
    required this.teamId,
    required this.teamNameSnapshot,
    required this.startsAt,
    required this.durationMinutes,
    this.title,
  });

  @override
  List<Object?> get props => [
    actor,
    teamId,
    teamNameSnapshot,
    startsAt,
    durationMinutes,
    title,
  ];
}

class CreateSessionsBulkEvent extends AttendanceSessionAdminEvent {
  final AuthUser actor;
  final Map<String, String> teamIdsAndNames;
  final DateTime startsAt;
  final int durationMinutes;
  final String? title;

  const CreateSessionsBulkEvent({
    required this.actor,
    required this.teamIdsAndNames,
    required this.startsAt,
    required this.durationMinutes,
    this.title,
  });

  @override
  List<Object?> get props => [
    actor,
    teamIdsAndNames,
    startsAt,
    durationMinutes,
    title,
  ];
}

class CloseSessionEvent extends AttendanceSessionAdminEvent {
  final AuthUser actor;
  final String teamId;
  final String sessionId;

  const CloseSessionEvent({
    required this.actor,
    required this.teamId,
    required this.sessionId,
  });

  @override
  List<Object?> get props => [actor, teamId, sessionId];
}
