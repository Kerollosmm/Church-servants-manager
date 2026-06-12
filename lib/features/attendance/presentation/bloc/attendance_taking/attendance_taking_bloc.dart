import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_mark.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_enums.dart';
import 'package:church_management_system/features/attendance/domain/entities/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_event.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Bloc for managing attendance-taking UI state during a session.
///
/// Uses pull-to-refresh model for quota efficiency on Spark plan.
/// Delegates mutations to [AttendanceRepository] with idempotency guards.
class AttendanceTakingBloc
    extends Bloc<AttendanceTakingEvent, AttendanceTakingState> {
  AttendanceTakingBloc({
    required AttendanceRepository repository,
    required AttendanceLocalDatasource localDatasource,
    required SyncService syncService,
    DateTime Function()? nowProvider,
  }) : _repository = repository,
       _localDatasource = localDatasource,
       _nowProvider = nowProvider ?? DateTime.now,
       super(const AttendanceTakingInitial()) {
    on<InitializeSessionEvent>(_onInitializeSession);
    on<RefreshSessionEvent>(_onRefreshSession);
    on<MarkStudentPresentEvent>(_onMarkStudentPresent);
    on<MarkStudentAbsentEvent>(_onMarkStudentAbsent);
    on<MarkStudentLateEvent>(_onMarkStudentLate);
    on<ClearStudentMarkEvent>(_onClearStudentMark);
    on<SubmitSessionEvent>(_onSubmitSession);
    on<MarkAllRemainingPresentEvent>(_onMarkAllRemainingPresent);
    on<ResetMutationStatusEvent>(_onResetMutationStatus);
    on<SessionTickEvent>(_onSessionTick);
  }

  final AttendanceRepository _repository;
  final AttendanceLocalDatasource _localDatasource;
  final DateTime Function() _nowProvider;

  Timer? _sessionTickerTimer;
  bool _permissionGranted = false;
  String? _cachedTeamId;
  String? _cachedSessionId;

  /// Whether the user permission for this session is already cached.
  bool get isPermissionCached =>
      _permissionGranted && _cachedTeamId != null && _cachedSessionId != null;

  Future<void> _onInitializeSession(
    InitializeSessionEvent event,
    Emitter<AttendanceTakingState> emit,
  ) async {
    emit(const AttendanceTakingLoading());

    try {
      await _fetchAndEmitSessionData(event.teamId, event.sessionId, emit);
      _startSessionTicker(event.teamId, event.sessionId);

      if (event.actor != null) {
        unawaited(
          _preloadPermission(
            actor: event.actor!,
            teamId: event.teamId,
            sessionId: event.sessionId,
          ),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'initialize failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceTakingBloc',
      );
      emit(
        AttendanceTakingError(mapExceptionToAttendanceFailure(error).message),
      );
    }
  }

  Future<void> _onRefreshSession(
    RefreshSessionEvent event,
    Emitter<AttendanceTakingState> emit,
  ) async {
    try {
      await _fetchAndEmitSessionData(event.teamId, event.sessionId, emit);
      _startSessionTicker(event.teamId, event.sessionId);
    } catch (error, stackTrace) {
      developer.log(
        'refresh failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceTakingBloc',
      );
    }
  }

  Future<void> _fetchAndEmitSessionData(
    String teamId,
    String sessionId,
    Emitter<AttendanceTakingState> emit,
  ) async {
    final results = await Future.wait([
      _repository.getSessionRosterSnapshot(
        teamId: teamId,
        sessionId: sessionId,
      ),
      _repository.getSessionStatus(teamId: teamId, sessionId: sessionId),
    ]);

    final snapshot = results[0] as AttendanceRosterSnapshot;
    final status = results[1] as SessionStatus;

    emit(_mapSnapshotToState(snapshot, status));
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

  void _onMarkStudentPresent(
    MarkStudentPresentEvent event,
    Emitter<AttendanceTakingState> emit,
  ) {
    _handleMarkUpdate(event.item.studentId, AttendanceMarkStatus.present, emit);
  }

  void _onMarkStudentAbsent(
    MarkStudentAbsentEvent event,
    Emitter<AttendanceTakingState> emit,
  ) {
    _handleMarkUpdate(event.item.studentId, AttendanceMarkStatus.absent, emit);
  }

  void _onMarkStudentLate(
    MarkStudentLateEvent event,
    Emitter<AttendanceTakingState> emit,
  ) {
    _handleMarkUpdate(event.item.studentId, AttendanceMarkStatus.late, emit);
  }

  void _handleMarkUpdate(
    String studentId,
    AttendanceMarkStatus targetStatus,
    Emitter<AttendanceTakingState> emit,
  ) {
    if (_shouldSkipMutation(studentId, targetStatus)) return;

    final cs = state;
    if (cs is! AttendanceTakingLoaded) return;

    if (!cs.isSessionOpen) {
      emit(cs.copyWith(errorMessage: 'انتهى وقت تسجيل الحضور لهذه الجلسة.'));
      return;
    }

    emit(cs.withPendingMark(studentId, targetStatus));

    // Persist to Hive immediately for crash resilience
    final now = DateTime.now();
    unawaited(
      _localDatasource.cacheMark(
        teamId: cs.session.teamId,
        sessionId: cs.session.id,
        studentId: studentId,
        mark: AttendanceMark(
          studentId: studentId,
          studentNameSnapshot: cs.session.studentNameSnapshots[studentId] ?? '',
          status: targetStatus,
          markedByUserId: '',
          markedByName: '',
          markedAt: now,
          updatedAt: now,
        ),
      ),
    );
  }

  Future<void> _onClearStudentMark(
    ClearStudentMarkEvent event,
    Emitter<AttendanceTakingState> emit,
  ) async {
    final currentState = state;
    if (currentState is AttendanceTakingLoaded &&
        !currentState.marksMap.containsKey(event.item.studentId)) {
      return;
    }

    await _runMutation(
      emit: emit,
      action: () => _repository.clearStudentMark(
        teamId: event.item.teamId,
        sessionId: event.item.sessionId,
        studentId: event.item.studentId,
        requestedBy: event.actor,
      ),
    );
  }

  Future<void> _onSubmitSession(
    SubmitSessionEvent event,
    Emitter<AttendanceTakingState> emit,
  ) async {
    final cs = state;
    if (cs is! AttendanceTakingLoaded) return;
    if (cs.pendingLocalMarks.isEmpty) return;

    final pendingSnapshot = Map<String, AttendanceMarkStatus>.from(
      cs.pendingLocalMarks,
    );

    await _runMutation(
      emit: emit,
      action: () => _repository.batchWriteMarks(
        teamId: cs.session.teamId,
        sessionId: cs.session.id,
        marks: pendingSnapshot,
        markedBy: event.actor,
        cachedPermission:
            _permissionGranted && _cachedTeamId == cs.session.teamId,
      ),
    );

    // On success: clear all pending marks from state and cache
    final afterState = state;
    if (afterState is AttendanceTakingLoaded) {
      emit(afterState.copyWith(pendingLocalMarks: const {}));
      unawaited(_localDatasource.clearCache());
    }
  }

  Future<void> _onMarkAllRemainingPresent(
    MarkAllRemainingPresentEvent event,
    Emitter<AttendanceTakingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) return;

    await _runMutation(
      emit: emit,
      action: () => _repository.markAllPresentForRemainingStudents(
        teamId: currentState.session.teamId,
        sessionId: currentState.session.id,
        markedBy: event.actor,
      ),
    );
  }

  Future<void> _runMutation({
    required Emitter<AttendanceTakingState> emit,
    required Future<void> Function() action,
  }) async {
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

    if (currentState.mutationStatus == MutationStatus.inProgress) return;

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
        name: 'AttendanceTakingBloc',
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

  Timer? _resetTimer;

  void _scheduleReset(Duration delay) {
    _resetTimer?.cancel();
    _resetTimer = Timer(delay, () {
      if (isClosed) return;
      add(const ResetMutationStatusEvent());
    });
  }

  void _onResetMutationStatus(
    ResetMutationStatusEvent event,
    Emitter<AttendanceTakingState> emit,
  ) {
    final current = state;
    if (current is AttendanceTakingLoaded &&
        current.mutationStatus == MutationStatus.success) {
      emit(current.copyWith(mutationStatus: MutationStatus.idle));
    }
  }

  void _startSessionTicker(String teamId, String sessionId) {
    _sessionTickerTimer?.cancel();
    _sessionTickerTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      final cs = state;
      if (cs is AttendanceTakingLoaded) {
        final nowOpen = cs.session.isOpenAt(_nowProvider());
        if (cs.isSessionOpen != nowOpen) {
          add(SessionTickEvent(isSessionOpen: nowOpen));
        }
        if (!nowOpen) {
          _sessionTickerTimer?.cancel();
        }
      }
    });
  }

  void _onSessionTick(
    SessionTickEvent event,
    Emitter<AttendanceTakingState> emit,
  ) {
    final cs = state;
    if (cs is AttendanceTakingLoaded) {
      emit(cs.copyWith(isSessionOpen: event.isSessionOpen));
    }
  }

  @override
  Future<void> close() async {
    _resetTimer?.cancel();
    _sessionTickerTimer?.cancel();
    _permissionGranted = false;
    _cachedTeamId = null;
    _cachedSessionId = null;
    return super.close();
  }
}
