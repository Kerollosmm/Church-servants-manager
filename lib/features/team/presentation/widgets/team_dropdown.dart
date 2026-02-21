import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Reusable dropdown widget for selecting a team.
///
/// Loads teams from [TeamCubit] for a given [groupId].
/// - Admin: sees "All Teams" option + individual teams
/// - Servant: sees teams for their group; defaults to [defaultTeamId]
class TeamDropdown extends StatefulWidget {
  /// The group/year to load teams for (e.g. "year1").
  final String groupId;

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
    required this.groupId,
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
  late Stream<List<TeamModel>> _teamsStream;

  @override
  void initState() {
    super.initState();
    _selectedTeamId = widget.defaultTeamId;
    _teamsStream = context.read<TeamRepository>().watchTeamsByGroup(
      widget.groupId,
    );
  }

  @override
  void didUpdateWidget(covariant TeamDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _teamsStream = context.read<TeamRepository>().watchTeamsByGroup(
        widget.groupId,
      );
    }
    if (oldWidget.defaultTeamId != widget.defaultTeamId ||
        oldWidget.groupId != widget.groupId) {
      _selectedTeamId = widget.defaultTeamId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamModel>>(
      stream: _teamsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Failed to load teams.',
              style: TextStyle(
                color: AppColors.error,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        final teams = snapshot.data ?? <TeamModel>[];
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
              'No teams available for this year.',
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
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Teams'),
            ),
          );
        }

        for (final team in visibleTeams) {
          items.add(
            DropdownMenuItem<String?>(value: team.id, child: Text(team.name)),
          );
        }

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
      },
    );
  }
}
