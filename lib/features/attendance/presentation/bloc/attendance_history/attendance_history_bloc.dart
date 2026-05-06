import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/features/attendance/data/models/attendance_session.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_event.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'attendance_history_state.dart';

class AttendanceHistoryBloc
    extends Bloc<AttendanceHistoryEvent, AttendanceHistoryState> {
  final AttendanceRepository _repository;
  String? _teamId;
  List<AttendanceSession> _sessions = const <AttendanceSession>[];
  AttendanceSession? _activeSession;

  AttendanceHistoryBloc({required AttendanceRepository repository})
    : _repository = repository,
      super(const AttendanceHistoryInitial()) {
    on<LoadForTeamEvent>(_onLoadForTeam);
  }

  Future<void> _onLoadForTeam(
    LoadForTeamEvent event,
    Emitter<AttendanceHistoryState> emit,
  ) async {
    final normalizedTeamId = event.teamId.trim();
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

      final teamId = _teamId;
      if (teamId != null && teamId.isNotEmpty) {
        emit(
          AttendanceHistoryLoaded(
            teamId: teamId,
            sessions: _sessions,
            activeSession: _activeSession,
          ),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'loadForTeam failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceHistoryBloc',
      );
      final failure = mapExceptionToAttendanceFailure(error);
      emit(AttendanceHistoryError(failure.message));
    }
  }
}
