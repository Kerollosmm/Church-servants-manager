import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
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
  final IStudentRepository _studentRepository;
  final GetStudentsStreamUseCase _getStudentsStream;
  final CanMutateStudentUseCase _canMutateStudent;
  final ProvisionStudentWithAuthUseCase _provisionUseCase;

  StreamSubscription<List<StudentModel>>? _studentsSubscription;
  Completer<void>? _pendingRefreshCompleter;
  List<StudentModel> _allStudents = [];
  Map<String, StudentModel> _studentsByDocId = {};
  String? _lastFilterGroupId;
  String? _lastFilterTeamId;
  String? _lastQuery;
  bool _includeArchived = false;

  StudentDataBloc({
    required IStudentRepository studentRepository,
    required GetStudentsStreamUseCase getStudentsStream,
    required CanMutateStudentUseCase canMutateStudent,
    required ProvisionStudentWithAuthUseCase provisionUseCase,
  }) : _studentRepository = studentRepository,
       _getStudentsStream = getStudentsStream,
       _canMutateStudent = canMutateStudent,
       _provisionUseCase = provisionUseCase,
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
  }

  Future<void> _cancelStudentsSubscription() async {
    final subscription = _studentsSubscription;
    _studentsSubscription = null;
    await subscription?.cancel();
  }

  Future<void> refresh(AuthUser actor) {
    final existingCompleter = _pendingRefreshCompleter;
    if (existingCompleter != null && !existingCompleter.isCompleted) {
      return existingCompleter.future;
    }

    final completer = Completer<void>();
    _pendingRefreshCompleter = completer;
    add(
      StudentsRefreshRequested(actor: actor, includeArchived: _includeArchived),
    );
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
    );
  }

  void _completePendingRefresh() {
    final completer = _pendingRefreshCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _pendingRefreshCompleter = null;
  }

  /// Subscribes to the stream returned by the use case.
  Future<void> _subscribeToStudents({
    required AuthUser actor,
    String? teamId,
    bool includeArchived = false,
  }) async {
    await _cancelStudentsSubscription();

    final stream = _getStudentsStream(
      actor: actor,
      teamId: teamId,
      includeArchived: includeArchived,
    );

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
        if (kDebugMode) {
          debugPrint('StudentDataBloc: Stream error (${error.runtimeType})');
        }
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

  void _setCurrentFilters({String? groupId, String? teamId, String? query}) {
    _lastFilterGroupId = groupId;
    _lastFilterTeamId = teamId;
    _lastQuery = query;
  }

  List<StudentModel> _resolveVisibleStudents(String? query) {
    if (query != null && query.isNotEmpty) {
      return _filterByName(_allStudents, query);
    }
    return _allStudents;
  }

  void _emitLoadedState(
    Emitter<StudentDataState> emit, {
    required List<StudentModel> students,
    String? query,
    StudentMutationStatus mutationStatus = StudentMutationStatus.idle,
    StudentMutationOperation? mutationOperation,
    String? successMessage,
  }) {
    emit(
      StudentDataLoaded(
        students: students,
        currentFilterGroupId: _lastFilterGroupId,
        currentFilterTeamId: _lastFilterTeamId,
        currentQuery: query,
        includeArchived: _includeArchived,
        mutationStatus: mutationStatus,
        mutationOperation: mutationOperation,
        successMessage: successMessage,
      ),
    );
  }

  void _emitSuccessWithData(
    Emitter<StudentDataState> emit,
    String message, {
    StudentMutationOperation? mutationOperation,
  }) {
    final students = _resolveVisibleStudents(_lastQuery);
    _emitLoadedState(
      emit,
      students: students,
      query: _lastQuery,
      mutationStatus: StudentMutationStatus.success,
      mutationOperation: mutationOperation,
      successMessage: message,
    );
  }

  Future<StudentModel?> _resolveExistingStudent(String docId) async {
    return _getCachedStudentById(docId) ??
        await _studentRepository.getStudentById(docId);
  }

  void _emitError(
    Emitter<StudentDataState> emit,
    String message,
    Object error,
  ) {
    if (kDebugMode) {
      debugPrint('StudentDataBloc: $message (${error.runtimeType})');
    }
    emit(StudentDataError('$message. حاول مرة أخرى.'));
  }

  void _emitNotAllowed(Emitter<StudentDataState> emit) {
    emit(const StudentDataError('غير مسموح.'));
  }

  bool _isRoleChangeRestricted({
    required AuthUser actor,
    required StudentModel existing,
    required StudentModel updated,
  }) {
    final isRoleChange = existing.role != updated.role;
    if (!isRoleChange) {
      return false;
    }
    return actor.role != UserRole.admin;
  }

  bool _isInvalidServantPromotion({
    required StudentModel existing,
    required StudentModel updated,
  }) {
    final isRoleChange = existing.role != updated.role;
    if (!isRoleChange) {
      return false;
    }
    return updated.role == UserRole.servant && updated.uid.trim().isEmpty;
  }

  StudentModel? _getCachedStudentById(String docId) {
    return _studentsByDocId[docId];
  }

  Future<void> _onLoadStudents(
    StudentsLoadRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(
      StudentDataLoading(
        previousStudents: _resolveVisibleStudents(_lastQuery),
        isRefresh: _allStudents.isNotEmpty,
        includeArchived: event.includeArchived,
      ),
    );
    _setCurrentFilters(groupId: event.actor.groupId, teamId: event.teamId);
    _includeArchived = event.includeArchived;

    await _subscribeToStudents(
      actor: event.actor,
      teamId: event.teamId,
      includeArchived: event.includeArchived,
    );
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
    final students = _resolveVisibleStudents(query);
    _emitLoadedState(emit, students: students, query: query);
    _completePendingRefresh();
  }

  void _onStreamError(_StreamError event, Emitter<StudentDataState> emit) {
    emit(StudentDataError(event.message));
    _completePendingRefresh();
  }

  Future<void> _onSearchStudents(
    StudentsSearchRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    final query = event.query.trim();
    final previousQuery = _lastQuery;
    final previousTeamId = _lastFilterTeamId;
    final previousIncludeArchived = _includeArchived;
    final nextTeamId = event.teamId;
    _includeArchived = event.includeArchived;
    _setCurrentFilters(
      groupId: event.actor.groupId,
      teamId: nextTeamId,
      query: query,
    );

    if (query.isNotEmpty) {
      await _cancelStudentsSubscription();
      emit(
        StudentDataLoading(
          previousStudents: _resolveVisibleStudents(previousQuery),
          isRefresh: _allStudents.isNotEmpty,
          includeArchived: event.includeArchived,
        ),
      );
      try {
        final students = await _studentRepository.searchStudents(
          query,
          limit: 20,
        );
        final filtered = nextTeamId != null && nextTeamId.isNotEmpty
            ? students.where((s) => s.classId == nextTeamId).toList()
            : students;
        _emitLoadedState(emit, students: filtered, query: query);
      } catch (e) {
        _emitError(emit, 'تعذر البحث عن المخدومين', e);
      }
      return;
    }

    if (previousTeamId != nextTeamId ||
        previousIncludeArchived != event.includeArchived) {
      emit(
        StudentDataLoading(
          previousStudents: _resolveVisibleStudents(previousQuery),
          isRefresh: _allStudents.isNotEmpty,
          includeArchived: event.includeArchived,
        ),
      );
      if (event.actor.role == UserRole.admin &&
          (nextTeamId == null || nextTeamId.isEmpty)) {
        await _cancelStudentsSubscription();
        try {
          final students = await _studentRepository.getAllStudents(
            limit: 50,
            includeArchived: event.includeArchived,
          );
          _allStudents = students
              .where((student) => student.role == UserRole.student)
              .toList(growable: false);
          _studentsByDocId = {for (final s in _allStudents) s.docID: s};
          _emitLoadedState(
            emit,
            students: _resolveVisibleStudents(query),
            query: query,
          );
        } catch (e) {
          _emitError(emit, 'تعذر تحميل بيانات المخدومين', e);
        }
      } else {
        await _subscribeToStudents(
          actor: event.actor,
          teamId: nextTeamId,
          includeArchived: event.includeArchived,
        );
      }
      return;
    }

    final students = _resolveVisibleStudents(query);
    _emitLoadedState(emit, students: students, query: query);
  }

  Future<void> _onCreateStudent(
    StudentCreated event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      if (!_canMutateStudent(event.actor, event.student)) {
        _emitNotAllowed(emit);
        return;
      }

      await _provisionUseCase(
        student: event.student,
        email: event.email,
        password: event.password,
      );

      _emitSuccessWithData(emit, 'تم إنشاء المخدوم بنجاح');
    } catch (e) {
      _emitError(emit, 'تعذر إنشاء المخدوم', e);
    }
  }

  Future<void> _onUpdateStudent(
    StudentUpdated event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      final existing = await _resolveExistingStudent(event.student.docID);
      if (existing == null) {
        emit(const StudentDataError('لم يتم العثور على المخدوم.'));
        return;
      }
      if (!_canMutateStudent(event.actor, existing)) {
        _emitNotAllowed(emit);
        return;
      }

      final isRoleChange = existing.role != event.student.role;
      if (_isRoleChangeRestricted(
        actor: event.actor,
        existing: existing,
        updated: event.student,
      )) {
        _emitNotAllowed(emit);
        return;
      }
      if (_isInvalidServantPromotion(
        existing: existing,
        updated: event.student,
      )) {
        emit(
          const StudentDataError(
            'لا يمكن ترقية المخدوم بدون حساب مستخدم مرتبط.',
          ),
        );
        return;
      }

      final uid = event.student.uid.trim();
      final hasLinkedUser = uid.isNotEmpty;

      if (isRoleChange || hasLinkedUser) {
        await _studentRepository.updateStudentAndSyncLinkedUserRole(
          updatedStudent: event.student,
          previousRole: existing.role,
        );
      } else {
        await _studentRepository.updateStudent(event.student);
      }
      _emitSuccessWithData(emit, 'تم تحديث بيانات المخدوم بنجاح');
    } catch (e) {
      _emitError(emit, 'تعذر تحديث بيانات المخدوم', e);
    }
  }

  Future<void> _onDeleteStudent(
    StudentDeleted event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      final existing = await _resolveExistingStudent(event.docId);
      if (existing == null) {
        emit(const StudentDataError('لم يتم العثور على المخدوم.'));
        return;
      }
      if (!_canMutateStudent(event.actor, existing)) {
        _emitNotAllowed(emit);
        return;
      }

      await _provisionUseCase.archive(
        docId: event.docId,
        performedByUid: event.actor.uid,
        linkedUid: existing.uid,
      );

      _emitSuccessWithData(
        emit,
        'تمت أرشفة المخدوم بنجاح',
        mutationOperation: StudentMutationOperation.archive,
      );
    } catch (e) {
      _emitError(emit, 'تعذر أرشفة المخدوم', e);
    }
  }

  Future<void> _onRestoreStudent(
    StudentRestored event,
    Emitter<StudentDataState> emit,
  ) async {
    try {
      final existing = await _studentRepository.getStudentById(
        event.docId,
        includeArchived: true,
      );
      if (existing == null) {
        emit(const StudentDataError('لم يتم العثور على المخدوم.'));
        return;
      }
      if (event.actor.role != UserRole.admin) {
        _emitNotAllowed(emit);
        return;
      }

      await _provisionUseCase.restore(
        docId: event.docId,
        performedByUid: event.actor.uid,
        linkedUid: existing.uid,
      );

      _emitSuccessWithData(
        emit,
        'تمت استعادة المخدوم بنجاح',
        mutationOperation: StudentMutationOperation.restore,
      );
    } catch (e) {
      _emitError(emit, 'تعذر استعادة المخدوم', e);
    }
  }

  Future<void> _onRefreshStudents(
    StudentsRefreshRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(
      StudentDataLoading(
        previousStudents: _resolveVisibleStudents(_lastQuery),
        isRefresh: _allStudents.isNotEmpty,
        includeArchived: event.includeArchived,
      ),
    );
    _setCurrentFilters(
      groupId: event.actor.groupId,
      teamId: _lastFilterTeamId,
      query: _lastQuery,
    );
    _includeArchived = event.includeArchived;
    await _subscribeToStudents(
      actor: event.actor,
      teamId: _lastFilterTeamId,
      includeArchived: event.includeArchived,
    );
  }

  Future<void> _onStopListening(
    StudentsListeningStopped event,
    Emitter<StudentDataState> emit,
  ) async {
    await _cancelStudentsSubscription();
    _allStudents = const [];
    _setCurrentFilters();
    _includeArchived = false;
    emit(const StudentDataInitial());
    _completePendingRefresh();
  }

  @override
  Future<void> close() async {
    await _cancelStudentsSubscription();
    _completePendingRefresh();
    return super.close();
  }
}
