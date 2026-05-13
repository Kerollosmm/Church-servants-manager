import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:equatable/equatable.dart';

sealed class AttendanceHistoryState extends Equatable {
  const AttendanceHistoryState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AttendanceHistoryInitial extends AttendanceHistoryState {
  const AttendanceHistoryInitial();
}

final class AttendanceHistoryLoading extends AttendanceHistoryState {
  const AttendanceHistoryLoading({this.teamId});

  final String? teamId;

  @override
  List<Object?> get props => [teamId];
}

final class AttendanceHistoryLoaded extends AttendanceHistoryState {
  const AttendanceHistoryLoaded({
    required this.teamId,
    required this.sessions,
    this.activeSession,
    this.isFromCache = false,
  });

  final String teamId;
  final List<AttendanceSession> sessions;
  final AttendanceSession? activeSession;
  final bool isFromCache;

  @override
  List<Object?> get props => [teamId, sessions, activeSession, isFromCache];
}

final class AttendanceHistoryError extends AttendanceHistoryState {
  const AttendanceHistoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
