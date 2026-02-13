import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Admin-only screen: pick which students belong to a specific team.
///
/// The screen shows all students in the same group/year as the team.
/// Checked students will be assigned to the team on Save.
class TeamMembersScreen extends StatefulWidget {
  final TeamMembersArgs args;

  const TeamMembersScreen({super.key, required this.args});

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  final _searchController = TextEditingController();
  final Map<String, bool> _selected = {};

  List<StudentModel> _all = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<StudentDataRepository>();
      final team = widget.args.team;
      final students = await repo.getStudentsByGroup(team.groupId);
      students.sort((a, b) => a.name.compareTo(b.name));

      _all = students;
      _selected.clear();
      for (final s in students) {
        _selected[s.docID] = (s.classId == team.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load students: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<StudentModel> get _filtered {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _save() async {
    final team = widget.args.team;
    final actor = widget.args.actor;

    final selectedStudents = _all
        .where((s) => (_selected[s.docID] ?? false) == true)
        .toList();

    setState(() => _saving = true);
    context.read<TeamCubit>().setTeamMembers(
          actor: actor,
          team: team,
          students: selectedStudents,
        );
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.args.team;
    final selectedCount = _selected.values.where((v) => v == true).length;

    return BlocListener<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamError) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is TeamOperationSuccess) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.secondary),
          );
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Members • ${team.name}'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Center(
                child: Text(
                  '$selectedCount',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: (_loading || _saving) ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search students...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = _filtered[index];
                        final isChecked = _selected[s.docID] ?? false;

                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: _saving
                              ? null
                              : (val) {
                                  setState(() {
                                    _selected[s.docID] = val ?? false;
                                  });
                                },
                          title: Text(s.name),
                          subtitle: Text('Grade ${s.grade}'),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
