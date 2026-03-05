import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/domain/failures/servant_failures.dart';
import 'package:equatable/equatable.dart';

/// Sealed states for ServantDataCubit with exhaustive switch support.
sealed class ServantDataState extends Equatable {
  const ServantDataState();

  @override
  List<Object?> get props => [];
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
  final bool hasMore;
  final bool isLoadingMore;

  const ServantDataLoaded({
    required this.servants,
    this.currentFilterTeamName,
    this.currentQuery,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  /// Get servant count.
  int get count => servants.length;

  /// Check if empty.
  bool get isEmpty => servants.isEmpty;

  @override
  List<Object?> get props => [
    servants,
    currentFilterTeamName,
    currentQuery,
    hasMore,
    isLoadingMore,
  ];
}

/// Error state - operation failed.
final class ServantDataError extends ServantDataState {
  final ServantFailure failure;

  const ServantDataError(this.failure);

  /// Helper to get the failure message.
  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

/// Success state for CRUD operations.
final class ServantDataOperationSuccess extends ServantDataState {
  final String message;

  const ServantDataOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
