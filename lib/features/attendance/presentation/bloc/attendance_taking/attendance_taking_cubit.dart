import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_roster_item.dart';
import 'package:church_management_system/features/attendance/data/models/attendance_roster_snapshot.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceTakingCubit extends Cubit<AttendanceTakingState> {
  AttendanceTakingCubit({
    required AttendanceRepository repository,
    DateTime Function()? nowProvider,
  }) : _repository = repository,
       _nowProvider = nowProvider ?? DateTime.now,
       super(const AttendanceTakingInitial());

  final AttendanceRepository _repository;
  final DateTime Function() _nowProvider;

  StreamSubscription<AttendanceRosterSnapshot>? _subscription;
  bool _isMutating = false;
  String? _mutationError;

  void initialize({required String teamId, required String sessionId}) {
    _isMutating = false;
    _mutationError = null;
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
      action: () => _repository.clearStudentMark(
        teamId: item.teamId,
        sessionId: item.sessionId,
        studentId: item.studentId,
        requestedBy: actor,
      ),
    );
  }

  Future<void> markAllRemainingPresent({required AuthUser actor}) {
    final currentState = state;
    if (currentState is! AttendanceTakingLoaded) {
      return Future<void>.value();
    }

    return _runMutation(
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
    if (!currentState.session.isOpenAt(_nowProvider())) {
      _mutationError = 'انتهى وقت تسجيل الحضور لهذه الجلسة.';
      emit(currentState.copyWith(mutationError: _mutationError));
      return;
    }

    _isMutating = true;
    _mutationError = null;
    emit(currentState.copyWith(isMutating: true, clearMutationError: true));
    try {
      await action();
      _isMutating = false;
      _mutationError = null;
      final latestState = state;
      if (latestState is AttendanceTakingLoaded) {
        emit(latestState.copyWith(isMutating: false, clearMutationError: true));
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'AttendanceTakingCubit: mutation failed (${error.runtimeType})',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      final failure = mapExceptionToAttendanceFailure(error);
      _isMutating = false;
      _mutationError = failure.message;
      final latestState = state;
      if (latestState is AttendanceTakingLoaded) {
        emit(
          latestState.copyWith(
            isMutating: false,
            mutationError: _mutationError,
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
