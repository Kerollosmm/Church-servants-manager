import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reusable dropdown widget for selecting a team.
///
/// Loads teams from [TeamCubit] for a given [groupId].
/// - Admin: sees "All Teams" option + individual teams
/// - Servant: sees teams for their group; defaults to [defaultTeamId]
class TeamDropdown extends StatefulWidget {
  /// The group/year to load teams for (e.g. "year1"). If null, loads all teams.
  final String? groupId;

  /// Pre-selected team ID (optional). Used for servant auto-selection.
  final String? defaultTeamId;

  /// Whether to show an "All Teams" option (usually for admins).
  final bool showAllOption;

  /// Callback when the selected team changes. Null means "All Teams".
  final ValueChanged<String?> onChanged;

  /// If provided, the dropdown will only show this team.
  /// Useful to lock servants to their assigned team.
  final String? restrictToTeamId;

  /// If provided, the dropdown will only show teams in this list.
  /// Useful to lock servants to multiple assigned teams.
  final List<String>? restrictToTeamIds;

  /// Custom label (optional).
  final String? label;

  const TeamDropdown({
    super.key,
    this.groupId,
    required this.onChanged,
    this.defaultTeamId,
    this.showAllOption = false,
    this.label,
    this.restrictToTeamId,
    this.restrictToTeamIds,
  });

  @override
  State<TeamDropdown> createState() => _TeamDropdownState();
}

class _TeamDropdownState extends State<TeamDropdown> {
  String? _selectedTeamId;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.defaultTeamId;
    if (widget.groupId == null) {
      context.read<TeamCubit>().loadAllTeams();
    } else {
      context.read<TeamCubit>().loadTeamsByGroup(
        widget.groupId!,
        defaultTeamId: widget.defaultTeamId,
      );
    }
  }

  @override
  void didUpdateWidget(covariant TeamDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      if (widget.groupId == null) {
        context.read<TeamCubit>().loadAllTeams();
      } else {
        context.read<TeamCubit>().loadTeamsByGroup(
          widget.groupId!,
          defaultTeamId: widget.defaultTeamId,
        );
      }
    }
    if (oldWidget.defaultTeamId != widget.defaultTeamId ||
        oldWidget.groupId != widget.groupId) {
      _selectedTeamId = widget.defaultTeamId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamLoaded &&
            _selectedTeamId == null &&
            state.selectedTeamId != null) {
          setState(() {
            _selectedTeamId = state.selectedTeamId;
          });
        }
      },
      builder: (context, state) {
        if (state is TeamLoading || state is TeamInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        if (state is TeamError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              state.message,
              style: TextStyle(
                color: AppColors.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        if (state is TeamLoaded) {
          final teams = state.teams;
          final restrictedTeamIds = <String>{};
          if (widget.restrictToTeamId != null &&
              widget.restrictToTeamId!.isNotEmpty) {
            restrictedTeamIds.add(widget.restrictToTeamId!);
          }
          for (final id in widget.restrictToTeamIds ?? const <String>[]) {
            if (id.isNotEmpty) {
              restrictedTeamIds.add(id);
            }
          }

          final visibleTeams = restrictedTeamIds.isEmpty
              ? teams
              : teams.where((t) => restrictedTeamIds.contains(t.id)).toList();

          if (visibleTeams.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                widget.groupId == null
                    ? 'No teams available.'
                    : 'No teams available for this year.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }

          // Build dropdown items
          final items = <DropdownMenuItem<String?>>[];

          if (widget.showAllOption) {
            items.add(
              DropdownMenuItem<String?>(
                value: null,
                child: SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('All Teams'),
                  ),
                ),
              ),
            );
          }

          items.addAll(
            visibleTeams.map((team) {
              return DropdownMenuItem<String?>(
                value: team.id,
                child: SizedBox(
                  height: 48,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(team.name),
                  ),
                ),
              );
            }),
          );

          // Ensure selected value is valid
          final validIds = visibleTeams.map((t) => t.id).toSet();
          final effectiveValue =
              (_selectedTeamId != null && validIds.contains(_selectedTeamId))
              ? _selectedTeamId
              : (widget.showAllOption ? null : visibleTeams.first.id);

          return DropdownButtonFormField<String?>(
            initialValue: effectiveValue,
            decoration: InputDecoration(
              labelText: widget.label ?? 'Team',
              prefixIcon: const Icon(Icons.group),
            ),
            items: items,
            onChanged: (value) {
              setState(() => _selectedTeamId = value);
              widget.onChanged(value);
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
