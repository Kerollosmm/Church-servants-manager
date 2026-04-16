import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/features/attendance/data/models/attendance_enums.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit for managing attendance-taking UI state during a session.
///
/// Listens to a single session-level marks stream and a session status stream.
/// Delegates mutations to [AttendanceRepository] with idempotency guards.
class AttendanceTakingCubit extends Cubit<AttendanceTakingState> {
  AttendanceTakingCubit({
    required AttendanceRepository repository,
    DateTime Function()? nowProvider,
  }) : _repository = repository,
       _nowProvider = nowProvider ?? DateTime.now,
       super(const AttendanceTakingInitial());

  final AttendanceRepository _repository;
  final DateTime Function() _nowProvider;

  StreamSubscription<AttendanceRosterSnapshot>? _rosterSubscription;
  StreamSubscription<SessionStatus>? _statusSubscription;
  bool _isMutating = false;
  String? _mutationError;

  /// Number of students without any mark in the current roster.
  int get unmarkedCount {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) return 0;
    return currentState.roster
        .where((s) => !currentState.marksMap.containsKey(s.studentId))
        .length;
  }

  void initialize({required String teamId, required String sessionId}) {
    _isMutating = false;
    _mutationError = null;
    emit(const AttendanceTakingLoading());

    _rosterSubscription?.cancel();
    _statusSubscription?.cancel();

    // Listen to session status stream for real-time open/closed state.
    _statusSubscription = _repository
        .watchSessionStatus(teamId: teamId, sessionId: sessionId)
        .listen(_onSessionStatusChange);

    // Single session-level stream replaces all per-student listeners.
    _rosterSubscription = _repository
        .watchSessionRosterSnapshot(teamId: teamId, sessionId: sessionId)
        .listen(
          _onSnapshot,
          onError: (Object error, StackTrace stackTrace) {
            developer.log(
              'roster stream failed',
              error: error,
              stackTrace: stackTrace,
              name: 'AttendanceTakingCubit',
            );
            final failure = mapExceptionToAttendanceFailure(error);
            emit(AttendanceTakingError(failure.message));
          },
        );
  }

  void _onSessionStatusChange(SessionStatus status) {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) return;

    final isSessionOpen = status != SessionStatus.closed;
    if (currentState.isSessionOpen != isSessionOpen) {
      emit(currentState.copyWith(isSessionOpen: isSessionOpen));
    }
  }

  void _onSnapshot(AttendanceRosterSnapshot snapshot) {
    final marksMap = <String, AttendanceMarkStatus>{};
    for (final item in snapshot.roster) {
      if (item.manualStatus != null) {
        marksMap[item.studentId] = item.manualStatus!;
      }
    }

    emit(
      AttendanceTakingLoaded(
        session: snapshot.session,
        roster: snapshot.roster,
        marksMap: marksMap,
        mutationStatus: _isMutating
            ? MutationStatus.inProgress
            : MutationStatus.idle,
        isSessionOpen: snapshot.session.isOpenAt(_nowProvider()),
        errorMessage: _mutationError,
      ),
    );
  }

  Future<void> markPresent({
    required AuthUser actor,
    required AttendanceRosterItem item,
  }) {
    // Idempotency guard: skip if already marked present.
    final currentState = state;
    if (currentState is AttendanceTakingLoaded) {
      final existingStatus = currentState.marksMap[item.studentId];
      if (existingStatus == AttendanceMarkStatus.present) {
        return Future<void>.value();
      }
    }

    return _runMutation(
      action: () => _repository.markStudentPresent(
        teamId: item.teamId,
        sessionId: item.sessionId,
        studentId: item.studentId,
        studentNameSnapshot: item.studentName,
        markedBy: actor,
      ),
    );
  }

  Future<void> markLate({
    required AuthUser actor,
    required AttendanceRosterItem item,
  }) {
    // Idempotency guard: skip if already marked late.
    final currentState = state;
    if (currentState is AttendanceTakingLoaded) {
      final existingStatus = currentState.marksMap[item.studentId];
      if (existingStatus == AttendanceMarkStatus.late) {
        return Future<void>.value();
      }
    }

    return _runMutation(
      action: () => _repository.markStudentLate(
        teamId: item.teamId,
        sessionId: item.sessionId,
        studentId: item.studentId,
        studentNameSnapshot: item.studentName,
        markedBy: actor,
      ),
    );
  }

  Future<void> clearMark({
    required AuthUser actor,
    required AttendanceRosterItem item,
  }) {
    // Idempotency guard: skip if not marked.
    final currentState = state;
    if (currentState is AttendanceTakingLoaded) {
      if (!currentState.marksMap.containsKey(item.studentId)) {
        return Future<void>.value();
      }
    }

    return _runMutation(
      action: () => _repository.clearStudentMark(
        teamId: item.teamId,
        sessionId: item.sessionId,
        studentId: item.studentId,
        requestedBy: actor,
      ),
    );
  }

  Future<void> markAllRemainingPresent({required AuthUser actor}) async {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) {
      return;
    }

    await _runMutation(
      action: () => _repository.markAllPresentForRemainingStudents(
        teamId: currentState.session.teamId,
        sessionId: currentState.session.id,
        markedBy: actor,
      ),
    );
  }

  Future<void> _runMutation({required Future<void> Function() action}) async {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) return;
    if (_isMutating) return;
    if (!currentState.isSessionOpen) {
      _mutationError = 'انتهى وقت تسجيل الحضور لهذه الجلسة.';
      emit(currentState.copyWith(errorMessage: _mutationError));
      return;
    }

    _isMutating = true;
    _mutationError = null;
    emit(
      currentState.copyWith(
        mutationStatus: MutationStatus.inProgress,
        clearErrorMessage: true,
      ),
    );
    try {
      await action();
      _isMutating = false;
      _mutationError = null;
      final latestState = state;
      if (latestState is AttendanceTakingLoaded) {
        emit(
          latestState.copyWith(
            mutationStatus: MutationStatus.success,
            clearErrorMessage: true,
          ),
        );
        // Reset success message after a brief delay.
        unawaited(
          Future<void>.delayed(const Duration(seconds: 2)).then((_) {
            final current = state;
            if (current is AttendanceTakingLoaded &&
                current.mutationStatus == MutationStatus.success) {
              emit(current.copyWith(mutationStatus: MutationStatus.idle));
            }
          }),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'mutation failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceTakingCubit',
      );
      final failure = mapExceptionToAttendanceFailure(error);
      _isMutating = false;
      _mutationError = failure.message;
      final latestState = state;
      if (latestState is AttendanceTakingLoaded) {
        emit(
          latestState.copyWith(
            mutationStatus: MutationStatus.failure,
            errorMessage: _mutationError,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    await _rosterSubscription?.cancel();
    await _statusSubscription?.cancel();
    return super.close();
  }
}
