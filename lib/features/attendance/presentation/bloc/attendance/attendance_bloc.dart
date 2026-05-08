import 'dart:developer' as developer;

import 'package:church_management_system/core/models/sync_entry.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance/attendance_event.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance/attendance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'attendance_event.dart';
export 'attendance_state.dart';

/// BLoC for taking attendance.
/// Handles session creation and implements optimistic UI updates with background syncing.
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _attendanceRepository;
  final SyncService _syncService;

  AttendanceBloc({
    required AttendanceRepository attendanceRepository,
    required SyncService syncService,
  }) : _attendanceRepository = attendanceRepository,
       _syncService = syncService,
       super(const AttendanceInitial()) {
    on<StartSession>(_onStartSession);
    on<LoadSessionRoster>(_onLoadSessionRoster);
    on<ToggleAttendance>(_onToggleAttendance);
  }

  Future<void> _onStartSession(
    StartSession event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      final session = await _attendanceRepository.createSession(
        teamId: event.teamId,
        teamNameSnapshot: event.teamNameSnapshot,
        startsAt: event.startsAt,
        durationMinutes: event.durationMinutes,
        createdBy: event.createdBy,
        title: event.title,
      );

      // Load roster immediately after session creation
      final rosterSnapshot = await _attendanceRepository
          .getSessionRosterSnapshot(
            teamId: session.teamId,
            sessionId: session.id,
          );

      emit(
        AttendanceSessionActive(
          session: session,
          roster: rosterSnapshot.roster,
        ),
      );
    } catch (e) {
      developer.log('Error creating session', error: e);
      emit(AttendanceError(message: 'حدث خطأ أثناء إنشاء الجلسة: $e'));
    }
  }

  Future<void> _onLoadSessionRoster(
    LoadSessionRoster event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    try {
      final session = await _attendanceRepository.getSessionById(
        teamId: event.teamId,
        sessionId: event.sessionId,
      );

      if (session == null) {
        emit(const AttendanceError(message: 'الجلسة غير موجودة.'));
        return;
      }

      final rosterSnapshot = await _attendanceRepository
          .getSessionRosterSnapshot(
            teamId: event.teamId,
            sessionId: event.sessionId,
          );

      emit(
        AttendanceSessionActive(
          session: session,
          roster: rosterSnapshot.roster,
        ),
      );
    } catch (e) {
      developer.log('Error loading roster', error: e);
      emit(AttendanceError(message: 'حدث خطأ أثناء تحميل القائمة: $e'));
    }
  }

  Future<void> _onToggleAttendance(
    ToggleAttendance event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is! AttendanceSessionActive) return;

    final currentState = state as AttendanceSessionActive;

    // 1. Optimistic UI Update
    final updatedRoster = currentState.roster.map((item) {
      if (item.studentId == event.studentId) {
        return item.copyWith(
          manualStatus: event.newStatus,
          isMarked: true,
          markedByName: event.markedBy.name,
          markedAt: DateTime.now(),
        );
      }
      return item;
    }).toList();

    // Immediately emit the new state to provide zero-latency feedback
    emit(currentState.copyWith(roster: updatedRoster));

    // 2. Background Sync
    final syncEntry = SyncEntry(
      id: 'mark_attendance_${currentState.session.id}_${event.studentId}_${event.markedBy.uid}',
      actionType: 'MARK_ATTENDANCE',
      payload: {
        'teamId': currentState.session.teamId,
        'sessionId': currentState.session.id,
        'studentId': event.studentId,
        'status': event.newStatus.name,
        'markedByUid': event.markedBy.uid,
        'markedByName': event.markedBy.name,
      },
      createdAt: DateTime.now(),
    );

    // Enqueue the operation and DO NOT await its completion
    _syncService.enqueue(syncEntry);
  }
}
