import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_managment_system/features/servant/domain/failures/servant_failures.dart';

import 'servant_data_state.dart';

export 'servant_data_state.dart';

/// Cubit for managing Servant data operations (CRUD).
class ServantDataCubit extends Cubit<ServantDataState> {
  final ServantDataRepository _repository;
  final AuthService _authService;

  ServantDataCubit({
    required ServantDataRepository repository,
    required AuthService authService,
  }) : _repository = repository,
       _authService = authService,
       super(const ServantDataInitial());

  String? _lastQuery;
  int _lastLimit = 200;
  List<ServantModel> _allServants = [];

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
    int limit = 200,
    bool forceRefresh = false,
  }) async {
    if (!_ensureAdmin(actor)) return;

    if (!forceRefresh &&
        state is ServantDataLoaded &&
        _allServants.isNotEmpty) {
      _lastLimit = limit;
      _lastQuery = null;
      emit(ServantDataLoaded(servants: _sortAndTrim(List.of(_allServants))));
      return;
    }

    emit(const ServantDataLoading());
    try {
      _lastLimit = limit;
      _lastQuery = null;
      _allServants = await _repository.getAllServants(limit: limit);
      emit(ServantDataLoaded(servants: _sortAndTrim(List.of(_allServants))));
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
      final filteredServants = _allServants.where((servant) {
        return servant.name.toLowerCase().contains(normalizedQuery);
      }).toList();
      emit(
        ServantDataLoaded(
          servants: _sortAndTrim(filteredServants),
          currentQuery: query,
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
    final previousLoaded = state is ServantDataLoaded
        ? state as ServantDataLoaded
        : null;
    emit(const ServantDataLoading());
    try {
      String? authUid;
      // Create a Firebase Auth account if email + password are provided.
      if (email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        final authUser = await _authService.createUserAsAdmin(
          email: email,
          password: password,
          name: servant.name,
          role: servant.role,
        );
        authUid = authUser.uid;
      }

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
        await loadServants(actor: actor, limit: _lastLimit, forceRefresh: true);
      }
      emit(const ServantDataOperationSuccess('Servant created successfully'));
    } catch (e) {
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
      await loadServants(actor: actor, limit: _lastLimit, forceRefresh: true);
      emit(const ServantDataOperationSuccess('Servant updated successfully'));
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> deleteServant({
    required AuthUser actor,
    required String docId,
  }) async {
    if (!_ensureAdmin(actor)) return;
    final previousLoaded = state is ServantDataLoaded
        ? state as ServantDataLoaded
        : null;
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
        await loadServants(actor: actor, limit: _lastLimit, forceRefresh: true);
      }
      emit(const ServantDataOperationSuccess('Servant deleted successfully'));
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> refreshServants({required AuthUser actor}) async {
    if (!_ensureAdmin(actor)) return;

    // Force a fresh fetch from the server
    await loadServants(actor: actor, limit: _lastLimit, forceRefresh: true);

    // Re-apply search locally if a query was active
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      await searchServants(actor: actor, query: _lastQuery!);
    }
  }

  ServantFailure _mapFailure(Object error) {
    if (error is ServantFailure) return error;
    return mapExceptionToServantFailure(error);
  }

  bool _tryEmitOptimisticUpdate(
    ServantDataLoaded? previousLoaded,
    List<ServantModel> Function(List<ServantModel> servants) update, {
    bool emitLoading = false,
  }) {
    if (previousLoaded == null) return false;

    _allServants = update(List<ServantModel>.from(_allServants));

    if (!_canOptimisticallyUpdate(previousLoaded)) return false;
    var updated = update(List<ServantModel>.from(previousLoaded.servants));
    updated = _sortAndTrim(updated);
    if (emitLoading) {
      emit(const ServantDataLoading());
    }
    emit(ServantDataLoaded(servants: updated));
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

  List<ServantModel> _sortAndTrim(List<ServantModel> servants) {
    servants.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    if (_lastLimit > 0 && servants.length > _lastLimit) {
      return servants.sublist(0, _lastLimit);
    }
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
