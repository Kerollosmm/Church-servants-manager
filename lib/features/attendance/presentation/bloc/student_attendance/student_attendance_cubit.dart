import 'dart:async';

import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/models/student_attendance_history_item.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentAttendanceCubit extends Cubit<StudentAttendanceState> {
  StudentAttendanceCubit({required AttendanceRepository repository})
    : _repository = repository,
      super(const StudentAttendanceInitial());

  final AttendanceRepository _repository;
  String? _studentId;
  String? _teamId;

  Future<void> loadForStudent({
    required String studentId,
    String? teamId,
  }) async {
    _studentId = studentId.trim();
    _teamId = teamId?.trim();
    if (_studentId == null || _studentId!.isEmpty) {
      emit(const StudentAttendanceError('تعذر تحديد المخدوم المطلوب.'));
      return;
    }

    emit(const StudentAttendanceLoading());

    try {
      final history = await _repository.getStudentAttendanceHistory(
        studentId: _studentId!,
        teamId: _teamId,
      );
      _onHistoryLoaded(history);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint(
          'StudentAttendanceCubit: failed to load history '
          '(${error.runtimeType})',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
      final failure = mapExceptionToAttendanceFailure(error);
      emit(StudentAttendanceError(failure.message));
    }
  }

  void _onHistoryLoaded(List<StudentAttendanceHistoryItem> history) {
    final studentId = _studentId;
    if (studentId == null || studentId.isEmpty) return;

    final stats = StudentAttendanceStats.fromHistory(
      studentId: studentId,
      filterTeamId: _teamId,
      history: history,
    );
    emit(StudentAttendanceLoaded(history: history, stats: stats));
  }
}
