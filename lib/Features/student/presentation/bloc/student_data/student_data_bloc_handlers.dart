part of 'student_data_bloc.dart';

extension StudentDataBlocActions on StudentDataBloc {
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
}

Future<void> _cancelStudentsSubscription(StudentDataBloc bloc) async {
  final subscription = bloc._studentsSubscription;
  bloc._studentsSubscription = null;
  await subscription?.cancel();
}

void _completePendingRefresh(StudentDataBloc bloc) {
  final completer = bloc._pendingRefreshCompleter;
  if (completer?.isCompleted == false) completer!.complete();
  bloc._pendingRefreshCompleter = null;
}

Future<void> _subscribeToStudents(
  StudentDataBloc bloc, {
  required AuthUser actor,
  String? teamId,
  bool includeArchived = false,
}) async {
  await _cancelStudentsSubscription(bloc);

  final stream = bloc._getStudentsUseCase.watch(
    actor: actor,
    teamId: teamId,
    includeArchived: includeArchived,
  );
  if (stream == null) {
    bloc.add(const _StudentsStreamUpdated([]));
    return;
  }

  bloc._studentsSubscription = stream.listen(
    (students) {
      if (bloc.isClosed) return;
      students.sort((a, b) => a.name.compareTo(b.name));
      bloc.add(_StudentsStreamUpdated(students));
    },
    onError: (Object error) {
      if (bloc.isClosed) return;
      if (kDebugMode) {
        debugPrint('StudentDataBloc: Stream error (${error.runtimeType})');
      }
      bloc.add(_StreamError('$error'));
    },
  );
}

void _setCurrentFilters(
  StudentDataBloc bloc, {
  String? groupId,
  String? teamId,
  String? query,
}) {
  bloc._lastFilterGroupId = groupId;
  bloc._lastFilterTeamId = teamId;
  bloc._lastQuery = query;
}

List<StudentModel> _resolveVisibleStudents(
  StudentDataBloc bloc,
  String? query,
) {
  if (query?.isNotEmpty == true) {
    return bloc._searchStudentsUseCase(
      students: bloc._allStudents,
      query: query!,
    );
  }
  return bloc._allStudents;
}

void _emitLoadedState(
  StudentDataBloc bloc,
  Emitter<StudentDataState> emit, {
  required List<StudentModel> students,
  String? query,
  StudentMutationStatus mutationStatus = StudentMutationStatus.idle,
  String? successMessage,
}) {
  emit(
    StudentDataLoaded(
      students: students,
      currentFilterGroupId: bloc._lastFilterGroupId,
      currentFilterTeamId: bloc._lastFilterTeamId,
      currentQuery: query,
      includeArchived: bloc._includeArchived,
      mutationStatus: mutationStatus,
      successMessage: successMessage,
    ),
  );
}

void _emitSuccessWithData(
  StudentDataBloc bloc,
  Emitter<StudentDataState> emit,
  String message,
) {
  _emitLoadedState(
    bloc,
    emit,
    students: _resolveVisibleStudents(bloc, bloc._lastQuery),
    query: bloc._lastQuery,
    mutationStatus: StudentMutationStatus.success,
    successMessage: message,
  );
}

void _emitError(Emitter<StudentDataState> emit, String message, Object error) {
  if (error is StudentOperationException) {
    emit(StudentDataError(error.message));
    return;
  }
  if (kDebugMode) {
    debugPrint('StudentDataBloc: $message (${error.runtimeType})');
  }
  emit(StudentDataError('$message. حاول مرة أخرى.'));
}

Future<void> _handleLoadStudents(
  StudentDataBloc bloc,
  StudentsLoadRequested event,
  Emitter<StudentDataState> emit,
) async {
  emit(
    StudentDataLoading(
      previousStudents: _resolveVisibleStudents(bloc, bloc._lastQuery),
      isRefresh: bloc._allStudents.isNotEmpty,
      includeArchived: event.includeArchived,
    ),
  );
  _setCurrentFilters(bloc, groupId: event.actor.groupId, teamId: event.teamId);
  bloc._includeArchived = event.includeArchived;
  await _subscribeToStudents(
    bloc,
    actor: event.actor,
    teamId: event.teamId,
    includeArchived: event.includeArchived,
  );
}

void _handleStreamUpdated(
  StudentDataBloc bloc,
  _StudentsStreamUpdated event,
  Emitter<StudentDataState> emit,
) {
  bloc._allStudents = event.students
      .where((student) => student.role == UserRole.student)
      .toList(growable: false);
  _emitLoadedState(
    bloc,
    emit,
    students: _resolveVisibleStudents(bloc, bloc._lastQuery),
    query: bloc._lastQuery,
  );
  _completePendingRefresh(bloc);
}

void _handleStreamError(
  StudentDataBloc bloc,
  _StreamError event,
  Emitter<StudentDataState> emit,
) {
  emit(StudentDataError(event.message));
  _completePendingRefresh(bloc);
}

Future<void> _handleSearchStudents(
  StudentDataBloc bloc,
  StudentsSearchRequested event,
  Emitter<StudentDataState> emit,
) async {
  final query = event.query.trim();
  final previousQuery = bloc._lastQuery;
  final previousTeamId = bloc._lastFilterTeamId;
  final previousIncludeArchived = bloc._includeArchived;
  final nextTeamId = event.teamId;
  bloc._includeArchived = event.includeArchived;
  _setCurrentFilters(
    bloc,
    groupId: event.actor.groupId,
    teamId: nextTeamId,
    query: query,
  );

  if (previousTeamId != nextTeamId ||
      previousIncludeArchived != event.includeArchived) {
    emit(
      StudentDataLoading(
        previousStudents: _resolveVisibleStudents(bloc, previousQuery),
        isRefresh: bloc._allStudents.isNotEmpty,
        includeArchived: event.includeArchived,
      ),
    );
    await _subscribeToStudents(
      bloc,
      actor: event.actor,
      teamId: nextTeamId,
      includeArchived: event.includeArchived,
    );
    return;
  }

  _emitLoadedState(
    bloc,
    emit,
    students: _resolveVisibleStudents(bloc, query),
    query: query,
  );
}

Future<void> _handleCreateStudent(
  StudentDataBloc bloc,
  StudentCreated event,
  Emitter<StudentDataState> emit,
) async {
  try {
    await bloc._addStudentUseCase(
      actor: event.actor,
      student: event.student,
      email: event.email,
      password: event.password,
    );
    _emitSuccessWithData(bloc, emit, 'تم إنشاء المخدوم بنجاح');
  } catch (error) {
    _emitError(emit, 'تعذر إنشاء المخدوم', error);
  }
}

Future<void> _handleUpdateStudent(
  StudentDataBloc bloc,
  StudentUpdated event,
  Emitter<StudentDataState> emit,
) async {
  try {
    await bloc._updateStudentUseCase(
      actor: event.actor,
      updatedStudent: event.student,
    );
    _emitSuccessWithData(bloc, emit, 'تم تحديث بيانات المخدوم بنجاح');
  } catch (error) {
    _emitError(emit, 'تعذر تحديث بيانات المخدوم', error);
  }
}

Future<void> _handleDeleteStudent(
  StudentDataBloc bloc,
  StudentDeleted event,
  Emitter<StudentDataState> emit,
) async {
  try {
    await bloc._deleteStudentUseCase(actor: event.actor, docId: event.docId);
    _emitSuccessWithData(bloc, emit, 'تمت أرشفة المخدوم بنجاح');
  } catch (error) {
    _emitError(emit, 'تعذر أرشفة المخدوم', error);
  }
}

Future<void> _handleRestoreStudent(
  StudentDataBloc bloc,
  StudentRestored event,
  Emitter<StudentDataState> emit,
) async {
  try {
    await bloc._restoreStudentUseCase(actor: event.actor, docId: event.docId);
    _emitSuccessWithData(bloc, emit, 'تمت استعادة المخدوم بنجاح');
  } catch (error) {
    _emitError(emit, 'تعذر استعادة المخدوم', error);
  }
}

Future<void> _handleRefreshStudents(
  StudentDataBloc bloc,
  StudentsRefreshRequested event,
  Emitter<StudentDataState> emit,
) async {
  emit(
    StudentDataLoading(
      previousStudents: _resolveVisibleStudents(bloc, bloc._lastQuery),
      isRefresh: bloc._allStudents.isNotEmpty,
      includeArchived: event.includeArchived,
    ),
  );
  _setCurrentFilters(
    bloc,
    groupId: event.actor.groupId,
    teamId: bloc._lastFilterTeamId,
    query: bloc._lastQuery,
  );
  bloc._includeArchived = event.includeArchived;
  await _subscribeToStudents(
    bloc,
    actor: event.actor,
    teamId: bloc._lastFilterTeamId,
    includeArchived: event.includeArchived,
  );
}

Future<void> _handleStopListening(
  StudentDataBloc bloc,
  StudentsListeningStopped event,
  Emitter<StudentDataState> emit,
) async {
  await _cancelStudentsSubscription(bloc);
  bloc._allStudents = const [];
  _setCurrentFilters(bloc);
  bloc._includeArchived = false;
  emit(const StudentDataInitial());
  _completePendingRefresh(bloc);
}
