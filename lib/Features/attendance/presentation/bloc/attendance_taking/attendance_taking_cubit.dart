import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceTakingCubit extends Cubit<AttendanceTakingState> {
  AttendanceTakingCubit({
    required IAttendanceRepository repository,
    DateTime Function()? nowProvider,
  }) : _repository = repository,
       _nowProvider = nowProvider ?? DateTime.now,
       super(const AttendanceTakingInitial());

  final IAttendanceRepository _repository;
  final DateTime Function() _nowProvider;

  StreamSubscription<AttendanceRosterSnapshot>? _subscription;
  bool _isMutating = false;
  String? _mutationError;
  String? _activeStudentId;

  void initialize({required String teamId, required String sessionId}) {
    _isMutating = false;
    _mutationError = null;
    _activeStudentId = null;
    emit(const AttendanceTakingLoading());
    _subscription?.cancel();
    _subscription = _repository
        .watchSessionRosterSnapshot(teamId: teamId, sessionId: sessionId)
        .listen(
          _onSnapshot,
          onError: (Object error, StackTrace stackTrace) {
            if (kDebugMode) {
              debugPrint(
                'AttendanceTakingCubit: roster stream failed '
                '(${error.runtimeType})',
              );
              debugPrintStack(stackTrace: stackTrace);
            }
            final failure = mapExceptionToAttendanceFailure(error);
            emit(AttendanceTakingError(failure.message));
          },
        );
  }

  void _onSnapshot(AttendanceRosterSnapshot snapshot) {
    final activeStudentId = _activeStudentId;
    if (_isMutating && activeStudentId != null) {
      emit(
        AttendanceTakingMarkInProgress(
          studentId: activeStudentId,
          session: snapshot.session,
          roster: snapshot.roster,
          mutationError: _mutationError,
        ),
      );
      return;
    }

    emit(
      AttendanceTakingLoaded(
        session: snapshot.session,
        roster: snapshot.roster,
        isMutating: _isMutating,
        mutationError: _mutationError,
      ),
    );
  }

  Future<void> markPresent({
    required AuthUser actor,
    required AttendanceRosterItem item,
  }) {
    return _runMutation(
      activeStudentId: item.studentId,
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
    return _runMutation(
      activeStudentId: item.studentId,
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
    return _runMutation(
      activeStudentId: item.studentId,
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
    if (currentState is! AttendanceTakingLoaded) return;

    return _runMutation(
      action: () => _repository.markAllPresentForRemainingStudents(
        teamId: currentState.session.teamId,
        sessionId: currentState.session.id,
        markedBy: actor,
      ),
    );
  }

  // FIX [013-P4]: Preserve the phase-4 API name while keeping current callers.
  Future<void> markAllPresent({required AuthUser actor}) {
    return markAllRemainingPresent(actor: actor);
  }

  Future<void> _runMutation({
    String? activeStudentId,
    required Future<void> Function() action,
  }) async {
    final currentState =
        state; // FIX [P1-C]: Capture pre-mutation state for session validation only
    if (currentState is! AttendanceTakingLoaded) return;
    if (_isMutating) return;
    if (!currentState.session.isOpenAt(_nowProvider())) {
      _mutationError = 'انتهى وقت تسجيل الحضور لهذه الجلسة.';
      emit(currentState.copyWith(mutationError: _mutationError));
      return;
    }

    _isMutating =
        true; // FIX [P1-C]: Set flag before await so _onSnapshot preserves isMutating during stream emissions
    _activeStudentId = activeStudentId;
    _mutationError = null;
    if (activeStudentId != null) {
      emit(
        AttendanceTakingMarkInProgress(
          studentId: activeStudentId,
          session: currentState.session,
          roster: currentState.roster,
        ),
      );
    } else {
      emit(currentState.copyWith(isMutating: true, clearMutationError: true));
    }
    try {
      await action(); // FIX [P1-C]: Stream snapshots arriving here are handled by _onSnapshot using _isMutating flag
      _mutationError =
          null; // FIX [P1-C]: Clear error on success before final emit
    } catch (error, stackTrace) {
      _mutationError = mapExceptionToAttendanceFailure(
        error,
      ).message; // FIX [P1-C]: Capture error first; applied to LATEST state below
      if (kDebugMode) {
        debugPrint(
          'AttendanceTakingCubit: mutation failed (${error.runtimeType})',
        );
        try {
          debugPrintStack(
            stackTrace: stackTrace,
          ); // FIX [P1-C]: Guard against package:stack_trace format assertion in test environments
        } catch (_) {
          // Ignore stack trace formatting errors (e.g. during flutter tests)
        }
      }
    } finally {
      // FIX [P1-C]: Use finally to guarantee state cleanup even if action throws
      _isMutating =
          false; // FIX [P1-C]: Clear flag before final emit so subsequent stream snapshots are not affected
      _activeStudentId = null;
      final latestState =
          state; // FIX [P1-C]: Read LATEST state (may include roster updates from server stream during await)
      if (latestState is AttendanceTakingLoaded) {
        emit(
          latestState.copyWith(
            // FIX [P1-C]: Apply mutation result to latest roster data, not the pre-mutation snapshot
            isMutating: false,
            mutationError: _mutationError,
            clearMutationError: _mutationError == null,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
