import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_state.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceSessionCreateScreen extends StatefulWidget {
  const AttendanceSessionCreateScreen({super.key});

  @override
  State<AttendanceSessionCreateScreen> createState() =>
      _AttendanceSessionCreateScreenState();
}

class _AttendanceSessionCreateScreenState
    extends State<AttendanceSessionCreateScreen> {
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
      repository: context.read<AttendanceRepository>(),
    );
    _teamCubit = TeamCubit(
      teamRepository: context.read<TeamRepository>(),
      adminTeamService: context.read<AdminTeamService>(),
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
    } else if (teamIds.isNotEmpty) {
      _teamCubit.loadTeamsByIds(
        teamIds,
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
    if (pickedDate == null) return;
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
    if (pickedTime == null) return;
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
    if (_selectedTeamId != null || teams.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    if (durationMinutes == null || durationMinutes <= 0) {
      AppSnackbars.showError(context, 'أدخل مدة صحيحة أكبر من صفر.');
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
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(
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
                    final currentActor = _currentActorOrNull();
                    if (currentActor != null) {
                      Navigator.pushReplacementNamed(
                        context,
                        attendanceTaking,
                        arguments: AttendanceTakingArgs(
                          actor: currentActor,
                          teamId: state.session.teamId,
                          sessionId: state.session.id,
                        ),
                      );
                    } else {
                      AppSnackbars.showError(
                        context,
                        'تم إنشاء الجلسة لكن لم يتم التحقق من المستخدم.',
                      );
                      Navigator.pushReplacementNamed(context, login);
                    }
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

                      return ListView(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        children: [
                          const AppInfoBanner(
                            icon: Icons.auto_awesome,
                            message:
                                'الغياب لا يتم تسجيله يدويا. أي مخدوم غير محدد عند نهاية الجلسة يصبح غائبا تلقائيا.',
                          ),
                          AppSpacing.gapMd,
                          TeamDropdown(
                            teams: teams,
                            selectedTeamId: _selectedTeamId,
                            isLoading:
                                teamState is TeamLoading ||
                                teamState is TeamInitial,
                            errorMessage: teamState is TeamError
                                ? teamState.message
                                : null,
                            showAllOption: actor.role == UserRole.admin,
                            restrictToTeamIds: actor.role == UserRole.servant
                                ? actor.effectiveAssignedTeamIds
                                : null,
                            label: 'الفريق',
                            onChanged: (teamId) {
                              setState(() => _selectedTeamId = teamId);
                            },
                          ),
                          AppSpacing.gapMd,
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'عنوان الجلسة (اختياري)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          AppSpacing.gapMd,
                          TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'المدة بالدقائق',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          AppSpacing.gapMd,
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'بداية الجلسة',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  AppSpacing.gapSm,
                                  Text(_formatDateTime(_startsAt)),
                                  AppSpacing.gapMd,
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _pickDate,
                                          icon: const Icon(
                                            Icons.calendar_month,
                                          ),
                                          label: const Text('اختيار التاريخ'),
                                        ),
                                      ),
                                      AppSpacing.gapSm,
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _pickTime,
                                          icon: const Icon(Icons.access_time),
                                          label: const Text('اختيار الوقت'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AppSpacing.gapLg,
                          BlocBuilder<
                            AttendanceSessionAdminCubit,
                            AttendanceSessionAdminState
                          >(
                            builder: (context, state) {
                              final isLoading =
                                  state is AttendanceSessionAdminLoading;
                              return FilledButton.icon(
                                onPressed: isLoading
                                    ? null
                                    : () => _submit(actor, teams),
                                icon: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.playlist_add_check),
                                label: const Text('إنشاء الجلسة'),
                              );
                            },
                          ),
                        ],
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

String _formatDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
