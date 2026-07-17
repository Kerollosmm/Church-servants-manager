import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

export 'servant_data_state.dart';

part 'servant_data_event.dart';

EventTransformer<Event> debounceRestartable<Event>({
  Duration duration = const Duration(milliseconds: 300),
}) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}

/// Bloc managing servant list state with pagination, search,
/// and CRUD operations.
///
/// Handles two-phase commit (servant doc + auth user) with
/// rollback on failure.
class ServantDataBloc extends Bloc<ServantDataEvent, ServantDataState> {
  ServantDataBloc({
    required IServantRepository repository,
    required ProvisionServantWithAuthUseCase provisionUseCase,
  }) : _repository = repository,
       _provisionUseCase = provisionUseCase,
       super(const ServantDataInitial()) {
    on<ServantsLoadRequested>(
      _onServantsLoadRequested,
      transformer: restartable(),
    );
    on<ServantsSearchRequested>(
      _onServantsSearchRequested,
      transformer: debounceRestartable(),
    );
    on<ServantCreateRequested>(
      _onServantCreateRequested,
      transformer: droppable(),
    );
    on<ServantUpdateRequested>(
      _onServantUpdateRequested,
      transformer: droppable(),
    );
    on<ServantDeleted>(_onServantDeleted, transformer: droppable());
    on<ServantRestored>(_onServantRestored, transformer: droppable());
    on<ServantsRefreshRequested>(
      _onServantsRefreshRequested,
      transformer: restartable(),
    );
    on<ServantsLoadMoreRequested>(
      _onServantsLoadMoreRequested,
      transformer: restartable(),
    );
  }

  final IServantRepository _repository;
  final ProvisionServantWithAuthUseCase _provisionUseCase;

  String? _lastQuery;
  int _lastLimit = 50;
  bool _includeArchived = false;
  List<Servant> _allServants = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isLoadingFirstPage = false;
  PaginationCursor? _lastDocument;

  ServantDataLoaded? get _loadedState =>
      state is ServantDataLoaded ? state as ServantDataLoaded : null;

  bool _canRead(AuthUser actor) =>
      actor.role == UserRole.admin || actor.role == UserRole.servant;

  bool _ensureRead(AuthUser actor, Emitter<ServantDataState> emit) {
    if (_canRead(actor)) return true;
    emit(
      const ServantDataError(
        GenericServantFailure('خطأ في الصلاحية: ليس لديك صلاحية عرض الخدام.'),
      ),
    );
    return false;
  }

  bool _ensureAdmin(AuthUser actor, Emitter<ServantDataState> emit) {
    if (actor.role == UserRole.admin) return true;
    emit(
      const ServantDataError(
        GenericServantFailure(
          'خطأ في الصلاحية: المسؤول فقط يمكنه إجراء هذه العملية.',
        ),
      ),
    );
    return false;
  }

  void _emitLoading(Emitter<ServantDataState> emit) {
    emit(
      ServantDataLoading(
        previousServants: List<Servant>.from(_allServants),
        isRefresh: _allServants.isNotEmpty,
        includeArchived: _includeArchived,
      ),
    );
  }

  void _emitLoaded(
    Emitter<ServantDataState> emit, {
    bool isLoadingMore = false,
    ServantMutationStatus mutationStatus = ServantMutationStatus.idle,
    String? feedbackMessage,
  }) {
    emit(
      ServantDataLoaded(
        servants: _sortByName(List<Servant>.from(_allServants)),
        currentQuery: _lastQuery,
        hasMore: (_lastQuery == null || _lastQuery!.isEmpty) && _hasMore,
        isLoadingMore: isLoadingMore,
        includeArchived: _includeArchived,
        mutationStatus: mutationStatus,
        feedbackMessage: feedbackMessage,
      ),
    );
  }

  void _emitMutationFailure(Object error, Emitter<ServantDataState> emit) {
    final failure = _mapFailure(error);
    if (_allServants.isNotEmpty) {
      _emitLoaded(
        emit,
        mutationStatus: ServantMutationStatus.failure,
        feedbackMessage: failure.message,
      );
      return;
    }
    emit(ServantDataError(failure));
  }

  Future<void> _onServantsLoadRequested(
    ServantsLoadRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureRead(event.actor, emit)) return;

    _includeArchived = event.includeArchived;
    if (!event.forceRefresh &&
        state is ServantDataLoaded &&
        _allServants.isNotEmpty) {
      _lastLimit = event.limit <= 0 ? _lastLimit : event.limit;
      _lastQuery = null;
      _emitLoaded(emit);
      return;
    }

    if (_isLoadingFirstPage) return;
    _isLoadingFirstPage = true;

    _emitLoading(emit);
    try {
      _setPaginationDefaults(limit: event.limit);
      await _loadFirstPage();
      _emitLoaded(emit);
    } catch (e) {
      _emitMutationFailure(e, emit);
    } finally {
      _isLoadingFirstPage = false;
    }
  }

  Future<void> _onServantsSearchRequested(
    ServantsSearchRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureRead(event.actor, emit)) return;

    _includeArchived = event.includeArchived;
    if (_allServants.isEmpty) {
      await _internalLoadServants(event.actor, event.includeArchived, emit);
    }

    try {
      _lastQuery = event.query;
      final normalizedQuery = event.query.toLowerCase();
      final filteredServants = _allServants
          .where((servant) {
            return servant.name.toLowerCase().contains(normalizedQuery);
          })
          .toList(growable: false);
      emit(
        ServantDataLoaded(
          servants: _sortByName(filteredServants),
          currentQuery: event.query,
          includeArchived: _includeArchived,
        ),
      );
    } catch (e) {
      _emitMutationFailure(e, emit);
    }
  }

  Future<void> _internalLoadServants(
    AuthUser actor,
    bool includeArchived,
    Emitter<ServantDataState> emit,
  ) async {
    _isLoadingFirstPage = true;
    _emitLoading(emit);
    try {
      _setPaginationDefaults(limit: _lastLimit);
      await _loadFirstPage();
      _emitLoaded(emit);
    } catch (e) {
      _emitMutationFailure(e, emit);
    } finally {
      _isLoadingFirstPage = false;
    }
  }

  Future<void> _onServantCreateRequested(
    ServantCreateRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureAdmin(event.actor, emit)) return;
    final previousLoaded = _loadedState;
    _emitLoaded(emit, mutationStatus: ServantMutationStatus.inProgress);
    try {
      final docId = await _provisionUseCase(
        servant: event.servant,
        email: event.email,
        password: event.password,
      );

      final createdServant = event.servant.copyWith(
        docID: docId,
        uid: (event.email != null && event.email!.isNotEmpty)
            ? docId
            : event.servant.uid,
      );

      final didOptimisticUpdate = _tryEmitOptimisticUpdate(
        emit,
        previousLoaded,
        (servants) {
          if (event.servant.docID != docId) {
            servants.removeWhere((s) => s.docID == event.servant.docID);
          }
          return _upsertServant(servants, createdServant);
        },
      );
      if (!didOptimisticUpdate) {
        await _internalReloadFromServer(event.actor, emit);
      }
      _emitLoaded(
        emit,
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تم إنشاء الخادم بنجاح',
      );
    } catch (e) {
      _emitMutationFailure(e, emit);
    }
  }

  Future<void> _onServantUpdateRequested(
    ServantUpdateRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureAdmin(event.actor, emit)) return;
    _emitLoaded(emit, mutationStatus: ServantMutationStatus.inProgress);
    try {
      await _repository.updateServant(event.servant);
      await _internalReloadFromServer(event.actor, emit);
      _emitLoaded(
        emit,
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تم تحديث بيانات الخادم بنجاح',
      );
    } catch (e) {
      _emitMutationFailure(e, emit);
    }
  }

  Future<void> _onServantDeleted(
    ServantDeleted event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureAdmin(event.actor, emit)) return;
    final previousLoaded = _loadedState;
    _emitLoaded(emit, mutationStatus: ServantMutationStatus.inProgress);
    try {
      final existing = await _repository.getServantById(
        event.docId,
        includeArchived: true,
      );
      if (existing == null) {
        throw const GenericServantFailure('الخادم غير موجود.');
      }

      await _provisionUseCase.archive(
        docId: event.docId,
        performedByUid: event.actor.uid,
        linkedUid: existing.uid,
        capturedTeamId: existing.assignedTeamId,
        capturedTeamIds: existing.assignedTeamIds,
      );

      final didOptimisticUpdate = _tryEmitOptimisticUpdate(
        emit,
        previousLoaded,
        (servants) {
          servants.removeWhere((s) => s.docID == event.docId);
          return servants;
        },
      );
      if (!didOptimisticUpdate) {
        await _internalReloadFromServer(event.actor, emit);
      }
      _emitLoaded(
        emit,
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تمت أرشفة الخادم بنجاح',
      );
    } catch (e) {
      _emitMutationFailure(e, emit);
    }
  }

  Future<void> _onServantRestored(
    ServantRestored event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureAdmin(event.actor, emit)) return;
    _emitLoaded(emit, mutationStatus: ServantMutationStatus.inProgress);
    try {
      final existing = await _repository.getServantById(
        event.docId,
        includeArchived: true,
      );
      if (existing == null) {
        _emitMutationFailure(
          const GenericServantFailure('لم يتم العثور على الخادم.'),
          emit,
        );
        return;
      }
      await _provisionUseCase.restore(
        docId: event.docId,
        performedByUid: event.actor.uid,
        linkedUid: existing.uid,
      );
      await _internalReloadFromServer(event.actor, emit);
      _emitLoaded(
        emit,
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage:
            'تمت استعادة الخادم بنجاح. يجب على المسؤول إعادة تعيين الفريق يدويا.',
      );
    } catch (e) {
      _emitMutationFailure(e, emit);
    }
  }

  Future<void> _onServantsRefreshRequested(
    ServantsRefreshRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureRead(event.actor, emit)) return;
    await _internalReloadFromServer(event.actor, emit);
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      await _onServantsSearchRequested(
        ServantsSearchRequested(
          actor: event.actor,
          query: _lastQuery!,
          includeArchived: _includeArchived,
        ),
        emit,
      );
    }
  }

  Future<void> _onServantsLoadMoreRequested(
    ServantsLoadMoreRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    if (!_ensureRead(event.actor, emit)) return;
    if (_isLoadingMore || !_hasMore) return;
    if (_lastQuery != null && _lastQuery!.isNotEmpty) return;

    _isLoadingMore = true;
    _emitLoaded(emit, isLoadingMore: true);

    try {
      final page = await _repository.getServantsPage(
        limit: _lastLimit,
        cursor: _lastDocument,
        includeArchived: _includeArchived,
      );

      final byId = <String, Servant>{for (final s in _allServants) s.docID: s};
      for (final servant in page.servants) {
        byId[servant.docID] = servant;
      }

      _allServants = byId.values.toList(growable: false);
      _hasMore = page.hasMore;
      _lastDocument = page.lastDocument;
      _isLoadingMore = false;
      _emitLoaded(emit);
    } catch (e) {
      _isLoadingMore = false;
      _emitMutationFailure(e, emit);
    }
  }

  Future<void> _internalReloadFromServer(
    AuthUser actor,
    Emitter<ServantDataState> emit,
  ) {
    _isLoadingFirstPage = true;
    _emitLoading(emit);
    return _loadFirstPage()
        .then((_) {
          _isLoadingFirstPage = false;
          _emitLoaded(emit);
        })
        .catchError((e) {
          _isLoadingFirstPage = false;
          _emitMutationFailure(e, emit);
        });
  }

  Future<void> _loadFirstPage() async {
    final page = await _repository.getServantsPage(
      limit: _lastLimit,
      includeArchived: _includeArchived,
    );
    _allServants = page.servants;
    _hasMore = page.hasMore;
    _lastDocument = page.lastDocument;
  }

  void _setPaginationDefaults({required int limit}) {
    _lastLimit = limit <= 0 ? 50 : limit;
    _lastQuery = null;
    _hasMore = true;
    _isLoadingMore = false;
    _lastDocument = null;
  }

  ServantFailure _mapFailure(Object error) {
    if (error is ServantFailure) return error;
    return mapExceptionToServantFailure(error);
  }

  bool _tryEmitOptimisticUpdate(
    Emitter<ServantDataState> emit,
    ServantDataLoaded? previousLoaded,
    List<Servant> Function(List<Servant> servants) update,
  ) {
    if (previousLoaded == null) return false;

    if (!_canOptimisticallyUpdate(previousLoaded)) return false;

    final updatedServants = update(List<Servant>.from(_allServants));
    _allServants = updatedServants;

    var updated = update(List<Servant>.from(previousLoaded.servants));
    updated = _sortByName(updated);
    emit(
      previousLoaded.copyWith(
        servants: updated,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
        includeArchived: _includeArchived,
        mutationStatus: ServantMutationStatus.idle,
        clearFeedbackMessage: true,
      ),
    );
    return true;
  }

  bool _canOptimisticallyUpdate(ServantDataLoaded previousLoaded) {
    if (_lastQuery != null && _lastQuery!.isNotEmpty) return false;
    if (previousLoaded.currentQuery != null &&
        previousLoaded.currentQuery!.isNotEmpty) {
      return false;
    }
    if (previousLoaded.currentFilterTeamName != null) return false;
    return true;
  }

  List<Servant> _sortByName(List<Servant> servants) {
    servants.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return servants;
  }

  List<Servant> _upsertServant(List<Servant> servants, Servant servant) {
    final index = servants.indexWhere((s) => s.docID == servant.docID);
    if (index == -1) {
      servants.add(servant);
    } else {
      servants[index] = servant;
    }
    return servants;
  }
}
