part of 'team_bloc.dart';

sealed class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => [];
}

class TeamLoadRequested extends TeamEvent {
  final String groupId;
  final String? defaultTeamId;
  final bool includeArchived;

  const TeamLoadRequested(
    this.groupId, {
    this.defaultTeamId,
    this.includeArchived = false,
  });

  @override
  List<Object?> get props => [groupId, defaultTeamId, includeArchived];
}

class TeamLoadAllRequested extends TeamEvent {
  final bool includeArchived;

  const TeamLoadAllRequested({this.includeArchived = false});

  @override
  List<Object?> get props => [includeArchived];
}

class TeamLoadByIdsRequested extends TeamEvent {
  final List<String> ids;
  final String? defaultTeamId;
  final bool includeArchived;

  const TeamLoadByIdsRequested(
    this.ids, {
    this.defaultTeamId,
    this.includeArchived = false,
  });

  @override
  List<Object?> get props => [ids, defaultTeamId, includeArchived];
}

class TeamCreateRequested extends TeamEvent {
  final TeamModel team;

  const TeamCreateRequested(this.team);

  @override
  List<Object?> get props => [team];
}

class TeamUpdateRequested extends TeamEvent {
  final TeamModel team;

  const TeamUpdateRequested(this.team);

  @override
  List<Object?> get props => [team];
}

class TeamDeleteRequested extends TeamEvent {
  final String teamId;
  final String groupId;

  const TeamDeleteRequested(this.teamId, this.groupId);

  @override
  List<Object?> get props => [teamId, groupId];
}

class TeamRestoreRequested extends TeamEvent {
  final String teamId;
  final String groupId;

  const TeamRestoreRequested(this.teamId, this.groupId);

  @override
  List<Object?> get props => [teamId, groupId];
}

class TeamSelected extends TeamEvent {
  final String? teamId;

  const TeamSelected(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class ServantAssignedToTeam extends TeamEvent {
  final AuthUser actor;
  final TeamModel team;
  final ServantModel servant;

  const ServantAssignedToTeam({
    required this.actor,
    required this.team,
    required this.servant,
  });

  @override
  List<Object?> get props => [actor, team, servant];
}

class ServantUnassignedFromTeam extends TeamEvent {
  final AuthUser actor;
  final TeamModel team;

  const ServantUnassignedFromTeam({required this.actor, required this.team});

  @override
  List<Object?> get props => [actor, team];
}

class TeamMembersSet extends TeamEvent {
  final AuthUser actor;
  final TeamModel team;
  final List<StudentModel> students;

  const TeamMembersSet({
    required this.actor,
    required this.team,
    required this.students,
  });

  @override
  List<Object?> get props => [actor, team, students];
}
