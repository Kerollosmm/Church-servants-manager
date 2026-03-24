import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_empty_state.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_list_tile.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_search_bar.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentManagementCoordinator extends StatefulWidget {
  const StudentManagementCoordinator({super.key});

  @override
  State<StudentManagementCoordinator> createState() =>
      _StudentManagementCoordinatorState();
}

class _StudentManagementCoordinatorState
    extends State<StudentManagementCoordinator> {
  final TextEditingController _searchController = TextEditingController();
  // FIX [008]: ScrollController to trigger load-more at 80% scroll. (T011)
  final ScrollController _scrollController = ScrollController();
  String? _selectedTeamId;
  bool _showArchived = false;
  late final StudentDataBloc _studentDataBloc;
  late final TeamCubit _teamCubit;

  @override
  void initState() {
    super.initState();
    _studentDataBloc = context.read<StudentDataBloc>();
    // FIX [007]: Resolve TeamCubit via getIt instead of manual instantiation,
    // ensuring the DI container owns the lifecycle of this cubit.
    _teamCubit = getIt<TeamCubit>();

    final actor = _currentActorOrNull();
    if (actor == null) {
      return;
    }

    _selectedTeamId =
        actor.role == UserRole.servant &&
            actor.effectiveAssignedTeamIds.length == 1
        ? actor.effectiveAssignedTeamIds.first
        : null;

    // FIX [008]: Listen to scroll position and load more at 80%. (T011)
    _scrollController.addListener(() => _onScroll(actor));

    _loadStudents(actor, teamId: _selectedTeamId);
    _loadTeamsForActor(actor);
  }

  @override
  void dispose() {
    _studentDataBloc.add(const StudentsListeningStopped());
    _teamCubit.close();
    _searchController.dispose();
    _scrollController.dispose(); // FIX [008]: dispose ScrollController (T011)
    super.dispose();
  }

  // FIX [008]: Trigger load-more when user scrolls past 80% of list. (T011)
  void _onScroll(AuthUser actor) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent * 0.8;
    if (position.pixels >= threshold) {
      _studentDataBloc.add(StudentsLoadMoreRequested(actor: actor));
    }
  }

  AuthUser? _currentActorOrNull() {
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    return null;
  }

  void _loadStudents(AuthUser actor, {String? teamId}) {
    _studentDataBloc.add(
      StudentsLoadRequested(
        actor: actor,
        teamId: teamId,
        includeArchived: _showArchived,
      ),
    );
  }

  void _dispatchSearch(AuthUser actor, String query, {String? teamId}) {
    _studentDataBloc.add(
      StudentsSearchRequested(
        actor: actor,
        query: query,
        teamId: teamId,
        includeArchived: _showArchived,
      ),
    );
  }

  void _onSearchChanged(AuthUser actor, String value) {
    _dispatchSearch(actor, value, teamId: _selectedTeamId);
  }

  void _clearSearch(AuthUser actor) {
    _searchController.clear();
    _dispatchSearch(actor, '', teamId: _selectedTeamId);
  }

  void _onTeamFilterChanged(AuthUser actor, String? teamId) {
    setState(() => _selectedTeamId = teamId);
    _teamCubit.selectTeam(teamId);

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _dispatchSearch(actor, query, teamId: teamId);
      return;
    }

    _loadStudents(actor, teamId: teamId);
  }

  Future<void> _refresh(AuthUser actor) {
    return _studentDataBloc.refresh(actor);
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
    if (!mounted || result != true) {
      return;
    }
    await _refresh(actor);
  }

  Future<void> _openStudentDetail(AuthUser actor, StudentModel student) async {
    final result = await Navigator.pushNamed(
      context,
      studentDetail,
      arguments: StudentDetailArgs(actor: actor, student: student),
    );
    if (!mounted || result != true) {
      return;
    }
    await _refresh(actor);
  }

  void _loadTeamsForActor(AuthUser actor) {
    if (actor.role == UserRole.admin) {
      _teamCubit.loadAllTeams();
      return;
    }

    final groupId = actor.groupId;
    if (groupId == null || groupId.isEmpty) {
      return;
    }

    _teamCubit.loadTeamsByGroup(
      groupId,
      defaultTeamId: actor.effectiveAssignedTeamIds.length == 1
          ? actor.effectiveAssignedTeamIds.first
          : null,
    );
  }

  bool _canManage(AuthUser actor) {
    return actor.role == UserRole.admin || actor.role == UserRole.servant;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final actor = switch (authState) {
          AuthAuthenticated() => authState.user,
          AuthDegraded() => authState.user,
          _ => null,
        };

        if (actor == null) {
          return const Scaffold(
            body: Center(child: Text('لم يتم تسجيل الدخول.')),
          );
        }

        return BlocProvider<TeamCubit>.value(
          value: _teamCubit,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                _showArchived
                    ? 'المخدومون المؤرشفون'
                    : actor.role == UserRole.admin
                    ? 'إدارة المخدومين'
                    : 'مخدومي',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'تحديث',
                  onPressed: () => _refresh(actor),
                ),
                IconButton(
                  icon: Icon(
                    _showArchived
                        ? Icons.unarchive_outlined
                        : Icons.archive_outlined,
                  ),
                  tooltip: _showArchived ? 'إخفاء المؤرشف' : 'عرض المؤرشف',
                  onPressed: () {
                    setState(() => _showArchived = !_showArchived);
                    _loadStudents(actor, teamId: _selectedTeamId);
                  },
                ),
              ],
            ),
            floatingActionButton: _canManage(actor)
                ? FloatingActionButton.extended(
                    onPressed: () => _openStudentEditor(actor),
                    icon: const Icon(Icons.person_add),
                    label: const Text('إضافة مخدوم'),
                  )
                : null,
            body: BlocConsumer<StudentDataBloc, StudentDataState>(
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
                final viewData = StudentListViewData.fromState(state);
                final assignedTeamIds = actor.effectiveAssignedTeamIds;

                return RefreshIndicator(
                  onRefresh: () => _refresh(actor),
                  child: CustomScrollView(
                    // FIX [008]: Attach scroll controller for load-more. (T011)
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.md,
                            AppSpacing.sm,
                          ),
                          child: BlocBuilder<TeamCubit, TeamState>(
                            builder: (context, teamState) {
                              final teams = teamState is TeamLoaded
                                  ? teamState.teams
                                  : const <TeamModel>[];

                              return StudentSearchBar(
                                controller: _searchController,
                                actorRole: actor.role,
                                assignedTeamIds: assignedTeamIds,
                                actorGroupId: actor.groupId,
                                isLoading: viewData.isLoading,
                                teams: teams,
                                teamsLoading:
                                    teamState is TeamLoading ||
                                    teamState is TeamInitial,
                                teamsErrorMessage: teamState is TeamError
                                    ? teamState.message
                                    : null,
                                selectedTeamId: _selectedTeamId,
                                onChanged: (value) =>
                                    _onSearchChanged(actor, value),
                                onSubmitted: (value) => _dispatchSearch(
                                  actor,
                                  value,
                                  teamId: _selectedTeamId,
                                ),
                                onClear: () => _clearSearch(actor),
                                onTeamChanged: (teamId) =>
                                    _onTeamFilterChanged(actor, teamId),
                              );
                            },
                          ),
                        ),
                      ),
                      if (viewData.showInitialLoading)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (viewData.showEmptyState)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: StudentEmptyState(
                            showArchived: _showArchived,
                            onRefresh: () => _refresh(actor),
                          ),
                        )
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final student = viewData.students[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                0,
                                AppSpacing.md,
                                AppSpacing.md,
                              ),
                              child: StudentListTile(
                                key: ValueKey(student.docID),
                                student: student,
                                onTap: () => _openStudentDetail(actor, student),
                              ),
                            );
                          }, childCount: viewData.students.length),
                        ),
                      // FIX [008]: Load-more indicator at bottom of list. (T011)
                      if (state is StudentDataLoaded && state.isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class StudentListViewData {
  const StudentListViewData({
    required this.isLoading,
    required this.students,
    required this.showInitialLoading,
    required this.showEmptyState,
    required this.canLoadMore,
  });

  factory StudentListViewData.fromState(StudentDataState state) {
    final isLoading = state is StudentDataLoading;
    final students = switch (state) {
      StudentDataLoaded() => state.students,
      StudentDataLoading() => state.previousStudents,
      _ => const <StudentModel>[],
    };
    final loadedState = state is StudentDataLoaded ? state : null;

    return StudentListViewData(
      isLoading: isLoading,
      students: students,
      showInitialLoading: isLoading && students.isEmpty,
      showEmptyState: state is StudentDataLoaded && state.students.isEmpty,
      // FIX [008]: expose canLoadMore for pagination UI. (T011)
      canLoadMore: loadedState != null && !loadedState.hasReachedMax,
    );
  }

  final bool isLoading;
  final List<StudentModel> students;
  final bool showInitialLoading;
  final bool showEmptyState;
  final bool canLoadMore; // FIX [008]: true when more pages exist (T011)
}
