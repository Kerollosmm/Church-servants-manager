import 'dart:developer' as developer;

import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_event.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'attendance_session_admin_state.dart';

class AttendanceSessionAdminBloc
    extends Bloc<AttendanceSessionAdminEvent, AttendanceSessionAdminState> {
  final AttendanceRepository _repository;

  AttendanceSessionAdminBloc({required AttendanceRepository repository})
    : _repository = repository,
      super(const AttendanceSessionAdminInitial()) {
    on<CreateSessionEvent>(_onCreateSession);
    on<CreateSessionsBulkEvent>(_onCreateSessionsBulk);
    on<CloseSessionEvent>(_onCloseSession);
  }

  Future<void> _onCreateSession(
    CreateSessionEvent event,
    Emitter<AttendanceSessionAdminState> emit,
  ) async {
    final normalizedTeamId = event.teamId.trim();
    if (normalizedTeamId.isEmpty) {
      emit(
        const AttendanceSessionAdminError(
          'يجب اختيار الفريق قبل إنشاء الجلسة.',
        ),
      );
      return;
    }
    if (event.durationMinutes <= 0 || event.durationMinutes > 480) {
      emit(
        const AttendanceSessionAdminError(
          'مدة الجلسة يجب أن تكون بين دقيقة واحدة و 480 دقيقة.',
        ),
      );
      return;
    }

    emit(const AttendanceSessionAdminLoading());
    try {
      final session = await _repository.createSession(
        teamId: normalizedTeamId,
        teamNameSnapshot: event.teamNameSnapshot,
        startsAt: event.startsAt,
        durationMinutes: event.durationMinutes,
        createdBy: event.actor,
        title: event.title,
      );
      emit(
        AttendanceSessionAdminSuccess(
          session: session,
          message: 'تم إنشاء جلسة الحضور بنجاح.',
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'createSession failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceSessionAdminBloc',
      );
      final failure = mapExceptionToAttendanceFailure(error);
      emit(AttendanceSessionAdminError(failure.message));
    }
  }

  Future<void> _onCreateSessionsBulk(
    CreateSessionsBulkEvent event,
    Emitter<AttendanceSessionAdminState> emit,
  ) async {
    if (event.teamIdsAndNames.isEmpty) {
      emit(const AttendanceSessionAdminError('لا توجد فرق مختارة.'));
      return;
    }
    if (event.durationMinutes <= 0 || event.durationMinutes > 480) {
      emit(
        const AttendanceSessionAdminError(
          'مدة الجلسة يجب أن تكون بين دقيقة واحدة و 480 دقيقة.',
        ),
      );
      return;
    }

    emit(const AttendanceSessionAdminLoading());
    try {
      final result = await _repository.createSessionsBulk(
        teamIdsAndNames: event.teamIdsAndNames,
        startsAt: event.startsAt,
        durationMinutes: event.durationMinutes,
        createdBy: event.actor,
        title: event.title,
      );

      if (result.isCompleteSuccess) {
        emit(
          AttendanceSessionAdminBulkSuccess(
            message: 'تم إنشاء جلسات الحضور لجميع الفرق بنجاح.',
            result: result,
          ),
        );
      } else if (result.isCompleteFailure) {
        emit(
          const AttendanceSessionAdminError(
            'فشلت عملية إنشاء جلسات الحضور لجميع الفرق.',
          ),
        );
      } else {
        emit(
          AttendanceSessionAdminBulkSuccess(
            message:
                'تم إنشاء بعض الجلسات بنجاح، وفشل البعض الآخر (${result.failedItems.length} فشل).',
            result: result,
          ),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'createSessionsBulk failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceSessionAdminBloc',
      );
      final failure = mapExceptionToAttendanceFailure(error);
      emit(AttendanceSessionAdminError(failure.message));
    }
  }

  Future<void> _onCloseSession(
    CloseSessionEvent event,
    Emitter<AttendanceSessionAdminState> emit,
  ) async {
    emit(const AttendanceSessionAdminLoading());
    try {
      final existingSession = await _repository.getSessionById(
        teamId: event.teamId,
        sessionId: event.sessionId,
      );
      if (existingSession == null) {
        emit(const AttendanceSessionAdminError('تعذر العثور على جلسة الحضور.'));
        return;
      }

      await _repository.closeSession(
        teamId: event.teamId,
        sessionId: event.sessionId,
        closedBy: event.actor,
      );

      emit(
        AttendanceSessionAdminSuccess(
          session: existingSession.copyWith(
            isClosed: true,
            updatedAt: DateTime.now(),
          ),
          message: 'تم إغلاق جلسة الحضور.',
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'closeSession failed',
        error: error,
        stackTrace: stackTrace,
        name: 'AttendanceSessionAdminBloc',
      );
      final failure = mapExceptionToAttendanceFailure(error);
      emit(AttendanceSessionAdminError(failure.message));
    }
  }
}
