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
    String? successMessage,
  }) {
    emit(
      StudentDataLoaded(
        students: students,
        currentFilterGroupId: _lastFilterGroupId,
        currentFilterTeamId: _lastFilterTeamId,
        currentQuery: query,
        successMessage: successMessage,
      ),
    );
  }

  /// Emits the current loaded state with an attached success message.
  /// Falls back to emitting [StudentDataOperationSuccess] if no data is loaded.
  void _emitSuccessWithData(Emitter<StudentDataState> emit, String message) {
    final students = _resolveVisibleStudents(_lastQuery);
    _emitLoadedState(
      emit,
      students: students,
      query: _lastQuery,
      successMessage: message,
    );
  }

  bool _canCreateAuthAccount(StudentCreated event) {
    return event.email != null &&
        event.email!.isNotEmpty &&
        event.password != null &&
        event.password!.isNotEmpty;
  }

  Future<AuthUser?> _createLinkedAuthUser(StudentCreated event) async {
    if (!_canCreateAuthAccount(event)) {
      return null;
    }

    return _authService.createUserAsAdmin(
      email: event.email!,
      password: event.password!,
      name: event.student.name,
      role: event.student.role,
    );
  }

  Future<void> _rollbackLinkedAuthUser(
    StudentCreated event,
    AuthUser authUser,
  ) async {
    if (!_canCreateAuthAccount(event)) {
      return;
    }

    await _authService.rollbackAdminCreatedUser(
      uid: authUser.uid,
      email: event.email!,
      password: event.password!,
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
    emit(const StudentDataLoading());
    _setCurrentFilters(groupId: event.actor.groupId, teamId: event.teamId);

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
    final students = _resolveVisibleStudents(query);
    _emitLoadedState(emit, students: students, query: query);
  }

  void _onStreamError(_StreamError event, Emitter<StudentDataState> emit) {
    emit(StudentDataError(event.message));
  }

  Future<void> _onSearchStudents(
    StudentsSearchRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    final query = event.query.trim();
    _setCurrentFilters(
      groupId: _lastFilterGroupId,
      teamId: _lastFilterTeamId,
      query: query,
    );

    final students = _resolveVisibleStudents(query);
    _emitLoadedState(emit, students: students, query: query);
  }

  Future<void> _onCreateStudent(
    StudentCreated event,
    Emitter<StudentDataState> emit,
  ) async {
    AuthUser? createdAuthUser;
    try {
      if (!_canMutateStudent(event.actor, event.student)) {
        _emitNotAllowed(emit);
        return;
      }

      createdAuthUser = await _createLinkedAuthUser(event);
      final studentToCreate = createdAuthUser == null
          ? event.student
          : event.student.copyWith(
              uid: createdAuthUser.uid,
              docID: createdAuthUser.uid,
            );

      await _studentRepository.createStudent(studentToCreate);
      _emitSuccessWithData(emit, 'تم إنشاء المخدوم بنجاح');
    } catch (e) {
      if (createdAuthUser != null) {
        try {
          await _rollbackLinkedAuthUser(event, createdAuthUser);
        } catch (rollbackError) {
          _emitError(
            emit,
            'تعذر إنشاء المخدوم، كما فشلت إعادة التراجع عن الحساب المرتبط',
            rollbackError,
          );
          return;
        }
      }
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

      if (isRoleChange) {
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
      await _studentRepository.deleteStudent(event.docId);
      _emitSuccessWithData(emit, 'تم حذف المخدوم بنجاح');
    } catch (e) {
      _emitError(emit, 'تعذر حذف المخدوم', e);
    }
  }

  Future<void> _onRefreshStudents(
    StudentsRefreshRequested event,
    Emitter<StudentDataState> emit,
  ) async {
    emit(const StudentDataLoading());
    _setCurrentFilters(
      groupId: event.actor.groupId,
      teamId: _lastFilterTeamId,
      query: _lastQuery,
    );
    await _subscribeToStudents(actor: event.actor, teamId: _lastFilterTeamId);
  }

  Future<void> _onStopListening(
    StudentsListeningStopped event,
    Emitter<StudentDataState> emit,
  ) async {
    await _cancelStudentsSubscription();
    _allStudents = const [];
    _setCurrentFilters();
    emit(const StudentDataInitial());
  }

  @override
  Future<void> close() async {
    await _cancelStudentsSubscription();
    return super.close();
  }
}
