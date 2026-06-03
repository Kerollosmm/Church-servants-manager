import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_session.dart';
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
    this.pendingLocalMarks = const {},
    this.mutationStatus = MutationStatus.idle,
    this.feedbackMessage,
    this.isSessionOpen = true,
    this.errorMessage,
  });

  final AttendanceSession session;
  final List<AttendanceRosterItem> roster;

  /// Maps studentId → AttendanceMarkStatus for quick lookup.
  final Map<String, AttendanceMarkStatus> marksMap;

  /// Maps studentId → AttendanceMarkStatus for instant UI feedback before sync.
  final Map<String, AttendanceMarkStatus> pendingLocalMarks;

  /// Effective marks for UI, merging Firestore marks with local pending marks.
  Map<String, AttendanceMarkStatus> get effectiveMarksMap {
    return {...marksMap, ...pendingLocalMarks};
  }

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
    Map<String, AttendanceMarkStatus>? pendingLocalMarks,
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
      pendingLocalMarks: pendingLocalMarks ?? this.pendingLocalMarks,
      mutationStatus: mutationStatus ?? this.mutationStatus,
      feedbackMessage: feedbackMessage ?? this.feedbackMessage,
      isSessionOpen: isSessionOpen ?? this.isSessionOpen,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }

  AttendanceTakingLoaded withPendingMark(
    String studentId,
    AttendanceMarkStatus status,
  ) {
    return copyWith(
      pendingLocalMarks: {...pendingLocalMarks, studentId: status},
    );
  }

  AttendanceTakingLoaded withoutPendingMark(String studentId) {
    final updated = Map<String, AttendanceMarkStatus>.from(pendingLocalMarks)
      ..remove(studentId);
    return copyWith(pendingLocalMarks: updated);
  }

  @override
  List<Object?> get props => [
    session,
    roster,
    marksMap,
    pendingLocalMarks,
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
