import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/servant/domain/failures/servant_failures.dart';
import 'package:equatable/equatable.dart';

sealed class ServantDataState extends Equatable {
  const ServantDataState();

  @override
  List<Object?> get props => const [];
}

enum ServantMutationStatus { idle, inProgress, success, failure }

final class ServantDataInitial extends ServantDataState {
  const ServantDataInitial();
}

final class ServantDataLoading extends ServantDataState {
  const ServantDataLoading({
    this.previousServants = const <Servant>[],
    this.isRefresh = false,
    this.includeArchived = false,
  });

  final List<Servant> previousServants;
  final bool isRefresh;
  final bool includeArchived;

  bool get hasPreviousServants => previousServants.isNotEmpty;

  @override
  List<Object?> get props => [previousServants, isRefresh, includeArchived];
}

final class ServantDataLoaded extends ServantDataState {
  const ServantDataLoaded({
    required this.servants,
    this.currentFilterTeamName,
    this.currentQuery,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.includeArchived = false,
    this.mutationStatus = ServantMutationStatus.idle,
    this.feedbackMessage,
    this.isFromCache = false,
  });

  final List<Servant> servants;
  final String? currentFilterTeamName;
  final String? currentQuery;
  final bool hasMore;
  final bool isLoadingMore;
  final bool includeArchived;
  final ServantMutationStatus mutationStatus;
  final String? feedbackMessage;
  final bool isFromCache;

  int get count => servants.length;

  bool get isEmpty => servants.isEmpty;

  ServantDataLoaded copyWith({
    List<Servant>? servants,
    String? currentFilterTeamName,
    bool clearCurrentFilterTeamName = false,
    String? currentQuery,
    bool clearCurrentQuery = false,
    bool? hasMore,
    bool? isLoadingMore,
    bool? includeArchived,
    ServantMutationStatus? mutationStatus,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
    bool? isFromCache,
  }) {
    T? resolve<T>(bool clear, T? value, T? fallback) =>
        clear ? null : (value ?? fallback);

    return ServantDataLoaded(
      servants: servants ?? this.servants,
      currentFilterTeamName: resolve(
        clearCurrentFilterTeamName,
        currentFilterTeamName,
        this.currentFilterTeamName,
      ),
      currentQuery: resolve(
        clearCurrentQuery,
        currentQuery,
        this.currentQuery,
      ),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      includeArchived: includeArchived ?? this.includeArchived,
      mutationStatus: mutationStatus ?? this.mutationStatus,
      feedbackMessage: resolve(
        clearFeedbackMessage,
        feedbackMessage,
        this.feedbackMessage,
      ),
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
    servants,
    currentFilterTeamName,
    currentQuery,
    hasMore,
    isLoadingMore,
    includeArchived,
    mutationStatus,
    feedbackMessage,
    isFromCache,
  ];
}

final class ServantDataError extends ServantDataState {
  const ServantDataError(this.failure);

  final ServantFailure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}
