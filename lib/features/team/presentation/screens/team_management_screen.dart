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

  Future<_ServantLoadResult> _loadServantsForGroup(String groupId) async {
    final servantRepo = context.read<ServantDataRepository>();
    final result = await servantRepo.getServantsByGroupWithFallback(groupId);
    return _ServantLoadResult(
      servants: result.servants,
      isFromCache: result.isFromCache,
    );
  }

  void _showAddTeamDialog() {
    final groupId = _groups[_tabController.index].name;
    _showTeamNameDialog(
      title: 'Add Team to ${_groupLabel(_groups[_tabController.index])}',
      actionLabel: 'Create',
      hintText: 'e.g. فريق مارمرقس',
      onSave: (name) {
        context.read<TeamCubit>().createTeam(
          TeamModel(id: '', name: name, groupId: groupId),
        );
      },
    );
  }

  void _showEditTeamDialog(TeamModel team) {
    _showTeamNameDialog(
      title: 'Edit Team',
      actionLabel: 'Save',
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
            labelText: 'Team Name',
            hintText: hintText,
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

    showDialog(
      context: context,
      builder: (_) => _AssignServantDialog(
        actor: actor,
        team: team,
        loadServantsForGroup: _loadServantsForGroup,
      ),
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

class _ServantLoadResult {
  final List<ServantModel> servants;
  final bool isFromCache;

  const _ServantLoadResult({required this.servants, this.isFromCache = false});
}

class _AssignServantDialog extends StatefulWidget {
  final AuthUser actor;
  final TeamModel team;
  final Future<_ServantLoadResult> Function(String groupId)
  loadServantsForGroup;

  const _AssignServantDialog({
    required this.actor,
    required this.team,
    required this.loadServantsForGroup,
  });

  @override
  State<_AssignServantDialog> createState() => _AssignServantDialogState();
}

class _AssignServantDialogState extends State<_AssignServantDialog> {
  late Future<_ServantLoadResult> _servantsFuture;
  String? _selectedId;
  var _selectionInitialized = false;

  @override
  void initState() {
    super.initState();
    _servantsFuture = widget.loadServantsForGroup(widget.team.groupId);
  }

  void _retryLoadServants() {
    setState(() {
      _servantsFuture = widget.loadServantsForGroup(widget.team.groupId);
      _selectionInitialized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ServantLoadResult>(
      future: _servantsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('Assign Servant'),
            content: Text('Failed to load servants: ${snapshot.error}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: _retryLoadServants,
                child: const Text('Retry'),
              ),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const AlertDialog(
            title: Text('Assign Servant'),
            content: SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final result = snapshot.data!;
        final uniqueServants = _uniqueServants(result.servants);

        if (!_selectionInitialized) {
          _selectedId = _normalizeToServantDocId(
            widget.team.assignedServantId,
            uniqueServants,
          );
          _selectionInitialized = true;
        }

        final items = <DropdownMenuItem<String?>>[
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('-- Unassigned --'),
          ),
          ...uniqueServants.map(
            (servant) => DropdownMenuItem<String?>(
              value: servant.docID,
              child: Text(servant.name),
            ),
          ),
        ];

        return AlertDialog(
          title: Text('Assign Servant - ${widget.team.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result.isFromCache)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'Offline mode: showing cached servants.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              DropdownButtonFormField<String?>(
                initialValue: _selectedId,
                isExpanded: true,
                items: items,
                onChanged: (value) => setState(() => _selectedId = value),
                decoration: const InputDecoration(
                  labelText: 'Responsible servant',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final selectedServant = _selectedServant(
                  uniqueServants,
                  _selectedId,
                );
                if (selectedServant == null) {
                  context.read<TeamCubit>().unassignServant(
                    actor: widget.actor,
                    team: widget.team,
                  );
                } else {
                  context.read<TeamCubit>().assignServant(
                    actor: widget.actor,
                    team: widget.team,
                    servant: selectedServant,
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  List<ServantModel> _uniqueServants(List<ServantModel> servants) {
    final uniqueServants = <ServantModel>[];
    final seenDocIds = <String>{};
    for (final servant in servants) {
      final docId = servant.docID.trim();
      if (docId.isEmpty || seenDocIds.contains(docId)) continue;
      seenDocIds.add(docId);
      uniqueServants.add(servant);
    }
    return uniqueServants;
  }

  String? _normalizeToServantDocId(String? rawId, List<ServantModel> servants) {
    if (rawId == null) return null;
    final id = rawId.trim();
    if (id.isEmpty) return null;

    for (final servant in servants) {
      if (servant.docID == id) return servant.docID;
    }
    for (final servant in servants) {
      if (servant.uid == id) return servant.docID;
    }
    return null;
  }

  ServantModel? _selectedServant(
    List<ServantModel> servants,
    String? selectedId,
  ) {
    if (selectedId == null) return null;
    for (final servant in servants) {
      if (servant.docID == selectedId) return servant;
    }
    return null;
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
            const PopupMenuItem(
              value: 'members',
              child: Text('Manage Members'),
            ),
            const PopupMenuItem(value: 'assign', child: Text('Assign Servant')),
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
