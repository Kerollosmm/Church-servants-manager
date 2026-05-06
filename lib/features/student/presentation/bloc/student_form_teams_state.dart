import 'package:church_management_system/features/team/data/models/team_model.dart';

class StudentFormTeamsState {
  final bool isLoading;
  final List<TeamModel> teams;
  final String? selectedTeamId;
  final String? errorMessage;

  const StudentFormTeamsState({
    this.isLoading = false,
    this.teams = const <TeamModel>[],
    this.selectedTeamId,
    this.errorMessage,
  });

  StudentFormTeamsState copyWith({
    bool? isLoading,
    List<TeamModel>? teams,
    String? selectedTeamId,
    bool clearSelectedTeamId = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return StudentFormTeamsState(
      isLoading: isLoading ?? this.isLoading,
      teams: teams ?? this.teams,
      selectedTeamId: clearSelectedTeamId
          ? null
          : (selectedTeamId ?? this.selectedTeamId),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
