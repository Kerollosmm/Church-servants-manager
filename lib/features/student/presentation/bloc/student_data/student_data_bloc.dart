import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_data_event.dart';
part 'student_data_state.dart';

/// BLoC for managing student data with role-based filtering.
/// Events accept filter parameters - UI passes groupId from RoleCubit.
class StudentDataBloc extends Bloc<StudentDataEvent, StudentDataState> {
  final StudentDataRepository _studentRepository;
  String? _lastFilterGroupId;
  String? _lastQuery;
  AuthUser? _lastActor;

  StudentDataBloc({required StudentDataRepository studentRepository})
    : _studentRepository = studentRepository,
      super(const StudentDataInitial()) {
    on<StudentsLoadRequested>(_onLoadStudents);
    on<StudentsSearchRequested>(_onSearchStudents);
    on<StudentCreated>(_onCreateStudent);
    on<StudentUpdated>(_onUpdateStudent);
    on<StudentDeleted>(_onDeleteStudent);
    on<StudentsRefreshRequested>(_onRefreshStudents);
  }

  Future<List<StudentModel>> _fetchStudentsForActor({
    required AuthUser actor,
    required int limit,
  }) async {
    switch (actor.role) {
      case UserRole.admin:
        return _studentRepository.getAllStudents(limit: limit);
      case UserRole.servant:
        final classId = actor.groupId;
        if (classId == null || classId.isEmpty) return [];
        return _studentRepository.getStudentsByClass(classId);
      case UserRole.student:
        throw StateError('Students are not allowed to load student lists.');
    }
  }

  bool _canMutateStudent(AuthUser actor, StudentModel student) {
    if (actor.role == UserRole.admin) return true;
    if (actor.role == UserRole.servant) {
      return actor.groupId != null && student.classId == actor.groupId;
    }
    return false;
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

  Future<void> _onLoadStudents(
    StudentsLoadRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      _lastActor = event.actor;
      _lastFilterGroupId = event.actor.groupId;
      _lastQuery = null;

      final students = await _fetchStudentsForActor(
        actor: event.actor,
        limit: event.limit,
      );

      emit(
        StudentDataLoaded(
          students: students,
          currentFilterGroupId: _lastFilterGroupId,
          currentQuery: null,
        ),
      );
    } catch (e) {
      _emitError(emit, 'Unable to load students', e);
    }
  }

  Future<void> _onSearchStudents(
    StudentsSearchRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      _lastActor = event.actor;
      final query = event.query.trim();
      _lastFilterGroupId = event.actor.groupId;
      _lastQuery = query;

      List<StudentModel> students;

      if (query.isEmpty) {
        students = await _fetchStudentsForActor(actor: event.actor, limit: 50);
      } else {
        switch (event.actor.role) {
          case UserRole.admin:
            students = await _studentRepository.searchStudents(query);
            break;
          case UserRole.servant:
            final classId = event.actor.groupId;
            if (classId == null || classId.isEmpty) {
              students = [];
              break;
            }
            final filtered = await _studentRepository.getStudentsByClass(
              classId,
            );
            students = _filterByName(filtered, query);
            break;
          case UserRole.student:
            throw StateError(
              'Students are not allowed to search student lists.',
            );
        }
      }

      emit(
        StudentDataLoaded(
          students: students,
          currentFilterGroupId: _lastFilterGroupId,
          currentQuery: query.isEmpty ? null : query,
        ),
      );
    } catch (e) {
      _emitError(emit, 'Unable to search students', e);
    }
  }

  Future<void> _onCreateStudent(
    StudentCreated event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      if (!_canMutateStudent(event.actor, event.student)) {
        emit(const StudentDataError('Not allowed.'));
        return;
      }
      await _studentRepository.createStudent(event.student);
      emit(const StudentDataOperationSuccess('Student created successfully'));
      _reloadLastView();
    } catch (e) {
      _emitError(emit, 'Unable to create student', e);
    }
  }

  Future<void> _onUpdateStudent(
    StudentUpdated event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      // Stronger check: validate against stored record so doc/class can't be spoofed.
      final existing = await _studentRepository.getStudentById(
        event.student.docID,
      );
      if (existing == null) {
        emit(const StudentDataError('Student not found.'));
        return;
      }
      if (!_canMutateStudent(event.actor, existing)) {
        emit(const StudentDataError('Not allowed.'));
        return;
      }
      await _studentRepository.updateStudent(event.student);
      emit(const StudentDataOperationSuccess('Student updated successfully'));
      _reloadLastView();
    } catch (e) {
      _emitError(emit, 'Unable to update student', e);
    }
  }

  Future<void> _onDeleteStudent(
    StudentDeleted event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    try {
      final existing = await _studentRepository.getStudentById(event.docId);
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
      _reloadLastView();
    } catch (e) {
      _emitError(emit, 'Unable to delete student', e);
    }
  }

  Future<void> _onRefreshStudents(
    StudentsRefreshRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    _lastActor = event.actor;
    _lastFilterGroupId = event.actor.groupId;
    _reloadLastView();
  }

  void _reloadLastView() {
    final actor = _lastActor;
    if (actor == null) return;

    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      add(StudentsSearchRequested(query: _lastQuery!, actor: actor));
      return;
    }
    add(StudentsLoadRequested(actor: actor));
  }
}
