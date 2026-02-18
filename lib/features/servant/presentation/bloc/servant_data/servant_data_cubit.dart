import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_managment_system/features/servant/domain/failures/servant_failures.dart';

import 'servant_data_state.dart';

export 'servant_data_state.dart';

/// Cubit for managing Servant data operations (CRUD).
class ServantDataCubit extends Cubit<ServantDataState> {
  final ServantDataRepository _repository;

  ServantDataCubit({required ServantDataRepository repository})
    : _repository = repository,
      super(const ServantDataInitial());

  String? _lastQuery;
  int _lastLimit = 50;

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

  Future<void> loadServants({required AuthUser actor, int limit = 50}) async {
    if (!_ensureAdmin(actor)) return;
    emit(const ServantDataLoading());
    try {
      _lastLimit = limit;
      _lastQuery = null;
      final servants = await _repository.getAllServants(limit: limit);
      emit(ServantDataLoaded(servants: servants));
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
      final servants = await _repository.searchServants(query);
      emit(ServantDataLoaded(servants: servants, currentQuery: query));
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> createServant({
    required AuthUser actor,
    required ServantModel servant,
  }) async {
    if (!_ensureAdmin(actor)) return;
    emit(const ServantDataLoading());
    try {
      await _repository.createServant(servant);
      // Reload first so the list is fresh, then emit success last so
      // BlocListeners (e.g. Navigator.pop) are triggered after data is ready.
      await loadServants(actor: actor, limit: _lastLimit);
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
      // Reload first so the list is fresh, then emit success last.
      await loadServants(actor: actor, limit: _lastLimit);
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
    emit(const ServantDataLoading());
    try {
      await _repository.deleteServant(docId);
      emit(const ServantDataOperationSuccess('Servant deleted successfully'));
      await loadServants(actor: actor, limit: _lastLimit);
    } catch (e) {
      emit(ServantDataError(_mapFailure(e)));
    }
  }

  Future<void> refreshServants({required AuthUser actor}) async {
    if (!_ensureAdmin(actor)) return;
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      await searchServants(actor: actor, query: _lastQuery!);
    } else {
      await loadServants(actor: actor, limit: _lastLimit);
    }
  }

  ServantFailure _mapFailure(Object error) {
    if (error is ServantFailure) return error;
    return mapExceptionToServantFailure(error);
  }
}
