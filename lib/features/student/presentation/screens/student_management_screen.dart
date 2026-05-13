import 'dart:async';
import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/utils/data_export_service.dart';
import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/core/widgets/app_error_state.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/ochre_card.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/core/widgets/search/live_search_panel.dart';
import 'package:church_management_system/core/widgets/sync_status_banner.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_bloc.dart';
import 'package:church_management_system/features/team/presentation/widgets/team_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  String? _selectedTeamId;
  bool _showArchived = false;
  late final StudentDataBloc _studentDataBloc;
  late final TeamBloc _teamCubit;
  final DataExportService _exportService = DataExportService();

  @override
  void initState() {
    super.initState();
    _studentDataBloc = context.read<StudentDataBloc>();
    _teamCubit = TeamBloc(
      teamRepository: getIt<TeamRepository>(),
      adminTeamService: getIt<AdminTeamService>(),
    );
    final actor = _currentActorOrNull();
    if (actor != null) {
      _selectedTeamId =
          actor.role == UserRole.servant &&
              actor.effectiveAssignedTeamIds.length == 1
          ? actor.effectiveAssignedTeamIds.first
          : null;
      _studentDataBloc.add(
        StudentsLoadRequested(
          actor: actor,
          teamId: _selectedTeamId,
          includeArchived: _showArchived,
        ),
      );
      _loadTeamsForActor(actor);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _studentDataBloc.add(const StudentsListeningStopped());
    _teamCubit.close();
    _searchController.dispose();
    super.dispose();
  }

  AuthUser? _currentActorOrNull() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    return null;
  }

  void _onSearchChanged(AuthUser actor, String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _dispatchSearch(actor, value, teamId: _selectedTeamId);
      }
    });
  }

  void _clearSearch(AuthUser actor) {
    _searchController.clear();
    _dispatchSearch(actor, '', teamId: _selectedTeamId);
  }

  void _dispatchSearch(AuthUser actor, String query, {String? teamId}) {
    context.read<StudentDataBloc>().add(
      StudentsSearchRequested(
        actor: actor,
        query: query,
        teamId: teamId,
        includeArchived: _showArchived,
      ),
    );
  }

  void _onTeamFilterChanged(AuthUser actor, String? teamId) {
    _selectedTeamId = teamId;
    _teamCubit.add(TeamSelected(teamId));
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _dispatchSearch(actor, query, teamId: teamId);
    } else {
      context.read<StudentDataBloc>().add(
        StudentsLoadRequested(
          actor: actor,
          teamId: teamId,
          includeArchived: _showArchived,
        ),
      );
    }
  }

  Future<void> _openStudentEditor(
    AuthUser actor, {
    StudentModel? student,
  }) async {
    final result = await Navigator.pushNamed(
      context,
      studentEdit,
      arguments: StudentEditArgs(actor: actor, student: student),
    );
    if (!mounted || result != true) return;
    await context.read<StudentDataBloc>().refresh(actor);
  }

  Future<void> _openStudentDetail(AuthUser actor, StudentModel student) async {
    final result = await Navigator.pushNamed(
      context,
      studentDetail,
      arguments: StudentDetailArgs(actor: actor, student: student),
    );
    if (!mounted || result != true) return;
    await context.read<StudentDataBloc>().refresh(actor);
  }

  void _loadTeamsForActor(AuthUser actor) {
    if (actor.role == UserRole.admin) {
      _teamCubit.add(const TeamLoadAllRequested());
      return;
    }
    final groupId = actor.groupId;
    if (groupId != null && groupId.isNotEmpty) {
      _teamCubit.add(
        TeamLoadRequested(
          groupId,
          defaultTeamId: actor.effectiveAssignedTeamIds.length == 1
              ? actor.effectiveAssignedTeamIds.first
              : null,
        ),
      );
    }
  }

  bool _canManage(AuthUser actor) =>
      actor.role == UserRole.admin || actor.role == UserRole.servant;

  _StudentListViewData _buildViewData(StudentDataState state) {
    final isLoading = state is StudentDataLoading;
    final students = switch (state) {
      StudentDataLoaded() => state.students,
      StudentDataLoading() => state.previousStudents,
      _ => const <StudentModel>[],
    };
    final showInitialLoading =
        state is StudentDataLoading && !state.hasPreviousStudents;

    final isFromCache = switch (state) {
      StudentDataLoaded() => state.isFromCache,
      _ => false,
    };

    return _StudentListViewData(
      isLoading: isLoading,
      students: students,
      showInitialLoading: showInitialLoading,
      showEmptyState: state is StudentDataLoaded && state.students.isEmpty,
      isFromCache: isFromCache,
    );
  }

  Future<void> _onExport() async {
    final state = _studentDataBloc.state;
    if (state is! StudentDataLoaded) return;

    final format = await showGenericDialog<String>(
      context: context,
      title: 'تصدير البيانات',
      content: 'اختر تنسيق الملف للتصدير:',
      optionBuilder: () => {'Excel (CSV)': 'csv', 'PDF': 'pdf', 'إلغاء': null},
    );

    if (format == null || !mounted) return;

    final headers = ['الاسم', 'المجموعة', 'الصف', 'الموبايل'];
    final rows = state.students
        .map((s) => [s.name, s.group.name, s.grade, s.mobile])
        .toList();

    try {
      if (format == 'csv') {
        await _exportService.exportCsv(
          fileName: 'students_export',
          headers: headers,
          rows: rows,
        );
      } else if (format == 'pdf') {
        await _exportService.exportPdf(
          title: 'قائمة المخدومين',
          fileName: 'students_report',
          headers: headers,
          rows: rows,
        );
      }
    } catch (e, stack) {
      developer.log(
        'Export failed',
        error: e,
        stackTrace: stack,
        name: 'StudentManagementScreen',
      );
      if (mounted) AppSnackbars.showError(context, 'فشل تصدير البيانات');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AuthBloc, AuthState, AuthUser?>(
      selector: (state) => switch (state) {
        AuthAuthenticated() => state.user,
        AuthDegraded() => state.user,
        _ => null,
      },
      builder: (context, actor) {
        if (actor == null) {
          return const Scaffold(
            body: Center(child: Text('لم يتم تسجيل الدخول.')),
          );
        }
        final assignedTeamIds = actor.effectiveAssignedTeamIds;

        return BlocProvider<TeamBloc>.value(
          value: _teamCubit,
          child: SanctuaryBackground(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  _showArchived
                      ? 'المخدومون المؤرشفون'
                      : (actor.role == UserRole.admin
                            ? 'إدارة المخدومين'
                            : 'مخدومي'),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'تصدير',
                    onPressed: _onExport,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'تحديث',
                    onPressed: () {
                      context.read<StudentDataBloc>().refresh(actor);
                    },
                  ),
                ],
              ),
              floatingActionButton: _canManage(actor)
                  ? FloatingActionButton.extended(
                      onPressed: () {
                        _openStudentEditor(actor);
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('إضافة مخدوم'),
                    )
                  : null,
              body: BlocConsumer<StudentDataBloc, StudentDataState>(
                buildWhen: (prev, curr) {
                  if (prev.runtimeType != curr.runtimeType) return true;
                  if (curr is StudentDataLoaded && prev is StudentDataLoaded) {
                    return prev.students != curr.students ||
                        prev.mutationStatus != curr.mutationStatus;
                  }
                  return true;
                },
                listener: (context, state) {
                  if (state is StudentDataError) {
                    AppSnackbars.showError(context, state.message);
                  }
                  if (state is StudentDataLoaded &&
                      state.successMessage != null) {
                    if (state.mutationStatus != StudentMutationStatus.success) {
                      return;
                    }
                    AppSnackbars.showSuccess(
                      context,
                      state.successMessage!,
                      backgroundColor: AppColors.secondary,
                    );
                  }
                },
                builder: (context, state) {
                  final viewData = _buildViewData(state);

                  return Column(
                    children: [
                      const SyncStatusBanner(),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              context.read<StudentDataBloc>().refresh(actor),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _SearchHeaderDelegate(
                                  searchController: _searchController,
                                  isLoading: viewData.isLoading,
                                  actor: actor,
                                  assignedTeamIds: assignedTeamIds,
                                  selectedTeamId: _selectedTeamId,
                                  showArchived: _showArchived,
                                  onSearchChanged: (v) =>
                                      _onSearchChanged(actor, v),
                                  onSearchSubmitted: (v) => _dispatchSearch(
                                    actor,
                                    v,
                                    teamId: _selectedTeamId,
                                  ),
                                  onSearchClear: () => _clearSearch(actor),
                                  onTeamChanged: (id) =>
                                      _onTeamFilterChanged(actor, id),
                                  onArchiveToggle: () {
                                    setState(
                                      () => _showArchived = !_showArchived,
                                    );
                                    context.read<StudentDataBloc>().add(
                                      StudentsLoadRequested(
                                        actor: actor,
                                        teamId: _selectedTeamId,
                                        includeArchived: _showArchived,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              if (viewData.showInitialLoading)
                                const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (state is StudentDataError)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: AppErrorState(
                                    message: state.message,
                                    onRetry: () =>
                                        context.read<StudentDataBloc>().add(
                                          StudentsLoadRequested(
                                            actor: actor,
                                            teamId: _selectedTeamId,
                                            includeArchived: _showArchived,
                                          ),
                                        ),
                                  ),
                                )
                              else if (viewData.showEmptyState)
                                SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: AppEmptyState(
                                    title: _showArchived
                                        ? 'لا يوجد مخدومون مؤرشفون'
                                        : 'لا يوجد مخدومون',
                                    subtitle: viewData.isFromCache
                                        ? 'يرجى الاتصال بالإنترنت لتحميل البيانات لأول مرة.'
                                        : (_showArchived
                                              ? 'عند أرشفة مخدوم سيظهر هنا.'
                                              : 'جرّب بحثا مختلفا أو أضف مخدوما جديدا.'),
                                    onAction:
                                        _canManage(actor) &&
                                            !viewData.isFromCache
                                        ? () => _openStudentEditor(actor)
                                        : null,
                                    actionLabel: 'إضافة مخدوم',
                                    onRefresh: () => context
                                        .read<StudentDataBloc>()
                                        .refresh(actor),
                                  ),
                                )
                              else ...[
                                if (viewData.isFromCache)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        0,
                                      ),
                                      child: AppInfoBanner(
                                        icon: Icons.cloud_off,
                                        backgroundColor: Colors.amber.shade100,
                                        foregroundColor: Colors.amber.shade900,
                                        message:
                                            'عرض البيانات المخزنة محلياً. قد لا تكون محدثة.',
                                      ),
                                    ),
                                  ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate((
                                    context,
                                    index,
                                  ) {
                                    final student = viewData.students[index];
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        0,
                                      ),
                                      child: _StudentCard(
                                        key: ValueKey(student.docID),
                                        actor: actor,
                                        student: student,
                                        onTap: () =>
                                            _openStudentDetail(actor, student),
                                      ),
                                    );
                                  }, childCount: viewData.students.length),
                                ),
                              ],
                            ],
                          ),
                        ),
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

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final bool isLoading;
  final AuthUser actor;
  final List<String> assignedTeamIds;
  final String? selectedTeamId;
  final bool showArchived;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onSearchClear;
  final ValueChanged<String?> onTeamChanged;
  final VoidCallback onArchiveToggle;

  _SearchHeaderDelegate({
    required this.searchController,
    required this.isLoading,
    required this.actor,
    required this.assignedTeamIds,
    required this.selectedTeamId,
    required this.showArchived,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onSearchClear,
    required this.onTeamChanged,
    required this.onArchiveToggle,
  });

  @override
  double get minExtent => 200;
  @override
  double get maxExtent => 200;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.9),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          LiveSearchPanel(
            controller: searchController,
            label: 'ابحث باسم المخدوم',
            hint: 'ابحث بالاسم',
            clearTooltip: 'مسح',
            liveLabel: 'متصل بـ Firestore',
            isLoading: isLoading,
            onChanged: onSearchChanged,
            onSubmitted: onSearchSubmitted,
            onClear: onSearchClear,
          ),
          AppSpacing.gapSm,
          Row(
            children: [
              Expanded(
                child: BlocBuilder<TeamBloc, TeamState>(
                  builder: (context, teamState) {
                    final teams = teamState is TeamLoaded
                        ? teamState.teams
                        : const <TeamModel>[];
                    final loading =
                        teamState is TeamLoading || teamState is TeamInitial;
                    final errorMessage = teamState is TeamError
                        ? teamState.message
                        : null;

                    return TeamDropdown(
                      teams: teams,
                      selectedTeamId: selectedTeamId,
                      isLoading: loading,
                      errorMessage: errorMessage,
                      showAllOption:
                          actor.role == UserRole.admin ||
                          (actor.role == UserRole.servant &&
                              assignedTeamIds.length > 1),
                      restrictToTeamIds:
                          actor.role == UserRole.servant &&
                              assignedTeamIds.isNotEmpty
                          ? assignedTeamIds
                          : null,
                      label: 'تصفية حسب الفريق',
                      onChanged: onTeamChanged,
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilterChip(
                label: const Text('المؤرشف'),
                selected: showArchived,
                onSelected: (_) => onArchiveToggle(),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return oldDelegate.isLoading != isLoading ||
        oldDelegate.selectedTeamId != selectedTeamId ||
        oldDelegate.showArchived != showArchived;
  }
}

class _StudentListViewData {
  final bool isLoading;
  final List<StudentModel> students;
  final bool showInitialLoading;
  final bool showEmptyState;
  final bool isFromCache;

  const _StudentListViewData({
    required this.isLoading,
    required this.students,
    required this.showInitialLoading,
    required this.showEmptyState,
    required this.isFromCache,
  });
}

class _StudentCard extends StatelessWidget {
  final AuthUser actor;
  final StudentModel student;
  final VoidCallback onTap;

  const _StudentCard({
    super.key,
    required this.actor,
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OchreCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          student.isArchived
              ? 'مؤرشف'
              : 'المجموعة ${student.group.displayName} • الصف ${student.grade}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Directionality.of(context) == TextDirection.rtl
              ? Icons.arrow_back_ios_new_rounded
              : Icons.arrow_forward_ios_rounded,
          color: AppColors.outline,
          size: 14,
        ),
      ),
    );
  }
}
