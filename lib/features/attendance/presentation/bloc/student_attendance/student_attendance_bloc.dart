import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/features/attendance/data/models/attendance_stats.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/failures/attendance_failures.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_event.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'student_attendance_state.dart';

class StudentAttendanceBloc
    extends Bloc<StudentAttendanceEvent, StudentAttendanceState> {
  final AttendanceRepository _repository;
  String? _studentId;
  String? _teamId;

  StudentAttendanceBloc({required AttendanceRepository repository})
    : _repository = repository,
      super(const StudentAttendanceInitial()) {
    on<LoadForStudentEvent>(_onLoadForStudent);
  }

  Future<void> _onLoadForStudent(
    LoadForStudentEvent event,
    Emitter<StudentAttendanceState> emit,
  ) async {
    _studentId = event.studentId.trim();
    _teamId = event.teamId?.trim();
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

      final studentId = _studentId;
      if (studentId == null || studentId.isEmpty) return;

      final stats = StudentAttendanceStats.fromHistory(
        studentId: studentId,
        filterTeamId: _teamId,
        history: history,
      );
      emit(StudentAttendanceLoaded(history: history, stats: stats));
    } catch (error, stackTrace) {
      developer.log(
        'failed to load history',
        error: error,
        stackTrace: stackTrace,
        name: 'StudentAttendanceBloc',
      );
      final failure = mapExceptionToAttendanceFailure(error);
      emit(StudentAttendanceError(failure.message));
    }
  }
}
