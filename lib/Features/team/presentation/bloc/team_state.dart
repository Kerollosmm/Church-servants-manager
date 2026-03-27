part of 'team_cubit.dart';

enum TeamMutationStatus { idle, inProgress, success, failure }

abstract class TeamState {
  const TeamState();
}

class TeamInitial extends TeamState {
  const TeamInitial();
}

class TeamLoading extends TeamState {
  const TeamLoading();
}

class TeamLoaded extends TeamState {
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
}

class TeamError extends TeamState {
  final String message;
  const TeamError(this.message);
}
