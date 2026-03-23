import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/usecases/assign_servant_to_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/create_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/get_teams_usecase.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_management_system/features/team/presentation/widgets/assign_servant_dialog.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_management_body.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_name_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamManagementCoordinator extends StatefulWidget {
  const TeamManagementCoordinator({super.key});

  @override
  State<TeamManagementCoordinator> createState() =>
      _TeamManagementCoordinatorState();
}

class _TeamManagementCoordinatorState extends State<TeamManagementCoordinator>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TeamCubit _teamCubit;
  final _groups = Group.values;
  bool _showArchived = false;

  AuthUser? _currentActor() {
    final s = context.read<AuthBloc>().state;
    if (s is AuthAuthenticated) return s.user;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _teamCubit = TeamCubit(
      teamRepository: context.read<TeamRepository>(),
      adminTeamService: context.read<AdminTeamService>(),
      getTeamsUseCase: getIt<GetTeamsUseCase>(),
      createTeamUseCase: getIt<CreateTeamUseCase>(),
      assignServantToTeamUseCase: getIt<AssignServantToTeamUseCase>(),
    );
    _tabController = TabController(length: _groups.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTeamsForCurrentTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _teamCubit.close();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTeamsForCurrentTab();
    }
  }

  void _loadTeamsForCurrentTab() {
    final groupId = _groups[_tabController.index].name;
    _teamCubit.loadTeamsByGroup(groupId, includeArchived: _showArchived);
  }

  String _groupLabel(Group group) {
    switch (group) {
      case Group.year1:
        return 'السنة الأولى';
      case Group.year2:
        return 'السنة الثانية';
      case Group.year3:
        return 'السنة الثالثة';
    }
  }

  void _showAddTeamDialog() {
    final groupId = _groups[_tabController.index].name;
    _showTeamNameDialog(
      title: 'إضافة فريق إلى ${_groupLabel(_groups[_tabController.index])}',
      actionLabel: 'إنشاء',
      hintText: 'مثال: فريق مارمرقس',
      onSave: (name) {
        _teamCubit.createTeam(TeamModel(id: '', name: name, groupId: groupId));
      },
    );
  }

  void _showEditTeamDialog(TeamModel team) {
    _showTeamNameDialog(
      title: 'تعديل الفريق',
      actionLabel: 'حفظ',
      initialName: team.name,
      onSave: (name) => _teamCubit.updateTeam(team.copyWith(name: name)),
    );
  }

  void _showTeamNameDialog({
    required String title,
    required String actionLabel,
    String initialName = '',
    String? hintText,
    required ValueChanged<String> onSave,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => TeamNameDialog(
        title: title,
        actionLabel: actionLabel,
        initialName: initialName,
        hintText: hintText,
      ),
    );

    final trimmedName = name?.trim() ?? '';
    if (!mounted || trimmedName.isEmpty) return;
    onSave(trimmedName);
  }

  void _confirmDeleteTeam(TeamModel team) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('أرشفة الفريق'),
        content: Text(
          'سيتم إخفاء "${team.name}" من القوائم النشطة مع الاحتفاظ بالسجل التاريخي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              _teamCubit.deleteTeam(team.id, team.groupId);
              Navigator.pop(dialogContext);
            },
            child: const Text('أرشفة'),
          ),
        ],
      ),
    );
  }

  void _restoreTeam(TeamModel team) {
    _teamCubit.restoreTeam(team.id, team.groupId);
  }

  void _openManageMembers(TeamModel team) {
    final actor = _currentActor();
    if (actor == null) {
      AppSnackbars.showError(context, 'لم يتم العثور على مستخدم مسجل الدخول.');
      return;
    }
    Navigator.pushNamed(
      context,
      teamMembers,
      arguments: TeamMembersArgs(actor: actor, team: team),
    );
  }

  void _showAssignServantDialog(TeamModel team) {
    final actor = _currentActor();
    if (actor == null) {
      AppSnackbars.showError(context, 'لم يتم العثور على مستخدم مسجل الدخول.');
      return;
    }

    showDialog(
      context: context,
      builder: (_) => BlocProvider<TeamCubit>.value(
        value: _teamCubit,
        child: AssignServantDialog(actor: actor, team: team),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TeamCubit>.value(
      value: _teamCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_showArchived ? 'إدارة الفرق المؤرشفة' : 'إدارة الفرق'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              tooltip: _showArchived ? 'إخفاء المؤرشف' : 'عرض المؤرشف',
              icon: Icon(
                _showArchived
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
              ),
              onPressed: () {
                setState(() => _showArchived = !_showArchived);
                _loadTeamsForCurrentTab();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppColors.white,
            unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
            indicatorColor: AppColors.white,
            tabs: _groups.map((g) => Tab(text: _groupLabel(g))).toList(),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddTeamDialog,
          icon: const Icon(Icons.add),
          label: const Text('إضافة فريق'),
        ),
        body: TeamManagementBody(
          showArchived: _showArchived,
          onRefresh: () async => _loadTeamsForCurrentTab(),
          onEdit: _showEditTeamDialog,
          onDelete: _confirmDeleteTeam,
          onRestore: _restoreTeam,
          onAssignServant: _showAssignServantDialog,
          onManageMembers: _openManageMembers,
        ),
      ),
    );
  }
}
