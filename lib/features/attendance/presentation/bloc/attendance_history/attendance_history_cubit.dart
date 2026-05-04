import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceHistoryCubit extends Cubit<AttendanceHistoryState> {
  AttendanceHistoryCubit({required AttendanceRepository repository})
    : _repository = repository,
      super(const AttendanceHistoryInitial());

  final AttendanceRepository _repository;
  String? _teamId;
  List<AttendanceSession> _sessions = const <AttendanceSession>[];
  AttendanceSession? _activeSession;

  Future<void> loadForTeam(String teamId) async {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      emit(const AttendanceHistoryError('يجب اختيار الفريق أولا.'));
      return;
    }

    _teamId = normalizedTeamId;
    _sessions = const <AttendanceSession>[];
    _activeSession = null;
    emit(AttendanceHistoryLoading(teamId: normalizedTeamId));

    try {
      final sessions = await _repository.getSessionsForTeam(normalizedTeamId);
      final now = DateTime.now();

      _sessions = sessions;
      try {
        _activeSession = sessions.firstWhere((s) => s.isOpenAt(now));
      } catch (_) {
        _activeSession = null;
      }

      _emitLoaded();
    } catch (error, stackTrace) {
      developer.log(
        'loadForTeam failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceHistoryCubit',
      );
      _onStreamError(error, stackTrace);
    }
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
    developer.log(
      'stream failed',
      error: error,
      stackTrace: stackTrace,
      name: 'AttendanceHistoryCubit',
    );
    final failure = mapExceptionToAttendanceFailure(error);
    emit(AttendanceHistoryError(failure.message));
  }
}
