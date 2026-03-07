import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantLoadResult {
  final List<ServantModel> servants;
  final bool isFromCache;

  const ServantLoadResult({required this.servants, this.isFromCache = false});
}

class AssignServantDialog extends StatefulWidget {
  final AuthUser actor;
  final TeamModel team;
  final Future<ServantLoadResult> Function(String groupId) loadServantsForGroup;

  const AssignServantDialog({
    super.key,
    required this.actor,
    required this.team,
    required this.loadServantsForGroup,
  });

  @override
  State<AssignServantDialog> createState() => _AssignServantDialogState();
}

class _AssignServantDialogState extends State<AssignServantDialog> {
  late Future<ServantLoadResult> _servantsFuture;
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
    return FutureBuilder<ServantLoadResult>(
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
