import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:church_managment_system/core/constants/enums.dart'; // Added for UserRole
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';

part 'servant_data_event.dart';
part 'servant_data_state.dart';

/// BLoC for managing Servant data operations (CRUD).
class ServantDataBloc extends Bloc<ServantDataEvent, ServantDataState> {
  final ServantDataRepository _repository;

  ServantDataBloc({required ServantDataRepository repository})
    : _repository = repository,
      super(const ServantDataInitial()) {
    on<ServantsLoadRequested>(_onServantsLoadRequested);
    on<ServantsSearchRequested>(_onServantsSearchRequested);
    on<ServantCreated>(_onServantCreated);
    on<ServantUpdated>(_onServantUpdated);
    on<ServantDeleted>(_onServantDeleted);
    on<ServantsRefreshRequested>(_onServantsRefreshRequested);
  }

  String? _lastQuery;
  int _lastLimit = 50;

  Future<void> _onServantsLoadRequested(
    ServantsLoadRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    emit(const ServantDataLoading());
    try {
      _lastLimit = event.limit;
      _lastQuery = null;
      final servants = await _repository.getAllServants(limit: event.limit);
      emit(ServantDataLoaded(servants: servants));
    } catch (e) {
      emit(ServantDataError('Failed to load servants: $e'));
    }
  }

  Future<void> _onServantsSearchRequested(
    ServantsSearchRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    // Security Check: Only admins can search the global servant directory
    if (event.actor.role != UserRole.admin) {
      emit(
        const ServantDataError(
          'Permission denied: Only admins can search servants.',
        ),
      );
      return;
    }

    emit(const ServantDataLoading());
    try {
      _lastQuery = event.query;
      final servants = await _repository.searchServants(event.query);
      emit(ServantDataLoaded(servants: servants, currentQuery: event.query));
    } catch (e) {
      emit(ServantDataError('Failed to search servants: $e'));
    }
  }

  Future<void> _onServantCreated(
    ServantCreated event,
    Emitter<ServantDataState> emit,
  ) async {
    emit(const ServantDataLoading());
    try {
      await _repository.createServant(event.servant);
      emit(const ServantDataOperationSuccess('Servant created successfully'));
      // Reload list
      add(ServantsLoadRequested(actor: event.actor, limit: _lastLimit));
    } catch (e) {
      emit(ServantDataError('Failed to create servant: $e'));
    }
  }

  Future<void> _onServantUpdated(
    ServantUpdated event,
    Emitter<ServantDataState> emit,
  ) async {
    emit(const ServantDataLoading());
    try {
      await _repository.updateServant(event.servant);
      emit(const ServantDataOperationSuccess('Servant updated successfully'));
      // Reload list
      add(ServantsLoadRequested(actor: event.actor, limit: _lastLimit));
    } catch (e) {
      emit(ServantDataError('Failed to update servant: $e'));
    }
  }

  Future<void> _onServantDeleted(
    ServantDeleted event,
    Emitter<ServantDataState> emit,
  ) async {
    emit(const ServantDataLoading());
    try {
      await _repository.deleteServant(event.docId);
      emit(const ServantDataOperationSuccess('Servant deleted successfully'));
      // Reload list
      add(ServantsLoadRequested(actor: event.actor, limit: _lastLimit));
    } catch (e) {
      emit(ServantDataError('Failed to delete servant: $e'));
    }
  }

  Future<void> _onServantsRefreshRequested(
    ServantsRefreshRequested event,
    Emitter<ServantDataState> emit,
  ) async {
    // Re-fetch with last known parameters
    if (_lastQuery != null && _lastQuery!.isNotEmpty) {
      add(ServantsSearchRequested(actor: event.actor, query: _lastQuery!));
    } else {
      add(ServantsLoadRequested(actor: event.actor, limit: _lastLimit));
    }
  }
}
