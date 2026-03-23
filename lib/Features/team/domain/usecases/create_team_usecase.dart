import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';

// FIX [P1]: extracted team creation behind a use case.
class CreateTeamUseCase {
  const CreateTeamUseCase(this._repository);

  final TeamRepository _repository;

  Future<String> call(TeamModel team) {
    return _repository.createTeam(team);
  }
}
