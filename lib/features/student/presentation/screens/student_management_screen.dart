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
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/core/widgets/sync_status_banner.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/entities/team.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_bloc.dart';
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

  Future<void> _openStudentEditor(AuthUser actor, {Student? student}) async {
    final result = await Navigator.pushNamed(
      context,
      studentEdit,
      arguments: StudentEditArgs(actor: actor, student: student),
    );
    if (!mounted || result != true) return;
    await context.read<StudentDataBloc>().refresh(actor);
  }

  Future<void> _openStudentDetail(AuthUser actor, Student student) async {
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
      _ => const <Student>[],
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

  Widget _buildArchiveToggleCard(BuildContext context, AuthUser actor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF6EE), // Beige background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECE0D1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Export / Download Button
              InkWell(
                onTap: _onExport,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'تفعيل الأرشيف',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    Text(
                      'عرض الطلاب غير النشطين',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Archive Switch
              Switch(
                value: _showArchived,
                activeThumbColor: const Color(0xFF8D6E63),
                onChanged: (value) {
                  setState(() {
                    _showArchived = value;
                  });
                  context.read<StudentDataBloc>().add(
                    StudentsLoadRequested(
                      actor: actor,
                      teamId: _selectedTeamId,
                      includeArchived: _showArchived,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(96),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
                  child: Row(
                    children: [
                      // Far Left: Notification Bell
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_none_outlined,
                          color: Color(0xFF0F172A),
                          size: 24,
                        ),
                      ),
                      const Spacer(),
                      // Center: Title & Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'قائمة الطلاب',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'خدمة مدارس الأحد',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      // Church Logo in rounded beige box
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF2E6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFECE0D1)),
                        ),
                        child: Image.asset(
                          'assets/images/logo_elkarooz.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.church,
                                color: Color(0xFF795548),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Back Button
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Color(0xFF0F172A),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              floatingActionButton: _canManage(actor)
                  ? FloatingActionButton.extended(
                      backgroundColor: const Color(0xFF8D6E63),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onPressed: () {
                        _openStudentEditor(actor);
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        'إضافة مخدوم',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                                ),
                              ),
                              _buildArchiveToggleCard(context, actor),
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
  });

  @override
  double get minExtent => 120;
  @override
  double get maxExtent => 120;

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF8D6E63);
    final activeTextColor = Colors.white;
    final inactiveColor = Colors.white;
    final inactiveTextColor = const Color(0xFF8D6E63);
    final borderColor = const Color(0xFFECE0D1);

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? Colors.transparent : borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? activeTextColor : inactiveTextColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeTextColor : inactiveTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Field
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFECE0D1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFFA58255)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                    decoration: const InputDecoration(
                      hintText: 'بحث عن طالب بالاسم أو الكود...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFA58255),
                    ),
                  )
                else if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onSearchClear,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Horizontal scrollable team chips
          Expanded(
            child: BlocBuilder<TeamBloc, TeamState>(
              builder: (context, teamState) {
                final teams = teamState is TeamLoaded
                    ? teamState.teams
                    : const <Team>[];

                final restrictedTeamIds = <String>{};
                if (actor.role == UserRole.servant &&
                    assignedTeamIds.isNotEmpty) {
                  restrictedTeamIds.addAll(assignedTeamIds);
                }
                final visibleTeams = restrictedTeamIds.isEmpty
                    ? teams
                    : teams
                          .where((t) => restrictedTeamIds.contains(t.id))
                          .toList();

                return ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFilterChip(
                      context: context,
                      label: 'الكل',
                      icon: Icons.grid_view,
                      isSelected: selectedTeamId == null,
                      onTap: () => onTeamChanged(null),
                    ),
                    ...visibleTeams.map((team) {
                      final isSelected = selectedTeamId == team.id;
                      IconData icon;
                      if (team.name.contains('شمامسة')) {
                        icon = Icons.people;
                      } else if (team.name.contains('كورال')) {
                        icon = Icons.music_note;
                      } else if (team.name.contains('كشافة')) {
                        icon = Icons.explore;
                      } else {
                        icon = Icons.group;
                      }
                      return _buildFilterChip(
                        context: context,
                        label: team.name,
                        icon: icon,
                        isSelected: isSelected,
                        onTap: () => onTeamChanged(team.id),
                      );
                    }),
                  ],
                );
              },
            ),
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
  final List<Student> students;
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
  final Student student;
  final VoidCallback onTap;

  const _StudentCard({
    super.key,
    required this.actor,
    required this.student,
    required this.onTap,
  });

  String _getGradeText(int grade, EducationStage stage) {
    final gradeWords = {
      1: 'الأول',
      2: 'الثاني',
      3: 'الثالث',
      4: 'الرابع',
      5: 'الخامس',
      6: 'السادس',
    };
    final gradeWord = gradeWords[grade] ?? grade.toString();
    return 'الصف $gradeWord ${stage.displayName}';
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = const Color(0xFF4CAF50);
    final inactiveColor = Colors.grey;
    final idLength = student.uid.length;
    final displayId = student.uid.isNotEmpty
        ? (idLength > 5 ? student.uid.substring(0, 5) : student.uid)
        : (student.docID.length > 4
              ? student.docID.substring(student.docID.length - 4)
              : student.docID);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECE0D1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Right side: Avatar with status dot (RTL leading)
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFF5EEDC),
                      backgroundImage:
                          student.imageUrl != null &&
                              student.imageUrl!.isNotEmpty
                          ? NetworkImage(student.imageUrl!)
                          : null,
                      child:
                          student.imageUrl == null || student.imageUrl!.isEmpty
                          ? Text(
                              student.name.isNotEmpty
                                  ? student.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF795548),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: student.isArchived
                              ? inactiveColor
                              : activeColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Middle: Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF3E2723),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Grade info
                      Row(
                        children: [
                          const Icon(
                            Icons.school,
                            size: 14,
                            color: Color(0xFF795548),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getGradeText(
                              student.grade,
                              student.educationStage,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF795548),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Team/Group info
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 14,
                            color: Color(0xFF795548),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            student.teamName.isNotEmpty
                                ? student.teamName
                                : student.group.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF795548),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Actions indicators
                      Row(
                        children: [
                          if (!student.isArchived)
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Color(0xFFC5A070),
                            ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.history,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Left side: ID and "Details" button (RTL trailing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // ID Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF2E6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ID: $displayId',
                        style: const TextStyle(
                          color: Color(0xFF795548),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Details button
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'التفاصيل',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFFA58255),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 12,
                          color: Color(0xFFA58255),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
