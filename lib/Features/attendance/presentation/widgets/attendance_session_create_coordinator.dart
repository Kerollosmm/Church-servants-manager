import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/session_create_form.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/usecases/assign_servant_to_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/create_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/get_teams_usecase.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceSessionCreateCoordinator extends StatefulWidget {
  const AttendanceSessionCreateCoordinator({super.key});

  @override
  State<AttendanceSessionCreateCoordinator> createState() =>
      _AttendanceSessionCreateCoordinatorState();
}

class _AttendanceSessionCreateCoordinatorState
    extends State<AttendanceSessionCreateCoordinator> {
  late final AttendanceSessionAdminCubit _cubit;
  late final TeamCubit _teamCubit;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(
    text: '30',
  );
  String? _selectedTeamId;
  DateTime _startsAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cubit = AttendanceSessionAdminCubit(
      repository: context.read<IAttendanceRepository>(),
    );
    _teamCubit = TeamCubit(
      teamRepository: context.read<TeamRepository>(),
      adminTeamService: context.read<AdminTeamService>(),
      getTeamsUseCase: getIt<GetTeamsUseCase>(),
      createTeamUseCase: getIt<CreateTeamUseCase>(),
      assignServantToTeamUseCase: getIt<AssignServantToTeamUseCase>(),
    );
    final actor = _currentActorOrNull();
    if (actor != null) {
      _loadTeamsForActor(actor);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    _teamCubit.close();
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  AuthUser? _currentActorOrNull() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    return null;
  }

  void _loadTeamsForActor(AuthUser actor) {
    if (actor.role == UserRole.admin) {
      _teamCubit.loadAllTeams();
      return;
    }

    final teamIds = actor.effectiveAssignedTeamIds;
    if (teamIds.length == 1) {
      _selectedTeamId ??= teamIds.first;
    }

    final groupId = actor.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      _teamCubit.loadTeamsByGroup(
        groupId,
        defaultTeamId: teamIds.length == 1 ? teamIds.first : null,
      );
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate == null) {
      return;
    }
    setState(() {
      _startsAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _startsAt.hour,
        _startsAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (pickedTime == null) {
      return;
    }
    setState(() {
      _startsAt = DateTime(
        _startsAt.year,
        _startsAt.month,
        _startsAt.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _ensureInitialTeam(List<TeamModel> teams) {
    if (_selectedTeamId != null || teams.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _selectedTeamId = teams.first.id);
    });
  }

  Future<void> _submit(AuthUser actor, List<TeamModel> teams) async {
    final teamId = _selectedTeamId;
    if (teamId == null || teamId.isEmpty) {
      AppSnackbars.showError(context, 'اختر الفريق قبل إنشاء الجلسة.');
      return;
    }

    final durationMinutes = int.tryParse(_durationController.text.trim());
    if (durationMinutes == null) {
      AppSnackbars.showError(context, 'أدخل مدة صحيحة بالدقائق.');
      return;
    }

    final selectedTeam = teams.firstWhere(
      (team) => team.id == teamId,
      orElse: () => TeamModel(id: teamId, name: 'الفريق', groupId: ''),
    );

    await _cubit.createSession(
      actor: actor,
      teamId: teamId,
      teamNameSnapshot: selectedTeam.name,
      startsAt: _startsAt,
      durationMinutes: durationMinutes,
      title: _titleController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final actor = _currentActorOrNull();
        if (actor == null ||
            (actor.role != UserRole.admin && actor.role != UserRole.servant)) {
          return const Scaffold(
            body: Center(
              child: Text('هذه الشاشة متاحة للمسؤول أو الخادم المخصص فقط.'),
            ),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider<TeamCubit>.value(value: _teamCubit),
            BlocProvider<AttendanceSessionAdminCubit>.value(value: _cubit),
          ],
          child:
              BlocListener<
                AttendanceSessionAdminCubit,
                AttendanceSessionAdminState
              >(
                listener: (context, state) {
                  if (state is AttendanceSessionAdminError) {
                    AppSnackbars.showError(context, state.message);
                    return;
                  }
                  if (state is AttendanceSessionAdminSuccess) {
                    AppSnackbars.showSuccess(context, state.message);
                    Navigator.pushReplacementNamed(
                      context,
                      attendanceTaking,
                      arguments: AttendanceTakingArgs(
                        actor: actor,
                        teamId: state.session.teamId,
                        sessionId: state.session.id,
                      ),
                    );
                  }
                },
                child: Scaffold(
                  appBar: AppBar(title: const Text('إنشاء جلسة حضور')),
                  body: BlocBuilder<TeamCubit, TeamState>(
                    builder: (context, teamState) {
                      final teams = teamState is TeamLoaded
                          ? teamState.teams
                          : const <TeamModel>[];
                      _ensureInitialTeam(teams);

                      return BlocBuilder<
                        AttendanceSessionAdminCubit,
                        AttendanceSessionAdminState
                      >(
                        builder: (context, sessionState) {
                          return SessionCreateForm(
                            actor: actor.role,
                            teams: actor.role == UserRole.servant
                                ? teams
                                      .where(
                                        (team) => actor.effectiveAssignedTeamIds
                                            .contains(team.id),
                                      )
                                      .toList(growable: false)
                                : teams,
                            selectedTeamId: _selectedTeamId,
                            isTeamsLoading:
                                teamState is TeamLoading ||
                                teamState is TeamInitial,
                            teamsErrorMessage: teamState is TeamError
                                ? teamState.message
                                : null,
                            titleController: _titleController,
                            durationController: _durationController,
                            startsAt: _startsAt,
                            isSubmitting:
                                sessionState is AttendanceSessionAdminLoading,
                            onTeamChanged: (teamId) {
                              setState(() => _selectedTeamId = teamId);
                            },
                            onPickDate: _pickDate,
                            onPickTime: _pickTime,
                            onSubmit: () => _submit(actor, teams),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
        );
      },
    );
  }
}
