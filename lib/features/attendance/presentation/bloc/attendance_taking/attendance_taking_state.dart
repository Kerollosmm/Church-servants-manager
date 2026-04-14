import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:equatable/equatable.dart';

/// Current mutation status for UI feedback.
enum MutationStatus { idle, inProgress, success, failure }

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

final class AttendanceTakingLoaded extends AttendanceTakingState {
  const AttendanceTakingLoaded({
    required this.session,
    required this.roster,
    this.marksMap = const {},
    this.mutationStatus = MutationStatus.idle,
    this.feedbackMessage,
    this.isSessionOpen = true,
    this.errorMessage,
  });

  final AttendanceSession session;
  final List<AttendanceRosterItem> roster;

  /// Maps studentId → AttendanceMarkStatus for quick lookup.
  final Map<String, AttendanceMarkStatus> marksMap;

  /// Current mutation state for UI feedback.
  final MutationStatus mutationStatus;

  /// Optional success/feedback message.
  final String? feedbackMessage;

  /// Whether the session is currently open for marking.
  /// Disables all mark buttons when false.
  final bool isSessionOpen;

  /// Optional error message from failed mutations.
  final String? errorMessage;

  AttendanceTakingLoaded copyWith({
    AttendanceSession? session,
    List<AttendanceRosterItem>? roster,
    Map<String, AttendanceMarkStatus>? marksMap,
    MutationStatus? mutationStatus,
    String? feedbackMessage,
    bool? isSessionOpen,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AttendanceTakingLoaded(
      session: session ?? this.session,
      roster: roster ?? this.roster,
      marksMap: marksMap ?? this.marksMap,
      mutationStatus: mutationStatus ?? this.mutationStatus,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      isSessionOpen: isSessionOpen ?? this.isSessionOpen,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    session,
    roster,
    marksMap,
    mutationStatus,
    feedbackMessage,
    isSessionOpen,
    errorMessage,
  ];
}

final class AttendanceTakingError extends AttendanceTakingState {
  const AttendanceTakingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
