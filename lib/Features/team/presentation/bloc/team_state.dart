part of 'team_cubit.dart';

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

  const TeamLoaded({required this.teams, this.selectedTeamId});
}

class TeamError extends TeamState {
  final String message;
  const TeamError(this.message);
}

class TeamOperationSuccess extends TeamState {
  final String message;
  const TeamOperationSuccess(this.message);
}
