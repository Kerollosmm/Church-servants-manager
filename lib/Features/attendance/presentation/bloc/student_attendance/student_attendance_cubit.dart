import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentAttendanceCubit extends Cubit<StudentAttendanceState> {
  StudentAttendanceCubit({required IAttendanceRepository repository})
    : _repository = repository,
      super(const StudentAttendanceInitial());

  final IAttendanceRepository _repository;

  StreamSubscription<List<StudentAttendanceHistoryItem>>? _subscription;
  String? _studentId;
  String? _teamId;

  // FIX [013-P4]: Match the phase-4 public API while preserving current callers.
  void load(String studentId, {String? teamId}) {
    loadForStudent(studentId: studentId, teamId: teamId);
  }

  void loadForStudent({required String studentId, String? teamId}) {
    _studentId = studentId.trim();
    _teamId = teamId?.trim();
    if (_studentId!.isEmpty) {
      emit(const StudentAttendanceError('تعذر تحديد المخدوم المطلوب.'));
      return;
    }

    emit(const StudentAttendanceLoading());
    _subscription?.cancel();
    _subscription = _repository
        .watchStudentAttendanceHistory(studentId: _studentId!, teamId: _teamId)
        .listen(
          _onHistoryUpdated,
          onError: (Object error, StackTrace stackTrace) {
            if (kDebugMode) {
              debugPrint(
                'StudentAttendanceCubit: stream failed (${error.runtimeType})',
              );
              debugPrintStack(stackTrace: stackTrace);
            }
            final failure = mapExceptionToAttendanceFailure(error);
            emit(StudentAttendanceError(failure.message));
          },
        );
  }

  void _onHistoryUpdated(List<StudentAttendanceHistoryItem> history) {
    final studentId = _studentId;
    if (studentId == null) return;
    final stats = StudentAttendanceStats.fromHistory(
      studentId: studentId,
      filterTeamId: _teamId,
      history: history,
    );
    emit(StudentAttendanceLoaded(history: history, stats: stats));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
