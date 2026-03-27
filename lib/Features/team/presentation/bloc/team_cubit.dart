import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/usecases/assign_servant_to_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/create_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/get_teams_usecase.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'team_state.dart';
part 'team_cubit_actions.dart';

/// Cubit for managing team/class data.
/// - Admin: full CRUD across all groups
/// - Servant: load teams for their group
class TeamCubit extends Cubit<TeamState> {
  TeamCubit({
    required TeamRepository teamRepository,
    required AdminTeamService adminTeamService,
    GetTeamsUseCase? getTeamsUseCase,
    CreateTeamUseCase? createTeamUseCase,
    AssignServantToTeamUseCase? assignServantToTeamUseCase,
  }) : _teamRepository = teamRepository,
       _getTeamsUseCase = getTeamsUseCase ?? GetTeamsUseCase(teamRepository),
       _createTeamUseCase =
           createTeamUseCase ?? CreateTeamUseCase(teamRepository),
       _assignServantToTeamUseCase =
           assignServantToTeamUseCase ??
           AssignServantToTeamUseCase(adminTeamService),
       super(const TeamInitial());

  final TeamRepository _teamRepository;
  final GetTeamsUseCase _getTeamsUseCase;
  final CreateTeamUseCase _createTeamUseCase;
  final AssignServantToTeamUseCase _assignServantToTeamUseCase;
  List<TeamModel> _currentTeams = const [];
  String? _selectedTeamId;
  bool _includeArchived = false;
}
