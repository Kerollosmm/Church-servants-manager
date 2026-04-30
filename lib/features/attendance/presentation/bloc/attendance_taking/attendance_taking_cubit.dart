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
import 'package:rxdart/rxdart.dart';

/// Cubit for managing attendance-taking UI state during a session.
///
/// Listens to session-level marks and status streams, merging them atomically.
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

  StreamSubscription<AttendanceTakingState>? _sessionSubscription;

  bool _permissionGranted = false;
  String? _cachedTeamId;
  String? _cachedSessionId;

  /// Whether the user permission for this session is already cached.
  bool get isPermissionCached =>
      _permissionGranted && _cachedTeamId != null && _cachedSessionId != null;

  /// Whether there are local marks waiting to be submitted.
  bool get hasPendingMarks {
    final cs = state;
    return cs is AttendanceTakingLoaded && cs.pendingLocalMarks.isNotEmpty;
  }

  /// Number of students without any mark in the current roster.
  int get unmarkedCount {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) return 0;
    return currentState.roster
        .where((s) => !currentState.effectiveMarksMap.containsKey(s.studentId))
        .length;
  }

  void initialize({
    required String teamId,
    required String sessionId,
    AuthUser? actor,
  }) {
    emit(const AttendanceTakingLoading());
    _sessionSubscription?.cancel();

    _sessionSubscription =
        CombineLatestStream.combine2(
          _repository.watchSessionRosterSnapshot(
            teamId: teamId,
            sessionId: sessionId,
          ),
          _repository.watchSessionStatus(teamId: teamId, sessionId: sessionId),
          _mapSnapshotToState,
        ).listen(
          emit,
          onError: (Object error, StackTrace stackTrace) {
            developer.log(
              'session stream failed',
              error: error,
              stackTrace: stackTrace,
              name: 'AttendanceTakingCubit',
            );
            emit(
              AttendanceTakingError(
                mapExceptionToAttendanceFailure(error).message,
              ),
            );
          },
        );

    if (actor != null) {
      unawaited(
        _preloadPermission(actor: actor, teamId: teamId, sessionId: sessionId),
      );
    }
  }

  Future<void> _preloadPermission({
    required AuthUser actor,
    required String teamId,
    required String sessionId,
  }) async {
    try {
      _permissionGranted = await _repository.canUserManageAttendance(
        user: actor,
        teamId: teamId,
      );
      _cachedTeamId = teamId;
      _cachedSessionId = sessionId;
    } catch (_) {
      _permissionGranted = false;
    }
  }

  AttendanceTakingState _mapSnapshotToState(
    AttendanceRosterSnapshot snapshot,
    SessionStatus status,
  ) {
    final marksMap = {
      for (final item in snapshot.roster)
        if (item.manualStatus != null) item.studentId: item.manualStatus!,
    };

    final currentState = state;
    final currentMutationStatus = currentState is AttendanceTakingLoaded
        ? currentState.mutationStatus
        : MutationStatus.idle;

    final currentPending = currentState is AttendanceTakingLoaded
        ? currentState.pendingLocalMarks
        : const <String, AttendanceMarkStatus>{};

    return AttendanceTakingLoaded(
      session: snapshot.session,
      roster: snapshot.roster,
      marksMap: marksMap,
      pendingLocalMarks: currentPending,
      mutationStatus: currentMutationStatus,
      isSessionOpen:
          status != SessionStatus.closed &&
          snapshot.session.isOpenAt(_nowProvider()),
      errorMessage: currentState is AttendanceTakingLoaded
          ? currentState.errorMessage
          : null,
    );
  }

  bool _shouldSkipMutation(
    String studentId,
    AttendanceMarkStatus targetStatus,
  ) {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) return true;
    return currentState.effectiveMarksMap[studentId] == targetStatus;
  }

  Future<void> markPresent({
    required AuthUser actor,
    required AttendanceRosterItem item,
  }) async {
    if (_shouldSkipMutation(item.studentId, AttendanceMarkStatus.present)) {
      return;
    }

    final cs = state;
    if (cs is! AttendanceTakingLoaded) return;
    if (!cs.isSessionOpen) {
      emit(cs.copyWith(errorMessage: 'انتهى وقت تسجيل الحضور لهذه الجلسة.'));
      return;
    }
    emit(cs.withPendingMark(item.studentId, AttendanceMarkStatus.present));
  }

  Future<void> markLate({
    required AuthUser actor,
    required AttendanceRosterItem item,
  }) async {
    if (_shouldSkipMutation(item.studentId, AttendanceMarkStatus.late)) return;

    final cs = state;
    if (cs is! AttendanceTakingLoaded) return;
    if (!cs.isSessionOpen) {
      emit(cs.copyWith(errorMessage: 'انتهى وقت تسجيل الحضور لهذه الجلسة.'));
      return;
    }
    emit(cs.withPendingMark(item.studentId, AttendanceMarkStatus.late));
  }

  Future<void> clearMark({
    required AuthUser actor,
    required AttendanceRosterItem item,
  }) async {
    final currentState = state;
    if (currentState is AttendanceTakingLoaded &&
        !currentState.marksMap.containsKey(item.studentId)) {
      return;
    }

    await _runMutation(
      action: () => _repository.clearStudentMark(
        teamId: item.teamId,
        sessionId: item.sessionId,
        studentId: item.studentId,
        requestedBy: actor,
      ),
    );
  }

  Future<void> submitAllPendingMarks({required AuthUser actor}) async {
    final cs = state;
    if (cs is! AttendanceTakingLoaded) return;
    if (cs.pendingLocalMarks.isEmpty) return;

    final pendingSnapshot = Map<String, AttendanceMarkStatus>.from(
      cs.pendingLocalMarks,
    );

    await _runMutation(
      action: () => _repository.batchWriteMarks(
        teamId: cs.session.teamId,
        sessionId: cs.session.id,
        marks: pendingSnapshot,
        markedBy: actor,
        cachedPermission:
            _permissionGranted && _cachedTeamId == cs.session.teamId,
      ),
    );

    // On success: clear all pending marks from state
    final afterState = state;
    if (afterState is AttendanceTakingLoaded) {
      emit(afterState.copyWith(pendingLocalMarks: const {}));
    }
  }

  Future<void> markAllRemainingPresent({required AuthUser actor}) async {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) return;

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

    if (!currentState.isSessionOpen) {
      emit(
        currentState.copyWith(
          errorMessage: 'انتهى وقت تسجيل الحضور لهذه الجلسة.',
        ),
      );
      return;
    }

    emit(
      currentState.copyWith(
        mutationStatus: MutationStatus.inProgress,
        clearErrorMessage: true,
      ),
    );

    try {
      await action();
      if (isClosed) return;
      if (state is! AttendanceTakingLoaded) return;

      final loadedState = state as AttendanceTakingLoaded;
      emit(loadedState.copyWith(mutationStatus: MutationStatus.success));

      _scheduleReset(const Duration(seconds: 2));
    } catch (error, stackTrace) {
      developer.log(
        'mutation failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceTakingCubit',
      );
      if (isClosed) return;
      if (state is! AttendanceTakingLoaded) return;

      final loadedState = state as AttendanceTakingLoaded;
      emit(
        loadedState.copyWith(
          mutationStatus: MutationStatus.failure,
          errorMessage: mapExceptionToAttendanceFailure(error).message,
        ),
      );
    }
  }

  void _scheduleReset(Duration delay) {
    Future<void>.delayed(delay).then((_) {
      if (isClosed) return;
      final current = state;
      if (current is AttendanceTakingLoaded &&
          current.mutationStatus == MutationStatus.success) {
        emit(current.copyWith(mutationStatus: MutationStatus.idle));
      }
    });
  }

  @override
  Future<void> close() async {
    _permissionGranted = false;
    _cachedTeamId = null;
    _cachedSessionId = null;
    await _sessionSubscription?.cancel();
    return super.close();
  }
}
