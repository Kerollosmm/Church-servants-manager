import 'dart:async';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
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
  final AuthService _authService;

  StreamSubscription<List<StudentModel>>? _studentsSubscription;
  List<StudentModel> _allStudents = [];
  Map<String, StudentModel> _studentsByDocId = {};
  String? _lastFilterGroupId;
  String? _lastFilterTeamId;
  String? _lastQuery;

  StudentDataBloc({
    required StudentDataRepository studentRepository,
    required GetStudentsStreamUseCase getStudentsStream,
    required CanMutateStudentUseCase canMutateStudent,
    required AuthService authService,
  }) : _studentRepository = studentRepository,
       _getStudentsStream = getStudentsStream,
       _canMutateStudent = canMutateStudent,
       _authService = authService,
       super(const StudentDataInitial()) {
    on<StudentsLoadRequested>(_onLoadStudents);
    on<StudentsSearchRequested>(_onSearchStudents);
    on<StudentCreated>(_onCreateStudent);
    on<StudentUpdated>(_onUpdateStudent);
    on<StudentDeleted>(_onDeleteStudent);
    on<StudentsRefreshRequested>(_onRefreshStudents);
    on<StudentsListeningStopped>(_onStopListening);
    on<_StudentsStreamUpdated>(_onStreamUpdated);
    on<_StreamError>(_onStreamError);
  }

  Future<void> _cancelStudentsSubscription() async {
    final subscription = _studentsSubscription;
    _studentsSubscription = null;
    await subscription?.cancel();
  }

  /// Subscribes to the stream returned by the use case.
  Future<void> _subscribeToStudents({
    required AuthUser actor,
    String? teamId,
  }) async {
    await _cancelStudentsSubscription();

    final stream = _getStudentsStream(actor: actor, teamId: teamId);

    if (stream == null) {
      add(const _StudentsStreamUpdated([]));
      return;
    }

    _studentsSubscription = stream.listen(
      (students) {
        if (isClosed) return;
        students.sort((a, b) => a.name.compareTo(b.name));
        add(_StudentsStreamUpdated(students));
      },
      onError: (Object error) {
        if (isClosed) return;
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
    return _studentsByDocId[docId];
  }

  Future<void> _onLoadStudents(
    StudentsLoadRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    _lastFilterGroupId = event.actor.groupId;
    _lastFilterTeamId = event.teamId;
    _lastQuery = null;

    await _subscribeToStudents(actor: event.actor, teamId: event.teamId);
  }

  void _onStreamUpdated(
    _StudentsStreamUpdated event,
    Emitter<StudentDataState> emit,
  ) {
    _allStudents = event.students
        .where((student) => student.role == UserRole.student)
        .toList(growable: false);
    _studentsByDocId = {for (final s in _allStudents) s.docID: s};
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

      var studentToCreate = event.student;

      // Create a Firebase Auth account if email + password are provided.
      if (event.email != null &&
          event.email!.isNotEmpty &&
          event.password != null &&
          event.password!.isNotEmpty) {
        final authUser = await _authService.createUserAsAdmin(
          email: event.email!,
          password: event.password!,
          name: event.student.name,
          role: event.student.role,
        );
        studentToCreate = event.student.copyWith(
          uid: authUser.uid,
          docID: authUser.uid,
        );
      }

      await _studentRepository.createStudent(studentToCreate);
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

      if (isRoleChange) {
        await _studentRepository.updateStudentAndSyncLinkedUserRole(
          updatedStudent: event.student,
          previousRole: existing.role,
        );
      } else {
        await _studentRepository.updateStudent(event.student);
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
    emit(const StudentDataLoading());
    _lastFilterGroupId = event.actor.groupId;
    await _subscribeToStudents(actor: event.actor, teamId: _lastFilterTeamId);
  }

  Future<void> _onStopListening(
    StudentsListeningStopped event,
    Emitter<StudentDataState> emit,
  ) async {
    await _cancelStudentsSubscription();
    _allStudents = const [];
    _lastFilterGroupId = null;
    _lastFilterTeamId = null;
    _lastQuery = null;
    emit(const StudentDataInitial());
  }

  @override
  Future<void> close() async {
    await _cancelStudentsSubscription();
    return super.close();
  }
}
