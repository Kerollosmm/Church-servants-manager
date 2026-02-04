part of 'servant_data_bloc.dart';

/// Sealed states for ServantDataBloc with exhaustive switch support.
sealed class ServantDataState {
  const ServantDataState();
}

/// Initial state - no data loaded yet.
final class ServantDataInitial extends ServantDataState {
  const ServantDataInitial();
}

/// Loading state - fetching data.
final class ServantDataLoading extends ServantDataState {
  const ServantDataLoading();
}

/// Loaded state - servants fetched successfully.
final class ServantDataLoaded extends ServantDataState {
  final List<ServantModel> servants;
  final String? currentFilterTeamName;
  final String? currentQuery;

  const ServantDataLoaded({
    required this.servants,
    this.currentFilterTeamName,
    this.currentQuery,
  });

  /// Get servant count.
  int get count => servants.length;

  /// Check if empty.
  bool get isEmpty => servants.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServantDataLoaded &&
          runtimeType == other.runtimeType &&
          currentFilterTeamName == other.currentFilterTeamName &&
          currentQuery == other.currentQuery &&
          const ListEquality<ServantModel>().equals(servants, other.servants);

  @override
  int get hashCode => Object.hash(
    const ListEquality<ServantModel>().hash(servants),
    currentFilterTeamName,
    currentQuery,
  );
}

/// Error state - operation failed.
final class ServantDataError extends ServantDataState {
  final String message;

  const ServantDataError(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServantDataError &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Success state for CRUD operations.
final class ServantDataOperationSuccess extends ServantDataState {
  final String message;

  const ServantDataOperationSuccess(this.message);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServantDataOperationSuccess &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}
