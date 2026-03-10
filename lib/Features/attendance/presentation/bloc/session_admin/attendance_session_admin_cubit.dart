import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceSessionAdminCubit extends Cubit<AttendanceSessionAdminState> {
  AttendanceSessionAdminCubit({required IAttendanceRepository repository})
    : _repository = repository,
      super(const AttendanceSessionAdminInitial());

  final IAttendanceRepository _repository;

  Future<void> createSession({
    required AuthUser actor,
    required String teamId,
    required String teamNameSnapshot,
    required DateTime startsAt,
    required int durationMinutes,
    String? title,
  }) async {
    final normalizedTeamId = teamId.trim();
    if (normalizedTeamId.isEmpty) {
      emit(const AttendanceSessionAdminError('يجب اختيار الفريق قبل إنشاء الجلسة.'));
      return;
    }
    if (durationMinutes <= 0 || durationMinutes > 480) {
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
        teamNameSnapshot: teamNameSnapshot,
        startsAt: startsAt,
        durationMinutes: durationMinutes,
        createdBy: actor,
        title: title,
      );
      emit(
        AttendanceSessionAdminSuccess(
          session: session,
          message: 'تم إنشاء جلسة الحضور بنجاح.',
        ),
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'AttendanceSessionAdminCubit: createSession failed '
          '(${error.runtimeType})',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      final failure = mapExceptionToAttendanceFailure(error);
      emit(AttendanceSessionAdminError(failure.message));
    }
  }

  Future<void> closeSession({
    required AuthUser actor,
    required String teamId,
    required String sessionId,
  }) async {
    emit(const AttendanceSessionAdminLoading());
    try {
      final existingSession = await _repository.getSessionById(
        teamId: teamId,
        sessionId: sessionId,
      );
      if (existingSession == null) {
        emit(const AttendanceSessionAdminError('تعذر العثور على جلسة الحضور.'));
        return;
      }

      await _repository.closeSession(
        teamId: teamId,
        sessionId: sessionId,
        closedBy: actor,
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
      if (kDebugMode) {
        debugPrint(
          'AttendanceSessionAdminCubit: closeSession failed '
          '(${error.runtimeType})',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      final failure = mapExceptionToAttendanceFailure(error);
      emit(AttendanceSessionAdminError(failure.message));
    }
  }
}
