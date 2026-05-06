import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:equatable/equatable.dart';

abstract class TeamMembersEvent extends Equatable {
  const TeamMembersEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeamMembersEvent extends TeamMembersEvent {
  final String groupId;
  final String teamId;

  const LoadTeamMembersEvent({required this.groupId, required this.teamId});

  @override
  List<Object?> get props => [groupId, teamId];
}

class SearchTeamMembersEvent extends TeamMembersEvent {
  final String query;

  const SearchTeamMembersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class ToggleSelectionEvent extends TeamMembersEvent {
  final String studentId;
  final bool isSelected;

  const ToggleSelectionEvent({
    required this.studentId,
    required this.isSelected,
  });

  @override
  List<Object?> get props => [studentId, isSelected];
}

class SaveMembersEvent extends TeamMembersEvent {
  final AuthUser actor;
  final TeamModel team;
  final List<StudentModel> selectedStudents;

  const SaveMembersEvent({
    required this.actor,
    required this.team,
    required this.selectedStudents,
  });

  @override
  List<Object?> get props => [actor, team, selectedStudents];
}
