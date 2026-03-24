import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/usecases/add_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/delete_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/restore_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/search_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/student_operation_exception.dart';
import 'package:church_management_system/features/student/domain/usecases/update_student_usecase.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_data_event.dart';
part 'student_data_state.dart';
part 'student_data_bloc_handlers.dart';

/// BLoC for managing student data with role-based filtering.
class StudentDataBloc extends Bloc<StudentDataEvent, StudentDataState> {
  // FIX [P1]: delegate student loading/search/CRUD logic to dedicated use cases.
  // FIX [007]: All use case parameters are now required; fallback constructors
  // removed so all dependencies must be explicitly wired by the DI container.
  StudentDataBloc({
    required GetStudentsUseCase getStudentsUseCase,
    required SearchStudentsUseCase searchStudentsUseCase,
    required AddStudentUseCase addStudentUseCase,
    required UpdateStudentUseCase updateStudentUseCase,
    required DeleteStudentUseCase deleteStudentUseCase,
    required RestoreStudentUseCase restoreStudentUseCase,
  }) : _getStudentsUseCase = getStudentsUseCase,
       _searchStudentsUseCase = searchStudentsUseCase,
       _addStudentUseCase = addStudentUseCase,
       _updateStudentUseCase = updateStudentUseCase,
       _deleteStudentUseCase = deleteStudentUseCase,
       _restoreStudentUseCase = restoreStudentUseCase,
       super(const StudentDataInitial()) {
    on<StudentsLoadRequested>(_onLoadStudents);
    on<StudentsSearchRequested>(_onSearchStudents);
    on<StudentCreated>(_onCreateStudent);
    on<StudentUpdated>(_onUpdateStudent);
    on<StudentDeleted>(_onDeleteStudent);
    on<StudentRestored>(_onRestoreStudent);
    on<StudentsRefreshRequested>(_onRefreshStudents);
    on<StudentsListeningStopped>(_onStopListening);
    on<_StudentsStreamUpdated>(_onStreamUpdated);
    on<_StreamError>(_onStreamError);
    on<StudentsLoadMoreRequested>(
      _onLoadMoreStudents,
    ); // FIX [008]: pagination (T008)
  }

  final GetStudentsUseCase _getStudentsUseCase;
  final SearchStudentsUseCase _searchStudentsUseCase;
  final AddStudentUseCase _addStudentUseCase;
  final UpdateStudentUseCase _updateStudentUseCase;
  final DeleteStudentUseCase _deleteStudentUseCase;
  final RestoreStudentUseCase _restoreStudentUseCase;

  StreamSubscription<List<StudentModel>>? _studentsSubscription;
  Completer<void>? _pendingRefreshCompleter;
  List<StudentModel> _allStudents = [];
  String? _lastFilterGroupId;
  String? _lastFilterTeamId;
  String? _lastQuery;
  bool _includeArchived = false;
  // FIX [009-P3]: keep load-more state isolated from the live student stream.
  int _pageOffset = 0;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  Future<void> _onLoadStudents(
    StudentsLoadRequested event,
    Emitter<StudentDataState> emit,
  ) => _handleLoadStudents(this, event, emit);

  Future<void> _onSearchStudents(
    StudentsSearchRequested event,
    Emitter<StudentDataState> emit,
  ) => _handleSearchStudents(this, event, emit);

  Future<void> _onCreateStudent(
    StudentCreated event,
    Emitter<StudentDataState> emit,
  ) => _handleCreateStudent(this, event, emit);

  Future<void> _onUpdateStudent(
    StudentUpdated event,
    Emitter<StudentDataState> emit,
  ) => _handleUpdateStudent(this, event, emit);

  Future<void> _onDeleteStudent(
    StudentDeleted event,
    Emitter<StudentDataState> emit,
  ) => _handleDeleteStudent(this, event, emit);

  Future<void> _onRestoreStudent(
    StudentRestored event,
    Emitter<StudentDataState> emit,
  ) => _handleRestoreStudent(this, event, emit);

  Future<void> _onRefreshStudents(
    StudentsRefreshRequested event,
    Emitter<StudentDataState> emit,
  ) => _handleRefreshStudents(this, event, emit);

  Future<void> _onStopListening(
    StudentsListeningStopped event,
    Emitter<StudentDataState> emit,
  ) => _handleStopListening(this, event, emit);

  void _onStreamUpdated(
    _StudentsStreamUpdated event,
    Emitter<StudentDataState> emit,
  ) => _handleStreamUpdated(this, event, emit);

  void _onStreamError(_StreamError event, Emitter<StudentDataState> emit) =>
      _handleStreamError(this, event, emit);

  // FIX [009-P4]: load-more remains event-driven, but uses scope-safe paging.
  Future<void> _onLoadMoreStudents(
    StudentsLoadMoreRequested event,
    Emitter<StudentDataState> emit,
  ) => _handleLoadMoreStudents(this, event, emit);

  @override
  Future<void> close() async {
    await _cancelStudentsSubscription(this);
    _completePendingRefresh(this);
    return super.close();
  }
}
