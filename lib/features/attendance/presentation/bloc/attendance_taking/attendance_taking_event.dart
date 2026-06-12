import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:equatable/equatable.dart';

sealed class AttendanceTakingEvent extends Equatable {
  const AttendanceTakingEvent();

  @override
  List<Object?> get props => [];
}

final class InitializeSessionEvent extends AttendanceTakingEvent {
  const InitializeSessionEvent({
    required this.teamId,
    required this.sessionId,
    this.actor,
  });

  final String teamId;
  final String sessionId;
  final AuthUser? actor;

  @override
  List<Object?> get props => [teamId, sessionId, actor];
}

final class RefreshSessionEvent extends AttendanceTakingEvent {
  const RefreshSessionEvent({required this.teamId, required this.sessionId});

  final String teamId;
  final String sessionId;

  @override
  List<Object?> get props => [teamId, sessionId];
}

final class MarkStudentPresentEvent extends AttendanceTakingEvent {
  const MarkStudentPresentEvent({required this.actor, required this.item});

  final AuthUser actor;
  final AttendanceRosterItem item;

  @override
  List<Object?> get props => [actor, item];
}

final class MarkStudentAbsentEvent extends AttendanceTakingEvent {
  const MarkStudentAbsentEvent({required this.actor, required this.item});

  final AuthUser actor;
  final AttendanceRosterItem item;

  @override
  List<Object?> get props => [actor, item];
}

final class MarkStudentLateEvent extends AttendanceTakingEvent {
  const MarkStudentLateEvent({required this.actor, required this.item});

  final AuthUser actor;
  final AttendanceRosterItem item;

  @override
  List<Object?> get props => [actor, item];
}

final class ClearStudentMarkEvent extends AttendanceTakingEvent {
  const ClearStudentMarkEvent({required this.actor, required this.item});

  final AuthUser actor;
  final AttendanceRosterItem item;

  @override
  List<Object?> get props => [actor, item];
}

final class SubmitSessionEvent extends AttendanceTakingEvent {
  const SubmitSessionEvent({required this.actor});

  final AuthUser actor;

  @override
  List<Object?> get props => [actor];
}

final class MarkAllRemainingPresentEvent extends AttendanceTakingEvent {
  const MarkAllRemainingPresentEvent({required this.actor});

  final AuthUser actor;

  @override
  List<Object?> get props => [actor];
}

final class ResetMutationStatusEvent extends AttendanceTakingEvent {
  const ResetMutationStatusEvent();
}

final class SessionTickEvent extends AttendanceTakingEvent {
  const SessionTickEvent({required this.isSessionOpen});

  final bool isSessionOpen;

  @override
  List<Object?> get props => [isSessionOpen];
}
