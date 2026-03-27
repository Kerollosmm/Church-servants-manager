import 'package:church_management_system/features/servant/data/models/servant_models.dart';
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
    this.previousServants = const <ServantModel>[],
    this.isRefresh = false,
    this.includeArchived = false,
  });

  final List<ServantModel> previousServants;
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
  });

  final List<ServantModel> servants;
  final String? currentFilterTeamName;
  final String? currentQuery;
  final bool hasMore;
  final bool isLoadingMore;
  final bool includeArchived;
  final ServantMutationStatus mutationStatus;
  final String? feedbackMessage;

  int get count => servants.length;

  bool get isEmpty => servants.isEmpty;

  ServantDataLoaded copyWith({
    List<ServantModel>? servants,
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
  }) {
    return ServantDataLoaded(
      servants: servants ?? this.servants,
      currentFilterTeamName: clearCurrentFilterTeamName
          ? null
          : (currentFilterTeamName ?? this.currentFilterTeamName),
      currentQuery: clearCurrentQuery
          ? null
          : (currentQuery ?? this.currentQuery),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      includeArchived: includeArchived ?? this.includeArchived,
      mutationStatus: mutationStatus ?? this.mutationStatus,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
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
  ];
}

final class ServantDataError extends ServantDataState {
  const ServantDataError(this.failure);

  final ServantFailure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}
