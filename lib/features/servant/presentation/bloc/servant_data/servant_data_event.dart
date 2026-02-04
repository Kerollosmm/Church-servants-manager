part of 'servant_data_bloc.dart';

/// Sealed events for ServantDataBloc (past tense naming convention).
sealed class ServantDataEvent {
  const ServantDataEvent();
}

/// Load servants with optional team filter.
final class ServantsLoadRequested extends ServantDataEvent {
  final AuthUser actor;
  final int limit;

  const ServantsLoadRequested({required this.actor, this.limit = 50});
}

/// Search servants by name (BLoC-managed).
final class ServantsSearchRequested extends ServantDataEvent {
  final AuthUser actor;
  final String query;

  const ServantsSearchRequested({required this.actor, required this.query});
}

/// Create a new servant.
final class ServantCreated extends ServantDataEvent {
  final AuthUser actor;
  final ServantModel servant;

  const ServantCreated({required this.actor, required this.servant});
}

/// Update an existing servant.
final class ServantUpdated extends ServantDataEvent {
  final AuthUser actor;
  final ServantModel servant;

  const ServantUpdated({required this.actor, required this.servant});
}

/// Delete a servant by document ID.
final class ServantDeleted extends ServantDataEvent {
  final AuthUser actor;
  final String docId;

  const ServantDeleted({required this.actor, required this.docId});
}

/// Refresh servants (re-fetch with current filter).
final class ServantsRefreshRequested extends ServantDataEvent {
  final AuthUser actor;

  const ServantsRefreshRequested({required this.actor});
}
