import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  AttendanceHistoryCubit({required IAttendanceRepository repository})
    : _repository = repository,
      super(const AttendanceHistoryInitial());

  final IAttendanceRepository _repository;

  StreamSubscription<List<AttendanceSession>>? _sessionsSubscription;
  StreamSubscription<AttendanceSession?>? _activeSessionSubscription;
  String? _teamId;
  List<AttendanceSession> _sessions = const <AttendanceSession>[];
  AttendanceSession? _activeSession;

  void loadForTeam(String teamId) {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      emit(const AttendanceHistoryError('يجب اختيار الفريق أولا.'));
      return;
    }

    _teamId = normalizedTeamId;
    _sessions = const <AttendanceSession>[];
    _activeSession = null;
    emit(AttendanceHistoryLoading(teamId: normalizedTeamId));

    _sessionsSubscription?.cancel();
    _activeSessionSubscription?.cancel();

    _sessionsSubscription = _repository
        .watchSessionsForTeam(normalizedTeamId)
        .listen((sessions) {
          _sessions = sessions;
          _emitLoaded();
        }, onError: _onStreamError);

    _activeSessionSubscription = _repository
        .watchActiveSessionForTeam(normalizedTeamId)
        .listen((session) {
          _activeSession = session;
          _emitLoaded();
        }, onError: _onStreamError);
  }

  void _emitLoaded() {
    final teamId = _teamId;
    if (teamId == null || teamId.isEmpty) return;
    emit(
      AttendanceHistoryLoaded(
        teamId: teamId,
        sessions: _sessions,
        activeSession: _activeSession,
      ),
    );
  }

  void _onStreamError(Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint(
        'AttendanceHistoryCubit: stream failed (${error.runtimeType})',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
    final failure = mapExceptionToAttendanceFailure(error);
    emit(AttendanceHistoryError(failure.message));
  }

  @override
  Future<void> close() async {
    await _sessionsSubscription?.cancel();
    await _activeSessionSubscription?.cancel();
    return super.close();
  }
}
