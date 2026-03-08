import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';

import 'servant_data_state.dart';

export 'servant_data_state.dart';

/// Cubit for managing Servant data operations (CRUD).
class ServantDataCubit extends Cubit<ServantDataState> {
  final ServantDataRepository _repository;
  final AdminUserProvisioningService _adminUserProvisioningService;

  ServantDataCubit({
    required ServantDataRepository repository,
    required AdminUserProvisioningService adminUserProvisioningService,
  }) : _repository = repository,
       _adminUserProvisioningService = adminUserProvisioningService,
       super(const ServantDataInitial());

  String? _lastQuery;
  int _lastLimit = 50;
  List<ServantModel> _allServants = [];
  bool _hasMore = true;
  bool _isLoadingMore = false;
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;

  ServantDataLoaded? get _loadedState =>
      state is ServantDataLoaded ? state as ServantDataLoaded : null;

  bool _ensureAdmin(AuthUser actor) {
    if (actor.role == UserRole.admin) {
      return true;
    }
    emit(
      const ServantDataError(
        GenericServantFailure(
          'Permission denied: Only admins can manage servants.',
        ),
      ),
    );
    return false;
  }

  Future<void> loadServants({
    required AuthUser actor,
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    if (!_ensureAdmin(actor)) return;

    if (!forceRefresh &&
        state is ServantDataLoaded &&
        _allServants.isNotEmpty) {
      _lastLimit = limit <= 0 ? _lastLimit : limit;
      _lastQuery = null;
      _emitLoaded();
      return;
    }

    emit(const ServantDataLoading());
    try {
      _setPaginationDefaults(limit: limit);
      await _loadFirstPage();
      _emitLoaded();
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> searchServants({
    required AuthUser actor,
    required String query,
  }) async {
    if (!_ensureAdmin(actor)) return;

    emit(const ServantDataLoading());
    try {
      _lastQuery = query;
      final normalizedQuery = query.toLowerCase();
      final filteredServants = _allServants
          .where(
            (servant) => servant.name.toLowerCase().contains(normalizedQuery),
          )
          .toList();
      emit(
        ServantDataLoaded(
          servants: _sortByName(filteredServants),
          currentQuery: query,
          hasMore: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
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
    AuthUser? createdAuthUser;
    emit(const ServantDataLoading());
    try {
      createdAuthUser = await _createServantAuthUser(
        servant: servant,
        email: email,
        password: password,
      );
      final authUid = createdAuthUser?.uid;

      final servantWithUid = authUid != null
          ? servant.copyWith(uid: authUid, docID: authUid)
          : servant;
      final docId = await _repository.createServant(servantWithUid);
      final createdServant = servantWithUid.copyWith(docID: docId);
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
      emit(const ServantDataOperationSuccess('تم إنشاء الخادم بنجاح'));
    } catch (e) {
      if (createdAuthUser != null &&
          email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        try {
          await _adminUserProvisioningService.rollbackCreatedUser(
            uid: createdAuthUser.uid,
            email: email,
            password: password,
          );
        } catch (rollbackError) {
          emit(
            ServantDataError(
              _mapFailure(
                Exception(
                  'Create servant failed and rollback was incomplete: $rollbackError',
                ),
              ),
            ),
          );
          return;
        }
      }
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> updateServant({
    required AuthUser actor,
    required ServantModel servant,
  }) async {
    if (!_ensureAdmin(actor)) return;
    emit(const ServantDataLoading());
    try {
      await _repository.updateServant(servant);
      // Always reload from server to ensure the list is fresh and accurate,
      // especially after role changes where the servant may no longer appear.
      await _reloadFromServer(actor);
      emit(const ServantDataOperationSuccess('تم تحديث بيانات الخادم بنجاح'));
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> deleteServant({
    required AuthUser actor,
    required String docId,
  }) async {
    if (!_ensureAdmin(actor)) return;
    final previousLoaded = _loadedState;
    emit(const ServantDataLoading());
    try {
      await _repository.deleteServant(docId);
      final didOptimisticUpdate = _tryEmitOptimisticUpdate(previousLoaded, (
        servants,
      ) {
        servants.removeWhere((s) => s.docID == docId);
        return servants;
      });
      if (!didOptimisticUpdate) {
        await _reloadFromServer(actor);
      }
      emit(const ServantDataOperationSuccess('تم حذف الخادم بنجاح'));
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> refreshServants({required AuthUser actor}) async {
    if (!_ensureAdmin(actor)) return;

    // Force a fresh fetch from the server
    await _reloadFromServer(actor);

    // Re-apply search locally if a query was active
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      await searchServants(actor: actor, query: _lastQuery!);
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
        lastDocument: _lastDocument,
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
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> _reloadFromServer(AuthUser actor) {
    return loadServants(actor: actor, limit: _lastLimit, forceRefresh: true);
  }

  Future<void> _loadFirstPage() async {
    final page = await _repository.getServantsPage(limit: _lastLimit);
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

  Future<AuthUser?> _createServantAuthUser({
    required ServantModel servant,
    String? email,
    String? password,
  }) async {
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return _adminUserProvisioningService.createUser(
      email: email,
      password: password,
      name: servant.name,
      role: servant.role,
    );
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

    _allServants = update(List<ServantModel>.from(_allServants));

    if (!_canOptimisticallyUpdate(previousLoaded)) return false;
    var updated = update(List<ServantModel>.from(previousLoaded.servants));
    updated = _sortByName(updated);
    emit(
      ServantDataLoaded(
        servants: updated,
        hasMore: _hasMore,
        isLoadingMore: _isLoadingMore,
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

  void _emitLoaded({bool isLoadingMore = false}) {
    emit(
      ServantDataLoaded(
        servants: _sortByName(List<ServantModel>.from(_allServants)),
        currentQuery: _lastQuery,
        hasMore: (_lastQuery == null || _lastQuery!.isEmpty) && _hasMore,
        isLoadingMore: isLoadingMore,
      ),
    );
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
