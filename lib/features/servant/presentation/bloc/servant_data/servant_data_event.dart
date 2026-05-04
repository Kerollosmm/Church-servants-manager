part of 'servant_data_bloc.dart';

sealed class ServantDataEvent extends Equatable {
  const ServantDataEvent();

  @override
  List<Object?> get props => [];
}

class ServantsLoadRequested extends ServantDataEvent {
  final AuthUser actor;
  final int limit;
  final bool forceRefresh;
  final bool includeArchived;

  const ServantsLoadRequested({
    required this.actor,
    this.limit = 50,
    this.forceRefresh = false,
    this.includeArchived = false,
  });

  @override
  List<Object?> get props => [actor, limit, forceRefresh, includeArchived];
}

class ServantsSearchRequested extends ServantDataEvent {
  final AuthUser actor;
  final String query;
  final bool includeArchived;

  const ServantsSearchRequested({
    required this.actor,
    required this.query,
    this.includeArchived = false,
  });

  @override
  List<Object?> get props => [actor, query, includeArchived];
}

class ServantCreateRequested extends ServantDataEvent {
  final AuthUser actor;
  final ServantModel servant;
  final String? email;
  final String? password;

  const ServantCreateRequested({
    required this.actor,
    required this.servant,
    this.email,
    this.password,
  });

  @override
  List<Object?> get props => [actor, servant, email, password];
}

class ServantUpdateRequested extends ServantDataEvent {
  final AuthUser actor;
  final ServantModel servant;

  const ServantUpdateRequested({required this.actor, required this.servant});

  @override
  List<Object?> get props => [actor, servant];
}

class ServantDeleted extends ServantDataEvent {
  final AuthUser actor;
  final String docId;

  const ServantDeleted({required this.actor, required this.docId});

  @override
  List<Object?> get props => [actor, docId];
}

class ServantRestored extends ServantDataEvent {
  final AuthUser actor;
  final String docId;

  const ServantRestored({required this.actor, required this.docId});

  @override
  List<Object?> get props => [actor, docId];
}

class ServantsRefreshRequested extends ServantDataEvent {
  final AuthUser actor;

  const ServantsRefreshRequested({required this.actor});

  @override
  List<Object?> get props => [actor];
}

class ServantsLoadMoreRequested extends ServantDataEvent {
  final AuthUser actor;

  const ServantsLoadMoreRequested({required this.actor});

  @override
  List<Object?> get props => [actor];
}
