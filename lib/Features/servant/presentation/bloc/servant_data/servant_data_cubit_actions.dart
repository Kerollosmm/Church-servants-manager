// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

part of 'servant_data_cubit.dart';

extension ServantDataCubitActions on ServantDataCubit {
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
        servants: _visibleServants(),
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

    _emitLoading();
    try {
      _setPaginationDefaults(limit: limit);
      _applyPage(await _loadPage(), reset: true);
      _emitLoaded();
    } catch (error) {
      _emitMutationFailure(error);
    }
  }

  Future<void> searchServants({
    required AuthUser actor,
    required String query,
    bool includeArchived = false,
  }) async {
    if (!_ensureAdmin(actor)) return;

    _includeArchived = includeArchived;
    _emitLoading();
    try {
      _lastQuery = query;
      emit(
        ServantDataLoaded(
          servants: _visibleServants(),
          currentQuery: query,
          hasMore: false,
          isLoadingMore: false,
          includeArchived: _includeArchived,
        ),
      );
    } catch (error) {
      _emitMutationFailure(error);
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
      final createdServant = await _addServantUseCase(
        servant: servant,
        email: email,
        password: password,
      );
      final didOptimisticUpdate = _tryEmitOptimisticUpdate(previousLoaded, (
        servants,
      ) {
        if (servant.docID != createdServant.docID) {
          servants.removeWhere((item) => item.docID == servant.docID);
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
    } catch (error) {
      _emitMutationFailure(error);
    }
  }

  Future<void> updateServant({
    required AuthUser actor,
    required ServantModel servant,
  }) async {
    if (!_ensureAdmin(actor)) return;
    _emitLoaded(mutationStatus: ServantMutationStatus.inProgress);
    try {
      await _updateServantUseCase(servant);
      await _reloadFromServer(actor);
      _emitLoaded(
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تم تحديث بيانات الخادم بنجاح',
      );
    } catch (error) {
      _emitMutationFailure(error);
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
      await _deleteServantUseCase(docId);
      final didOptimisticUpdate = _tryEmitOptimisticUpdate(previousLoaded, (
        servants,
      ) {
        servants.removeWhere((item) => item.docID == docId);
        return servants;
      });
      if (!didOptimisticUpdate) {
        await _reloadFromServer(actor);
      }
      _emitLoaded(
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage: 'تمت أرشفة الخادم بنجاح',
      );
    } catch (error) {
      _emitMutationFailure(error);
    }
  }

  Future<void> restoreServant({
    required AuthUser actor,
    required String docId,
  }) async {
    if (!_ensureAdmin(actor)) return;
    _emitLoaded(mutationStatus: ServantMutationStatus.inProgress);
    try {
      await _restoreServantUseCase(docId);
      await _reloadFromServer(actor);
      _emitLoaded(
        mutationStatus: ServantMutationStatus.success,
        feedbackMessage:
            'تمت استعادة الخادم بنجاح. يجب على المسؤول إعادة تعيين الفريق يدويا.',
      );
    } catch (error) {
      _emitMutationFailure(error);
    }
  }

  Future<void> refreshServants({
    required AuthUser actor,
    bool? includeArchived,
  }) async {
    if (!_ensureAdmin(actor)) return;
    if (includeArchived != null) {
      _includeArchived = includeArchived;
    }
    await _reloadFromServer(actor);
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      await searchServants(
        actor: actor,
        query: _lastQuery!,
        includeArchived: _includeArchived,
      );
    }
  }

  Future<void> loadMoreServants({
    required AuthUser actor,
    bool? includeArchived,
  }) async {
    if (!_ensureAdmin(actor)) return;
    if (includeArchived != null) {
      _includeArchived = includeArchived;
    }
    if (_isLoadingMore || !_hasMore) return;
    if (_lastQuery != null && _lastQuery!.isNotEmpty) return;

    _isLoadingMore = true;
    _emitLoaded(isLoadingMore: true);

    try {
      _applyPage(await _loadPage(lastDocument: _lastDocument));
      _isLoadingMore = false;
      _emitLoaded();
    } catch (error) {
      _isLoadingMore = false;
      _emitMutationFailure(error);
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

  Future<ServantsPage> _loadPage({
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
  }) {
    return _getServantsUseCase(
      limit: _lastLimit,
      lastDocument: lastDocument,
      includeArchived: _includeArchived,
    );
  }

  void _applyPage(ServantsPage page, {bool reset = false}) {
    if (reset) {
      _allServants = page.servants;
    } else {
      final byId = <String, ServantModel>{
        for (final servant in _allServants) servant.docID: servant,
      };
      for (final servant in page.servants) {
        byId[servant.docID] = servant;
      }
      _allServants = byId.values.toList(growable: false);
    }
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

    _allServants = update(List<ServantModel>.from(_allServants));

    if (!_canOptimisticallyUpdate(previousLoaded)) return false;
    final updated = _filterServantsUseCase(
      servants: update(List<ServantModel>.from(previousLoaded.servants)),
      query: previousLoaded.currentQuery,
    );
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

  List<ServantModel> _visibleServants() {
    return _filterServantsUseCase(servants: _allServants, query: _lastQuery);
  }

  List<ServantModel> _upsertServant(
    List<ServantModel> servants,
    ServantModel servant,
  ) {
    final index = servants.indexWhere((item) => item.docID == servant.docID);
    if (index == -1) {
      servants.add(servant);
    } else {
      servants[index] = servant;
    }
    return servants;
  }
}
