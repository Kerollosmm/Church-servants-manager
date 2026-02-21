import 'dart:async';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_managment_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_data_event.dart';
part 'student_data_state.dart';

/// BLoC for managing student data with role-based filtering.
///
/// Delegates stream selection to [GetStudentsStreamUseCase]
/// and authorization to [CanMutateStudentUseCase].
class StudentDataBloc extends Bloc<StudentDataEvent, StudentDataState> {
  final StudentDataRepository _studentRepository;
  final GetStudentsStreamUseCase _getStudentsStream;
  final CanMutateStudentUseCase _canMutateStudent;

  StreamSubscription<List<StudentModel>>? _studentsSubscription;
  List<StudentModel> _allStudents = [];
  String? _lastFilterGroupId;
  String? _lastFilterTeamId;
  String? _lastQuery;

  StudentDataBloc({
    required StudentDataRepository studentRepository,
    required GetStudentsStreamUseCase getStudentsStream,
    required CanMutateStudentUseCase canMutateStudent,
  }) : _studentRepository = studentRepository,
       _getStudentsStream = getStudentsStream,
       _canMutateStudent = canMutateStudent,
       super(const StudentDataInitial()) {
    on<StudentsLoadRequested>(_onLoadStudents);
    on<StudentsSearchRequested>(_onSearchStudents);
    on<StudentCreated>(_onCreateStudent);
    on<StudentUpdated>(_onUpdateStudent);
    on<StudentDeleted>(_onDeleteStudent);
    on<StudentsRefreshRequested>(_onRefreshStudents);
    on<_StudentsStreamUpdated>(_onStreamUpdated);
    on<_StreamError>(_onStreamError);
  }

  /// Subscribes to the stream returned by the use case.
  void _subscribeToStudents({required AuthUser actor, String? teamId}) {
    _studentsSubscription?.cancel();

    final stream = _getStudentsStream(actor: actor, teamId: teamId);

    if (stream == null) {
      add(const _StudentsStreamUpdated([]));
      return;
    }

    _studentsSubscription = stream.listen(
      (students) {
        students.sort((a, b) => a.name.compareTo(b.name));
        add(_StudentsStreamUpdated(students));
      },
      onError: (Object error) {
        debugPrint('StudentDataBloc: Stream error - $error');
        add(_StreamError('$error'));
      },
    );
  }

  List<StudentModel> _filterByName(List<StudentModel> students, String query) {
    final normalized = query.toLowerCase();
    return students
        .where((s) => s.name.toLowerCase().contains(normalized))
        .toList();
  }

  void _emitError(
    Emitter<StudentDataState> emit,
    String message,
    Object error,
  ) {
    debugPrint('StudentDataBloc: $message - $error');
    emit(StudentDataError('$message. Please try again.'));
  }

  StudentModel? _getCachedStudentById(String docId) {
    for (final student in _allStudents) {
      if (student.docID == docId) return student;
    }
    return null;
  }

  Future<void> _onLoadStudents(
    StudentsLoadRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    _lastFilterGroupId = event.actor.groupId;
    _lastFilterTeamId = event.teamId;
    _lastQuery = null;

    _subscribeToStudents(actor: event.actor, teamId: event.teamId);
  }

  void _onStreamUpdated(
    _StudentsStreamUpdated event,
    Emitter<StudentDataState> emit,
  ) {
    _allStudents = event.students
        .where((student) => student.role == UserRole.student)
        .toList(growable: false);
    final query = _lastQuery;
    final students = (query != null && query.isNotEmpty)
        ? _filterByName(_allStudents, query)
        : _allStudents;

    emit(
      StudentDataLoaded(
        students: students,
        currentFilterGroupId: _lastFilterGroupId,
        currentFilterTeamId: _lastFilterTeamId,
        currentQuery: query,
      ),
    );
  }

  void _onStreamError(_StreamError event, Emitter<StudentDataState> emit) {
    emit(StudentDataError(event.message));
  }

  Future<void> _onSearchStudents(
    StudentsSearchRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    final query = event.query.trim();
    _lastQuery = query;

    final students = (query.isNotEmpty)
        ? _filterByName(_allStudents, query)
        : _allStudents;

    emit(
      StudentDataLoaded(
        students: students,
        currentFilterGroupId: _lastFilterGroupId,
        currentFilterTeamId: _lastFilterTeamId,
        currentQuery: query,
      ),
    );
  }

  Future<void> _onCreateStudent(
    StudentCreated event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      if (!_canMutateStudent(event.actor, event.student)) {
        emit(const StudentDataError('Not allowed.'));
        return;
      }
      await _studentRepository.createStudent(event.student);
      emit(const StudentDataOperationSuccess('Student created successfully'));
    } catch (e) {
      _emitError(emit, 'Unable to create student', e);
    }
  }

  Future<void> _onUpdateStudent(
    StudentUpdated event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      final existing =
          _getCachedStudentById(event.student.docID) ??
          await _studentRepository.getStudentById(event.student.docID);
      if (existing == null) {
        emit(const StudentDataError('Student not found.'));
        return;
      }
      if (!_canMutateStudent(event.actor, existing)) {
        emit(const StudentDataError('Not allowed.'));
        return;
      }

      final isRoleChange = existing.role != event.student.role;
      if (isRoleChange && event.actor.role != UserRole.admin) {
        emit(const StudentDataError('Not allowed.'));
        return;
      }
      if (isRoleChange &&
          event.student.role == UserRole.servant &&
          event.student.uid.trim().isEmpty) {
        emit(
          const StudentDataError(
            'Cannot promote student without linked user account.',
          ),
        );
        return;
      }

      await _studentRepository.updateStudent(event.student);
      if (isRoleChange) {
        await _studentRepository.syncLinkedUserRoleFromStudent(
          updatedStudent: event.student,
          previousRole: existing.role,
        );
      }
      emit(const StudentDataOperationSuccess('Student updated successfully'));
    } catch (e) {
      _emitError(emit, 'Unable to update student', e);
    }
  }

  Future<void> _onDeleteStudent(
    StudentDeleted event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      final existing =
          _getCachedStudentById(event.docId) ??
          await _studentRepository.getStudentById(event.docId);
      if (existing == null) {
        emit(const StudentDataError('Student not found.'));
        return;
      }
      if (!_canMutateStudent(event.actor, existing)) {
        emit(const StudentDataError('Not allowed.'));
        return;
      }
      await _studentRepository.deleteStudent(event.docId);
      emit(const StudentDataOperationSuccess('Student deleted successfully'));
    } catch (e) {
      _emitError(emit, 'Unable to delete student', e);
    }
  }

  Future<void> _onRefreshStudents(
    StudentsRefreshRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    _lastFilterGroupId = event.actor.groupId;
    _subscribeToStudents(actor: event.actor, teamId: _lastFilterTeamId);
  }

  @override
  Future<void> close() {
    _studentsSubscription?.cancel();
    return super.close();
  }
}
