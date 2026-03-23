import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';

// FIX [P1]: extracted team assignment/member orchestration behind a use case.
class AssignServantToTeamUseCase {
  const AssignServantToTeamUseCase(this._adminTeamService);

  final AdminTeamService _adminTeamService;

  Future<void> assign({
    required AuthUser actor,
    required TeamModel team,
    required ServantModel servant,
  }) {
    return _adminTeamService.assignServantToTeam(
      actor: actor,
      team: team,
      servant: servant,
    );
  }

  Future<void> unassign({required AuthUser actor, required TeamModel team}) {
    return _adminTeamService.unassignServantFromTeam(actor: actor, team: team);
  }

  Future<void> setMembers({
    required AuthUser actor,
    required TeamModel team,
    required List<StudentModel> students,
  }) {
    return _adminTeamService.setStudentsForTeam(
      actor: actor,
      team: team,
      selectedStudents: students,
    );
  }
}
