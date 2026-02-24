import 'dart:async';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_managment_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

part 'student_data_event.dart';
part 'student_data_state.dart';

/// BLoC for managing student data with role-based filtering.
///
/// Delegates stream selection to [GetStudentsStreamUseCase]
/// and authorization to [CanMutateStudentUseCase].
class StudentDataBloc extends Bloc<StudentDataEvent, StudentDataState> {
  static const int _backgroundSortThreshold = 120;

  final StudentDataRepository _studentRepository;
  final GetStudentsStreamUseCase _getStudentsStream;
  final CanMutateStudentUseCase _canMutateStudent;
  final AuthService _authService;

  StreamSubscription<List<StudentModel>>? _studentsSubscription;
  int _studentsEmissionVersion = 0;
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
    on<StudentFormSubmitted>(_onFormSubmitted);
    on<_StudentsStreamUpdated>(_onStreamUpdated);
    on<_StreamError>(_onStreamError);
  }

  Future<void> _cancelStudentsSubscription() async {
    final subscription = _studentsSubscription;
    _studentsSubscription = null;
    _studentsEmissionVersion++;
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
      (students) async {
        if (isClosed) return;
        final emissionVersion = ++_studentsEmissionVersion;
        final sortedStudents = await _sortStudentsForUi(students);
        if (isClosed || emissionVersion != _studentsEmissionVersion) return;
        add(_StudentsStreamUpdated(sortedStudents));
      },
      onError: (Object error) {
        if (isClosed) return;
        debugPrint('StudentDataBloc: Stream error - $error');
        add(_StreamError('$error'));
      },
    );
  }

  void _onStreamUpdated(
    _StudentsStreamUpdated event,
    Emitter<StudentDataState> emit,
  ) {
    final students = event.students
        .where((student) => student.role == UserRole.student)
        .toList(growable: false);
    _studentsByDocId = {for (final s in students) s.docID: s};

    emit(
      StudentDataLoaded(
        students: students,
        currentFilterGroupId: _lastFilterGroupId,
        currentFilterTeamId: _lastFilterTeamId,
        currentQuery: _lastQuery,
      ),
    );
  }

  void _emitError(
    Emitter<StudentDataState> emit,
    String message,
    Object error,
  ) {
    debugPrint('StudentDataBloc: $message - $error');
    emit(StudentDataError('$message. Please try again.'));
  }

  int _compareStudentsByName(StudentModel a, StudentModel b) {
    final nameCompare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    if (nameCompare != 0) return nameCompare;
    return a.docID.compareTo(b.docID);
  }

  bool _isSortedByName(List<StudentModel> students) {
    for (var i = 1; i < students.length; i++) {
      if (_compareStudentsByName(students[i - 1], students[i]) > 0) {
        return false;
      }
    }
    return true;
  }

  Future<List<StudentModel>> _sortStudentsForUi(
    List<StudentModel> students,
  ) async {
    if (students.length < 2 || _isSortedByName(students)) {
      return students;
    }

    if (students.length < _backgroundSortThreshold) {
      final sorted = List<StudentModel>.of(students);
      sorted.sort(_compareStudentsByName);
      return sorted;
    }

    final sortRows = <List<String>>[
      for (final student in students)
        <String>[student.docID, student.name.toLowerCase()],
    ];

    try {
      final sortedIds = await compute(_sortStudentIdsByName, sortRows);
      final byId = <String, StudentModel>{
        for (final student in students) student.docID: student,
      };
      final ordered = <StudentModel>[];
      for (final id in sortedIds) {
        final student = byId.remove(id);
        if (student != null) {
          ordered.add(student);
        }
      }

      if (byId.isNotEmpty) {
        final remaining = byId.values.toList(growable: false);
        final sortedRemaining = List<StudentModel>.of(remaining)
          ..sort(_compareStudentsByName);
        ordered.addAll(sortedRemaining);
      }

      return ordered;
    } catch (error) {
      debugPrint(
        'StudentDataBloc: Background sort failed, using local sort: $error',
      );
      final sorted = List<StudentModel>.of(students);
      sorted.sort(_compareStudentsByName);
      return sorted;
    }
  }

  StudentModel? _getCachedStudentById(String docId) {
    return _studentsByDocId[docId];
  }

  Future<void> _onLoadStudents(
    StudentsLoadRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    final currentStudents = state is StudentDataLoaded
        ? (state as StudentDataLoaded).students
        : <StudentModel>[];
    emit(StudentDataLoading(previousStudents: currentStudents));
    _lastFilterGroupId = event.actor.groupId;
    _lastFilterTeamId = event.teamId;
    _lastQuery = null;

    await _subscribeToStudents(actor: event.actor, teamId: event.teamId);
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

    final currentStudents = state is StudentDataLoaded
        ? (state as StudentDataLoaded).students
        : <StudentModel>[];
    emit(StudentDataLoading(previousStudents: currentStudents));
    try {
      final results = await _studentRepository.searchStudents(query);
      emit(
        StudentDataLoaded(
          students: results,
          currentFilterGroupId: _lastFilterGroupId,
          currentFilterTeamId: _lastFilterTeamId,
          currentQuery: query,
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
      
      // Refresh the stream to update UI with new data
      await _subscribeToStudents(actor: event.actor, teamId: _lastFilterTeamId);
      
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
      
      // Refresh the stream to update UI with updated data
      await _subscribeToStudents(actor: event.actor, teamId: _lastFilterTeamId);
      
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
      
      // Refresh the stream to update UI after deletion
      final actor = _authService.currentUser;
      if (actor != null) {
        await _subscribeToStudents(actor: actor, teamId: _lastFilterTeamId);
      }
      
      emit(const StudentDataOperationSuccess('Student deleted successfully'));
    } catch (e) {
      _emitError(emit, 'Unable to delete student', e);
    }
  }

  Future<void> _onFormSubmitted(
    StudentFormSubmitted event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      if (event.isEditing) {
        final existing = event.existingStudent;
        if (existing == null) {
          emit(const StudentDataError('Student not found.'));
          return;
        }
        if (!_canMutateStudent(event.actor, existing)) {
          emit(const StudentDataError('Not allowed.'));
          return;
        }

        final isRoleChange = existing.role != event.role;
        if (isRoleChange && event.actor.role != UserRole.admin) {
          emit(const StudentDataError('Not allowed.'));
          return;
        }
        if (isRoleChange &&
            event.role == UserRole.servant &&
            existing.uid.trim().isEmpty) {
          emit(
            const StudentDataError(
              'Cannot promote student without linked user account.',
            ),
          );
          return;
        }

        final student = StudentModel(
          uid: existing.uid,
          docID: existing.docID,
          name: event.name,
          imageUrl: event.imageUrl,
          role: event.role,
          mobile: event.mobile,
          group: event.group,
          teamName: event.teamName ?? '',
          motherPhone: event.motherPhone,
          fatherPhone: event.fatherPhone,
          grade: event.grade,
          educationStage: event.educationStage,
          school: event.school,
          address: event.address,
          birthdate: event.birthdate,
          fatherOfConfession: event.fatherOfConfession,
          notes: event.notes,
          classId: event.teamId,
        );

        if (isRoleChange) {
          await _studentRepository.updateStudentAndSyncLinkedUserRole(
            updatedStudent: student,
            previousRole: existing.role,
          );
        } else {
          await _studentRepository.updateStudent(student);
        }
        
        // Refresh the stream to update UI with updated data
        await _subscribeToStudents(actor: event.actor, teamId: _lastFilterTeamId);
        
        emit(const StudentDataOperationSuccess('Student updated successfully'));
      } else {
        var studentToCreate = StudentModel(
          uid: '',
          docID: '',
          name: event.name,
          imageUrl: event.imageUrl,
          role: event.role,
          mobile: event.mobile,
          group: event.group,
          teamName: event.teamName ?? '',
          motherPhone: event.motherPhone,
          fatherPhone: event.fatherPhone,
          grade: event.grade,
          educationStage: event.educationStage,
          school: event.school,
          address: event.address,
          birthdate: event.birthdate,
          fatherOfConfession: event.fatherOfConfession,
          notes: event.notes,
          classId: event.teamId,
        );

        if (!_canMutateStudent(event.actor, studentToCreate)) {
          emit(const StudentDataError('Not allowed.'));
          return;
        }

        if (event.email != null &&
            event.email!.isNotEmpty &&
            event.password != null &&
            event.password!.isNotEmpty) {
          final authUser = await _authService.createUserAsAdmin(
            email: event.email!,
            password: event.password!,
            name: event.name,
            role: event.role,
          );
          studentToCreate = studentToCreate.copyWith(
            uid: authUser.uid,
            docID: authUser.uid,
          );
        }

        await _studentRepository.createStudent(studentToCreate);
        
        // Refresh the stream to update UI with new data
        await _subscribeToStudents(actor: event.actor, teamId: _lastFilterTeamId);
        
        emit(const StudentDataOperationSuccess('Student created successfully'));
      }
    } catch (e) {
      _emitError(emit, 'Unable to save student', e);
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

List<String> _sortStudentIdsByName(List<List<String>> rows) {
  rows.sort((a, b) {
    final nameCompare = a[1].compareTo(b[1]);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return a[0].compareTo(b[0]);
  });
  return [for (final row in rows) row[0]];
}
