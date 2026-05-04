part of 'team_bloc.dart';

enum TeamMutationStatus { idle, inProgress, success, failure }

sealed class TeamState extends Equatable {
  const TeamState();

  @override
  List<Object?> get props => [];
}

final class TeamInitial extends TeamState {
  const TeamInitial();
}

final class TeamLoading extends TeamState {
  const TeamLoading();
}

final class TeamLoaded extends TeamState {
  final List<TeamModel> teams;
  final String? selectedTeamId;
  final TeamMutationStatus mutationStatus;
  final String? feedbackMessage;

  const TeamLoaded({
    required this.teams,
    this.selectedTeamId,
    this.mutationStatus = TeamMutationStatus.idle,
    this.feedbackMessage,
  });

  TeamLoaded copyWith({
    List<TeamModel>? teams,
    String? selectedTeamId,
    bool clearSelectedTeamId = false,
    TeamMutationStatus? mutationStatus,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return TeamLoaded(
      teams: teams ?? this.teams,
      selectedTeamId: clearSelectedTeamId
          ? null
          : (selectedTeamId ?? this.selectedTeamId),
      mutationStatus: mutationStatus ?? this.mutationStatus,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
    teams,
    selectedTeamId,
    mutationStatus,
    feedbackMessage,
  ];
}

final class TeamError extends TeamState {
  final String message;
  const TeamError(this.message);

  @override
  List<Object?> get props => [message];
}
