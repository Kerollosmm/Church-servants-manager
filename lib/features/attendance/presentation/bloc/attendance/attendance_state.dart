import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';
import 'package:equatable/equatable.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceSessionActive extends AttendanceState {
  final AttendanceSession session;
  final List<AttendanceRosterItem> roster;

  const AttendanceSessionActive({required this.session, required this.roster});

  @override
  List<Object?> get props => [session, roster];

  AttendanceSessionActive copyWith({
    AttendanceSession? session,
    List<AttendanceRosterItem>? roster,
  }) {
    return AttendanceSessionActive(
      session: session ?? this.session,
      roster: roster ?? this.roster,
    );
  }
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object?> get props => [message];
}
