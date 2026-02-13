import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
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
        return 'Year 1';
      case Group.year2:
        return 'Year 2';
      case Group.year3:
        return 'Year 3';
    }
  }

  void _showAddTeamDialog() {
    final nameController = TextEditingController();
    final groupId = _groups[_tabController.index].name;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Add Team to ${_groupLabel(_groups[_tabController.index])}',
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Team Name',
            hintText: 'e.g. فريق مارمرقس',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              context.read<TeamCubit>().createTeam(
                TeamModel(id: '', name: name, groupId: groupId),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditTeamDialog(TeamModel team) {
    final nameController = TextEditingController(text: team.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Team'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Team Name'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              context.read<TeamCubit>().updateTeam(team.copyWith(name: name));
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTeam(TeamModel team) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<TeamCubit>().deleteTeam(team.id, team.groupId);
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openManageMembers(TeamModel team) {
    final actor = _currentActor();
    if (actor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found.')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found.')),
      );
      return;
    }

    final repo = context.read<ServantDataRepository>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return FutureBuilder<List<ServantModel>>(
          future: repo.getServantsByTeam(team.groupId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AlertDialog(
                title: Text('Assign Servant'),
                content: SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final servants = snapshot.data ?? <ServantModel>[];
            final items = <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('— Unassigned —'),
              ),
              ...servants.map(
                (s) => DropdownMenuItem<String?>(
                  value: s.docID,
                  child: Text(s.name),
                ),
              ),
            ];

            String? selectedId = team.assignedServantId;

            ServantModel? selectedServant() {
              if (selectedId == null) return null;
              try {
                return servants.firstWhere((s) => s.docID == selectedId);
              } catch (_) {
                return null;
              }
            }

            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  title: Text('Assign Servant • ${team.name}'),
                  content: DropdownButtonFormField<String?>(
                    value: selectedId,
                    isExpanded: true,
                    items: items,
                    onChanged: (v) => setState(() => selectedId = v),
                    decoration: const InputDecoration(
                      labelText: 'Responsible servant',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        final s = selectedServant();
                        if (s == null) {
                          context.read<TeamCubit>().unassignServant(
                                actor: actor,
                                team: team,
                              );
                        } else {
                          context.read<TeamCubit>().assignServant(
                                actor: actor,
                                team: team,
                                servant: s,
                              );
                        }
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Teams'),
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
        label: const Text('Add Team'),
      ),
      body: BlocConsumer<TeamCubit, TeamState>(
        listener: (context, state) {
          if (state is TeamError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is TeamOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.secondary,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TeamLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TeamLoaded) {
            final teams = state.teams;
            if (teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_work_outlined,
                      size: 64,
                      color: AppColors.outline,
                    ),
                    AppSpacing.gapMd,
                    Text(
                      'No teams yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    AppSpacing.gapSm,
                    Text(
                      'Tap + to create a team for this year.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  AppSpacing.gapMd,
                  Text(state.message),
                  AppSpacing.gapMd,
                  FilledButton.icon(
                    onPressed: _loadTeamsForCurrentTab,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
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
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: team.assignedServantName != null
            ? Text(
                'Servant: ${team.assignedServantName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              )
            : Text(
                'No servant assigned',
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
            const PopupMenuItem(value: 'members', child: Text('Manage Members')),
            const PopupMenuItem(value: 'assign', child: Text('Assign Servant')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
