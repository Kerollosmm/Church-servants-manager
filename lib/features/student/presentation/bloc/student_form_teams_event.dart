import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:equatable/equatable.dart';

abstract class StudentFormTeamsEvent extends Equatable {
  const StudentFormTeamsEvent();

  @override
  List<Object?> get props => [];
}

class LoadTeamsForGroupEvent extends StudentFormTeamsEvent {
  final AuthUser actor;
  final String groupId;
  final String? preferredTeamId;
  final String? preferredTeamName;
  final String? currentSelection;

  const LoadTeamsForGroupEvent({
    required this.actor,
    required this.groupId,
    this.preferredTeamId,
    this.preferredTeamName,
    this.currentSelection,
  });

  @override
  List<Object?> get props => [
    actor,
    groupId,
    preferredTeamId,
    preferredTeamName,
    currentSelection,
  ];
}

class SelectTeamEvent extends StudentFormTeamsEvent {
  final String? teamId;

  const SelectTeamEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}
