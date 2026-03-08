import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_state_message.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/team/presentation/widgets/assign_servant_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Admin screen for managing teams/classes within each year/group.
class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _groups = Group.values;

  AuthUser? _currentActor() {
    final s = context.read<AuthBloc>().state;
    if (s is AuthAuthenticated) return s.user;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _groups.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Load teams for the first tab
    _loadTeamsForCurrentTab();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTeamsForCurrentTab();
    }
  }

  void _loadTeamsForCurrentTab() {
    final groupId = _groups[_tabController.index].name;
    context.read<TeamCubit>().loadTeamsByGroup(groupId);
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
        context.read<TeamCubit>().createTeam(
          TeamModel(id: '', name: name, groupId: groupId),
        );
      },
    );
  }

  void _showEditTeamDialog(TeamModel team) {
    _showTeamNameDialog(
      title: 'تعديل الفريق',
      actionLabel: 'حفظ',
      initialName: team.name,
      onSave: (name) {
        context.read<TeamCubit>().updateTeam(team.copyWith(name: name));
      },
    );
  }

  void _showTeamNameDialog({
    required String title,
    required String actionLabel,
    String initialName = '',
    String? hintText,
    required ValueChanged<String> onSave,
  }) {
    final nameController = TextEditingController(text: initialName);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'اسم الفريق',
            hintText: hintText,
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              onSave(name);
              Navigator.pop(dialogContext);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    ).then((_) => nameController.dispose());
  }

  void _confirmDeleteTeam(TeamModel team) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الفريق'),
        content: Text('هل أنت متأكد من حذف "${team.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<TeamCubit>().deleteTeam(team.id, team.groupId);
              Navigator.pop(dialogContext);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
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
      builder: (_) => AssignServantDialog(actor: actor, team: team),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الفرق'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
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
      body: BlocConsumer<TeamCubit, TeamState>(
        listener: (context, state) {
          if (state is TeamError) {
            AppSnackbars.showError(context, state.message);
          }
          if (state is TeamLoaded &&
              state.feedbackMessage != null &&
              state.mutationStatus == TeamMutationStatus.success) {
            AppSnackbars.showSuccess(
              context,
              state.feedbackMessage!,
              backgroundColor: AppColors.secondary,
            );
          }
          if (state is TeamLoaded &&
              state.feedbackMessage != null &&
              state.mutationStatus == TeamMutationStatus.failure) {
            AppSnackbars.showError(context, state.feedbackMessage!);
          }
        },
        builder: (context, state) {
          if (state is TeamLoading || state is TeamInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TeamLoaded) {
            final teams = state.teams;
            if (teams.isEmpty) {
              return const AppStateMessage(
                icon: Icons.group_work_outlined,
                title: 'لا توجد فرق بعد',
                message: 'اضغط + لإنشاء فريق لهذه السنة.',
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadTeamsForCurrentTab(),
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: teams.length,
                separatorBuilder: (_, _) => AppSpacing.gapSm,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return _TeamCard(
                    team: team,
                    onEdit: () => _showEditTeamDialog(team),
                    onDelete: () => _confirmDeleteTeam(team),
                    onAssignServant: () => _showAssignServantDialog(team),
                    onManageMembers: () => _openManageMembers(team),
                  );
                },
              ),
            );
          }

          if (state is TeamError) {
            return AppStateMessage(
              icon: Icons.error_outline,
              iconColor: AppColors.error,
              title: 'تعذر تحميل الفرق',
              message: state.message,
              onRetry: _loadTeamsForCurrentTab,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssignServant;
  final VoidCallback onManageMembers;

  const _TeamCard({
    required this.team,
    required this.onEdit,
    required this.onDelete,
    required this.onAssignServant,
    required this.onManageMembers,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(Icons.group, color: AppColors.primary),
        ),
        title: Text(
          team.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: team.assignedServantName != null
            ? Text(
                'الخادم: ${team.assignedServantName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Text(
                'لا يوجد خادم مخصص',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'members') onManageMembers();
            if (value == 'assign') onAssignServant();
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'members', child: Text('إدارة الأعضاء')),
            const PopupMenuItem(value: 'assign', child: Text('تعيين خادم')),
            const PopupMenuItem(value: 'edit', child: Text('تعديل')),
            const PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }
}
