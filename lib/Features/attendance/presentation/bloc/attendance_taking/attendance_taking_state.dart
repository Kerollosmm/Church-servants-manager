import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:equatable/equatable.dart';

sealed class AttendanceTakingState extends Equatable {
  const AttendanceTakingState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class AttendanceTakingInitial extends AttendanceTakingState {
  const AttendanceTakingInitial();
}

final class AttendanceTakingLoading extends AttendanceTakingState {
  const AttendanceTakingLoading();
}

class AttendanceTakingLoaded extends AttendanceTakingState {
  const AttendanceTakingLoaded({
    required this.session,
    required this.roster,
    this.isMutating = false,
    this.mutationError,
  });

  final AttendanceSession session;
  final List<AttendanceRosterItem> roster;
  final bool isMutating;
  final String? mutationError;

  AttendanceTakingLoaded copyWith({
    AttendanceSession? session,
    List<AttendanceRosterItem>? roster,
    bool? isMutating,
    String? mutationError,
    bool clearMutationError = false,
  }) {
    return AttendanceTakingLoaded(
      session: session ?? this.session,
      roster: roster ?? this.roster,
      isMutating: isMutating ?? this.isMutating,
      mutationError: clearMutationError
          ? null
          : (mutationError ?? this.mutationError),
    );
  }

  @override
  List<Object?> get props => [session, roster, isMutating, mutationError];
}

final class AttendanceTakingMarkInProgress extends AttendanceTakingLoaded {
  const AttendanceTakingMarkInProgress({
    required this.studentId,
    required super.session,
    required super.roster,
    super.mutationError,
  }) : super(isMutating: true);

  final String studentId;

  @override
  List<Object?> get props => [...super.props, studentId];
}

final class AttendanceTakingError extends AttendanceTakingState {
  const AttendanceTakingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
