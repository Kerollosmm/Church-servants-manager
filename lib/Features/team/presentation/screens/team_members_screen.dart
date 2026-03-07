import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/core/widgets/feedback/app_snackbars.dart';
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
  String? _loadError;
  bool _loadedFromCache = false;

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

  Future<_StudentsLoadResult> _loadStudentsForGroupWithFallback(
    String groupId,
  ) async {
    final studentRepo = context.read<StudentDataRepository>();
    final result = await studentRepo.getStudentsByGroupWithFallback(groupId);
    return _StudentsLoadResult(
      students: result.students,
      isFromCache: result.isFromCache,
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final team = widget.args.team;
      final result = await _loadStudentsForGroupWithFallback(team.groupId);
      final students = result.students;
      students.sort((a, b) => a.name.compareTo(b.name));

      _all = students;
      _loadedFromCache = result.isFromCache;
      _selected.clear();
      for (final s in students) {
        _selected[s.docID] = (s.classId == team.id);
      }
    } catch (e) {
      _all = [];
      _loadedFromCache = false;
      _loadError = 'فشل تحميل المخدومين: $e';
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
    if (_saving || _loading) return;

    final team = widget.args.team;
    final actor = widget.args.actor;

    final selectedStudents = _all
        .where((s) => (_selected[s.docID] ?? false) == true)
        .toList();

    setState(() => _saving = true);
    try {
      await context.read<TeamCubit>().setTeamMembers(
        actor: actor,
        team: team,
        students: selectedStudents,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.args.team;
    final filtered = _filtered;
    final selectedCount = _selected.values.where((v) => v == true).length;

    return BlocListener<TeamCubit, TeamState>(
      listener: (context, state) {
        if (state is TeamError) {
          setState(() => _saving = false);
          AppSnackbars.showError(context, state.message);
        }
        if (state is TeamOperationSuccess) {
          setState(() => _saving = false);
          AppSnackbars.showSuccess(
            context,
            state.message,
            backgroundColor: AppColors.secondary,
          );
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('الأعضاء • ${team.name}'),
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
              label: const Text('حفظ'),
              style: TextButton.styleFrom(foregroundColor: AppColors.white),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      AppSpacing.gapMd,
                      Text(_loadError!, textAlign: TextAlign.center),
                      AppSpacing.gapMd,
                      FilledButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  if (_loadedFromCache)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        0,
                      ),
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'وضع عدم الاتصال: يتم عرض البيانات المخزنة مؤقتا.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'ابحث عن مخدوم...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final s = filtered[index];
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
                          subtitle: Text('الصف ${s.grade}'),
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

class _StudentsLoadResult {
  final List<StudentModel> students;
  final bool isFromCache;

  const _StudentsLoadResult({required this.students, this.isFromCache = false});
}
