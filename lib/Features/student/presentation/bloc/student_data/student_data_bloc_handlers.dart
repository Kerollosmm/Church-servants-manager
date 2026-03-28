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

void _resetPagination(StudentDataBloc bloc) {
  bloc._lastDocument = null;
  bloc._hasReachedMax = false;
  bloc._isLoadingMore = false;
}

List<StudentModel> _currentVisibleStudents(
  StudentDataBloc bloc,
  StudentDataLoaded? current,
) {
  if (current == null) {
    return bloc._allStudents;
  }

  if (current.currentQuery?.isNotEmpty == true) {
    return current.students;
  }

  final loadedCount = current.students.length;
  if (loadedCount <= 0) {
    return const <StudentModel>[];
  }

  if (bloc._allStudents.length <= loadedCount) {
    return bloc._allStudents;
  }

  return bloc._allStudents.take(loadedCount).toList(growable: false);
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
      lastDocument: bloc._lastDocument,
      currentFilterGroupId: bloc._lastFilterGroupId,
      currentFilterTeamId: bloc._lastFilterTeamId,
      currentQuery: query,
      includeArchived: bloc._includeArchived,
      mutationStatus: mutationStatus,
      successMessage: successMessage,
      isLoadingMore: bloc._isLoadingMore,
      hasReachedMax: bloc._hasReachedMax,
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
    students: _currentVisibleStudents(
      bloc,
      bloc.state is StudentDataLoaded ? bloc.state as StudentDataLoaded : null,
    ),
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
      previousStudents: bloc._allStudents,
      isRefresh: bloc._allStudents.isNotEmpty,
      includeArchived: event.includeArchived,
    ),
  );
  _setCurrentFilters(bloc, groupId: event.actor.groupId, teamId: event.teamId);
  bloc._includeArchived = event.includeArchived;
  bloc._pageSize = event.limit <= 0 ? 20 : event.limit;
  _resetPagination(bloc);
  bloc._allStudents = const <StudentModel>[];
  await _subscribeToStudents(
    bloc,
    actor: event.actor,
    teamId: event.teamId,
    includeArchived: event.includeArchived,
  );
  final page = await bloc._getStudentsUseCase.fetchPage(
    actor: event.actor,
    limit: bloc._pageSize,
    teamId: event.teamId,
    includeArchived: event.includeArchived,
  );
  bloc._allStudents = page.students;
  bloc._lastDocument = page.lastDocument;
  bloc._hasReachedMax = page.hasReachedMax;
  _emitLoadedState(bloc, emit, students: page.students, query: bloc._lastQuery);
  _completePendingRefresh(bloc);
}

void _handleStreamUpdated(
  StudentDataBloc bloc,
  _StudentsStreamUpdated event,
  Emitter<StudentDataState> emit,
) {
  bloc._allStudents = event.students
      .where((student) => student.role == UserRole.student)
      .toList(growable: false);
  final current = bloc.state is StudentDataLoaded
      ? bloc.state as StudentDataLoaded
      : null;
  final currentQuery = current?.currentQuery ?? bloc._lastQuery;

  if (currentQuery?.isNotEmpty == true) {
    _completePendingRefresh(bloc);
    return;
  }

  _emitLoadedState(
    bloc,
    emit,
    students: _currentVisibleStudents(bloc, current),
    query: currentQuery,
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
  final previousTeamId = bloc._lastFilterTeamId;
  final previousIncludeArchived = bloc._includeArchived;
  final nextTeamId = event.teamId;
  bloc._includeArchived = event.includeArchived;
  _setCurrentFilters(
    bloc,
    groupId: event.actor.groupId,
    teamId: nextTeamId,
    query: query.isEmpty ? null : query,
  );

  emit(
    StudentDataLoading(
      previousStudents: bloc._allStudents,
      isRefresh: bloc._allStudents.isNotEmpty,
      includeArchived: event.includeArchived,
    ),
  );

  if (previousTeamId != nextTeamId ||
      previousIncludeArchived != event.includeArchived) {
    _resetPagination(bloc);
    await _subscribeToStudents(
      bloc,
      actor: event.actor,
      teamId: nextTeamId,
      includeArchived: event.includeArchived,
    );
  }

  if (query.isEmpty) {
    bloc._lastQuery = null;
    bloc._allStudents = const <StudentModel>[];
    _resetPagination(bloc);
    final page = await bloc._getStudentsUseCase.fetchPage(
      actor: event.actor,
      limit: bloc._pageSize,
      teamId: nextTeamId,
      includeArchived: event.includeArchived,
    );
    bloc._allStudents = page.students;
    bloc._lastDocument = page.lastDocument;
    bloc._hasReachedMax = page.hasReachedMax;
    _emitLoadedState(
      bloc,
      emit,
      students: page.students,
      query: null,
    );
    return;
  }

  final results = await bloc._searchStudentsUseCase(
    actor: event.actor,
    query: query,
    limit: bloc._pageSize,
    teamId: nextTeamId,
    includeArchived: event.includeArchived,
  );
  bloc._allStudents = results;
  bloc._lastDocument = null;
  bloc._hasReachedMax = true;
  _emitLoadedState(
    bloc,
    emit,
    students: results,
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
      previousStudents: bloc._allStudents,
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
  _resetPagination(bloc);
  bloc._allStudents = const <StudentModel>[];
  await _subscribeToStudents(
    bloc,
    actor: event.actor,
    teamId: bloc._lastFilterTeamId,
    includeArchived: event.includeArchived,
  );

  if (bloc._lastQuery?.isNotEmpty == true) {
    final results = await bloc._searchStudentsUseCase(
      actor: event.actor,
      query: bloc._lastQuery!,
      limit: bloc._pageSize,
      teamId: bloc._lastFilterTeamId,
      includeArchived: event.includeArchived,
    );
    bloc._allStudents = results;
    bloc._lastDocument = null;
    bloc._hasReachedMax = true;
    _emitLoadedState(
      bloc,
      emit,
      students: results,
      query: bloc._lastQuery,
    );
    _completePendingRefresh(bloc);
    return;
  }

  final page = await bloc._getStudentsUseCase.fetchPage(
    actor: event.actor,
    limit: bloc._pageSize,
    teamId: bloc._lastFilterTeamId,
    includeArchived: event.includeArchived,
  );
  bloc._allStudents = page.students;
  bloc._lastDocument = page.lastDocument;
  bloc._hasReachedMax = page.hasReachedMax;
  _emitLoadedState(bloc, emit, students: page.students, query: bloc._lastQuery);
  _completePendingRefresh(bloc);
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
  _resetPagination(bloc);
  emit(const StudentDataInitial());
  _completePendingRefresh(bloc);
}

// FIX [008]: Cursor-based pagination handler appending the next page. (T008)
Future<void> _handleLoadMoreStudents(
  StudentDataBloc bloc,
  StudentsLoadMoreRequested event,
  Emitter<StudentDataState> emit,
) async {
  final current = bloc.state;
  if (current is! StudentDataLoaded) return;
  if (bloc._isLoadingMore || bloc._hasReachedMax) return;
  // Do not paginate when a search query is active (stream covers filtered data).
  if (bloc._lastQuery?.isNotEmpty == true) return;

  bloc._isLoadingMore = true;
  emit(current.copyWith(isLoadingMore: true));

  try {
    final page = await bloc._getStudentsUseCase.fetchPage(
      actor: event.actor,
      limit: bloc._pageSize,
      lastDocument: current.lastDocument,
      teamId: bloc._lastFilterTeamId,
      includeArchived: bloc._includeArchived,
    );

    bloc._lastDocument = page.lastDocument;
    bloc._hasReachedMax = page.hasReachedMax;

    // Merge avoiding duplicates by docID.
    final merged = Map<String, StudentModel>.fromEntries(
      [...bloc._allStudents, ...page.students].map((s) => MapEntry(s.docID, s)),
    ).values.toList(growable: false);
    bloc._allStudents = merged;

    bloc._isLoadingMore = false;
    emit(
      current.copyWith(
        students: merged,
        lastDocument: bloc._lastDocument,
        isLoadingMore: false,
        hasReachedMax: bloc._hasReachedMax,
      ),
    );
  } catch (error) {
    bloc._isLoadingMore = false;
    emit(current.copyWith(isLoadingMore: false));
    if (kDebugMode) debugPrint('StudentDataBloc: load more failed: $error');
  }
}
