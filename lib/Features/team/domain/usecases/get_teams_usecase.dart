import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';

// FIX [P1]: extracted team loading behind a use case.
class GetTeamsUseCase {
  const GetTeamsUseCase(this._repository);

  final TeamRepository _repository;

  Future<List<TeamModel>> byGroup(
    String groupId, {
    bool includeArchived = false,
  }) {
    return _repository.getTeamsByGroup(
      groupId,
      includeArchived: includeArchived,
    );
  }

  Future<List<TeamModel>> all({bool includeArchived = false}) {
    return _repository.getAllTeams(includeArchived: includeArchived);
  }
}
