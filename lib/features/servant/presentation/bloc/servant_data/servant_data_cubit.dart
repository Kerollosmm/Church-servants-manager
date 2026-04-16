import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/utils/pagination_cursor.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'servant_data_state.dart';

/// Cubit managing servant list state with pagination, search,
/// and CRUD operations.
///
/// Handles two-phase commit (servant doc + auth user) with
/// rollback on failure.
class ServantDataCubit extends Cubit<ServantDataState> {
  ServantDataCubit({
    required IServantRepository repository,
    required ProvisionServantWithAuthUseCase provisionUseCase,
  }) : _repository = repository,
       _provisionUseCase = provisionUseCase,
       super(const ServantDataInitial());

  final IServantRepository _repository;
  final ProvisionServantWithAuthUseCase _provisionUseCase;

  String? _lastQuery;
  int _lastLimit = 50;
  bool _includeArchived = false;
  List<ServantModel> _allServants = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isLoadingFirstPage = false;
  PaginationCursor? _lastDocument;

  ServantDataLoaded? get _loadedState =>
      state is ServantDataLoaded ? state as ServantDataLoaded : null;

  bool _ensureAdmin(AuthUser actor) {
    if (actor.role == UserRole.admin) {
      return true;
    }
    emit(
      const ServantDataError(
        GenericServantFailure(
          'خطأ في الصلاحية: المسؤول فقط يمكنه إدارة الخدام.',
        ),
      ),
    );
    return false;
  }

  void _emitLoading() {
    emit(
      ServantDataLoading(
        previousServants: List<ServantModel>.from(_allServants),
        isRefresh: _allServants.isNotEmpty,
        includeArchived: _includeArchived,
      ),
    );
  }

  void _emitLoaded({
    bool isLoadingMore = false,
    ServantMutationStatus mutationStatus = ServantMutationStatus.idle,
    String? feedbackMessage,
  }) {
    emit(
      ServantDataLoaded(
        servants: _sortByName(List<ServantModel>.from(_allServants)),
        currentQuery: _lastQuery,
        hasMore: (_lastQuery == null || _lastQuery!.isEmpty) && _hasMore,
        isLoadingMore: isLoadingMore,
        includeArchived: _includeArchived,
        mutationStatus: mutationStatus,
        feedbackMessage: feedbackMessage,
      ),
    );
  }

  void _emitMutationFailure(Object error) {
    final failure = _mapFailure(error);
    if (_allServants.isNotEmpty) {
      _emitLoaded(
        mutationStatus: ServantMutationStatus.failure,
        feedbackMessage: failure.message,
      );
      return;
    }
    emit(ServantDataError(failure));
  }

  Future<void> loadServants({
    required AuthUser actor,
    int limit = 50,
    bool forceRefresh = false,
    bool includeArchived = false,
  }) async {
    if (!_ensureAdmin(actor)) return;

    _includeArchived = includeArchived;
    if (!forceRefresh &&
        state is ServantDataLoaded &&
        _allServants.isNotEmpty) {
      _lastLimit = limit <= 0 ? _lastLimit : limit;
      _lastQuery = null;
      _emitLoaded();
      return;
    }

    if (_isLoadingFirstPage) return;
    _isLoadingFirstPage = true;

    _emitLoading();
    try {
      _setPaginationDefaults(limit: limit);
      await _loadFirstPage();
      _emitLoaded();
    } catch (e) {
      _emitMutationFailure(e);
    } finally {
      _isLoadingFirstPage = false;
    }
  }

  Future<void> searchServants({
    required AuthUser actor,
    required String query,
    bool includeArchived = false,
  }) async {
    if (!_ensureAdmin(actor)) return;

    _includeArchived = includeArchived;
    if (_allServants.isEmpty) {
      await loadServants(actor: actor, includeArchived: includeArchived);
    }

    try {
      _lastQuery = query;
      final normalizedQuery = query.toLowerCase();
      final filteredServants = _allServants
          .where((servant) {
            return servant.name.toLowerCase().contains(normalizedQuery);
          })
          .toList(growable: false);
      emit(
        ServantDataLoaded(
          servants: _sortByName(filteredServants),
          currentQuery: query,
          includeArchived: _includeArchived,
        ),
      );
    } catch (e) {
      _emitMutationFailure(e);
    }
  }

  Future<void> createServant({
    required AuthUser actor,
    required ServantModel servant,
    String? email,
    String? password,
  }) async {
    if (!_ensureAdmin(actor)) return;
    final previousLoaded = _loadedState;
    _emitLoaded(mutationStatus: ServantMutationStatus.inProgress);
    try {
      final docId = await _provisionUseCase(
        servant: servant,
        email: email,
        password: password,
      );

      final createdServant = servant.copyWith(
        docID: docId,
        uid: (email != null && email.isNotEmpty) ? docId : servant.uid,
      );

      final didOptimisticUpdate = _tryEmitOptimisticUpdate(previousLoaded, (
        servants,
      ) {
        if (servant.docID != docId) {
          servants.removeWhere((s) => s.docID == servant.docID);
        }
        return _upsertServant(servants, createdServant);
      });
      if (!didOptimisticUpdate) {
        await _reloadFromServer(actor);
      }
      _emitLoaded(
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تم إنشاء الخادم بنجاح',
      );
    } catch (e) {
      _emitMutationFailure(e);
    }
  }

  Future<void> updateServant({
    required AuthUser actor,
    required ServantModel servant,
  }) async {
    if (!_ensureAdmin(actor)) return;
    _emitLoaded(mutationStatus: ServantMutationStatus.inProgress);
    try {
      await _repository.updateServant(servant);
      await _reloadFromServer(actor);
      _emitLoaded(
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تم تحديث بيانات الخادم بنجاح',
      );
    } catch (e) {
      _emitMutationFailure(e);
    }
  }

  Future<void> deleteServant({
    required AuthUser actor,
    required String docId,
  }) async {
    if (!_ensureAdmin(actor)) return;
    final previousLoaded = _loadedState;
    _emitLoaded(mutationStatus: ServantMutationStatus.inProgress);
    try {
      final existing = await _repository.getServantById(
        docId,
        includeArchived: true,
      );
      if (existing == null) {
        throw const GenericServantFailure('الخادم غير موجود.');
      }

      await _provisionUseCase.archive(
        docId: docId,
        performedByUid: actor.uid,
        linkedUid: existing.uid,
        capturedTeamId: existing.assignedTeamId,
        capturedTeamIds: existing.assignedTeamIds,
      );

      final didOptimisticUpdate = _tryEmitOptimisticUpdate(previousLoaded, (
        servants,
      ) {
        servants.removeWhere((s) => s.docID == docId);
        return servants;
      });
      if (!didOptimisticUpdate) {
        await _reloadFromServer(actor);
      }
      _emitLoaded(
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تمت أرشفة الخادم بنجاح',
      );
    } catch (e) {
      _emitMutationFailure(e);
    }
  }

  Future<void> restoreServant({
    required AuthUser actor,
    required String docId,
  }) async {
    if (!_ensureAdmin(actor)) return;
    _emitLoaded(mutationStatus: ServantMutationStatus.inProgress);
    try {
      final existing = await _repository.getServantById(
        docId,
        includeArchived: true,
      );
      if (existing == null) {
        _emitMutationFailure(
          const GenericServantFailure('لم يتم العثور على الخادم.'),
        );
        return;
      }
      await _provisionUseCase.restore(
        docId: docId,
        performedByUid: actor.uid,
        linkedUid: existing.uid,
      );
      await _reloadFromServer(actor);
      _emitLoaded(
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage:
            'تمت استعادة الخادم بنجاح. يجب على المسؤول إعادة تعيين الفريق يدويا.',
      );
    } catch (e) {
      _emitMutationFailure(e);
    }
  }

  Future<void> refreshServants({required AuthUser actor}) async {
    if (!_ensureAdmin(actor)) return;
    await _reloadFromServer(actor);
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      await searchServants(
        actor: actor,
        query: _lastQuery!,
        includeArchived: _includeArchived,
      );
    }
  }

  Future<void> loadMoreServants({required AuthUser actor}) async {
    if (!_ensureAdmin(actor)) return;
    if (_isLoadingMore || !_hasMore) return;
    if (_lastQuery != null && _lastQuery!.isNotEmpty) return;

    _isLoadingMore = true;
    _emitLoaded(isLoadingMore: true);

    try {
      final page = await _repository.getServantsPage(
        limit: _lastLimit,
        cursor: _lastDocument,
        includeArchived: _includeArchived,
      );

      final byId = <String, ServantModel>{
        for (final s in _allServants) s.docID: s,
      };
      for (final servant in page.servants) {
        byId[servant.docID] = servant;
      }

      _allServants = byId.values.toList(growable: false);
      _hasMore = page.hasMore;
      _lastDocument = page.lastDocument;
      _isLoadingMore = false;
      _emitLoaded();
    } catch (e) {
      _isLoadingMore = false;
      _emitMutationFailure(e);
    }
  }

  Future<void> _reloadFromServer(AuthUser actor) {
    return loadServants(
      actor: actor,
      limit: _lastLimit,
      forceRefresh: true,
      includeArchived: _includeArchived,
    );
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
    ServantDataLoaded? previousLoaded,
    List<ServantModel> Function(List<ServantModel> servants) update,
  ) {
    if (previousLoaded == null) return false;
    if (!_canOptimisticallyUpdate(previousLoaded)) return false;

    final updatedServants = update(List<ServantModel>.from(_allServants));
    _allServants = updatedServants;

    var updated = update(List<ServantModel>.from(previousLoaded.servants));
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

  List<ServantModel> _sortByName(List<ServantModel> servants) {
    servants.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return servants;
  }

  List<ServantModel> _upsertServant(
    List<ServantModel> servants,
    ServantModel servant,
  ) {
    final index = servants.indexWhere((s) => s.docID == servant.docID);
    if (index == -1) {
      servants.add(servant);
    } else {
      servants[index] = servant;
    }
    return servants;
  }
}
