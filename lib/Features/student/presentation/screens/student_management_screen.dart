import 'dart:async';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/core/widgets/app_empty_state.dart';
import 'package:church_managment_system/core/widgets/cards/person_list_card.dart';
import 'package:church_managment_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_managment_system/core/widgets/search/live_search_panel.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/team/presentation/widgets/team_dropdown.dart';
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
  late final StudentDataBloc _studentDataBloc;
  List<StudentModel> _lastLoadedStudents = const <StudentModel>[];
  bool _hasLoadedStudents = false;

  @override
  void initState() {
    super.initState();
    _studentDataBloc = context.read<StudentDataBloc>();
    final actor = _currentActorOrNull();
    if (actor != null) {
      _studentDataBloc.add(StudentsLoadRequested(actor: actor));
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _studentDataBloc.add(const StudentsListeningStopped());
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
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _dispatchSearch(actor, value, teamId: _selectedTeamId);
    });
  }

  void _clearSearch(AuthUser actor) {
    _searchController.clear();
    _dispatchSearch(actor, '', teamId: _selectedTeamId);
  }

  void _dispatchSearch(AuthUser actor, String query, {String? teamId}) {
    context.read<StudentDataBloc>().add(
      StudentsSearchRequested(actor: actor, query: query, teamId: teamId),
    );
  }

  void _onTeamFilterChanged(AuthUser actor, String? teamId) {
    _selectedTeamId = teamId;
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _dispatchSearch(actor, query, teamId: teamId);
    } else {
      context.read<StudentDataBloc>().add(
        StudentsLoadRequested(actor: actor, teamId: teamId),
      );
    }
  }

  Future<void> _refresh(AuthUser actor) async {
    final bloc = context.read<StudentDataBloc>();
    final completer = Completer<void>();
    late final StreamSubscription<StudentDataState> sub;
    sub = bloc.stream.listen((state) {
      if (state is! StudentDataLoading && !completer.isCompleted) {
        completer.complete();
        sub.cancel();
      }
    });
    bloc.add(StudentsRefreshRequested(actor: actor));
    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        sub.cancel();
      },
    );
  }

  bool _canManage(AuthUser actor) =>
      actor.role == UserRole.admin || actor.role == UserRole.servant;

  _StudentListViewData _buildViewData(StudentDataState state) {
    final isLoading = state is StudentDataLoading;
    if (state is StudentDataLoaded) {
      _lastLoadedStudents = state.students;
      _hasLoadedStudents = true;
    }
    final students = state is StudentDataLoaded
        ? state.students
        : (_hasLoadedStudents ? _lastLoadedStudents : const <StudentModel>[]);

    return _StudentListViewData(
      isLoading: isLoading,
      students: students,
      showInitialLoading: isLoading && students.isEmpty,
      showEmptyState: state is StudentDataLoaded && state.students.isEmpty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        final assignedTeamIds = actor.effectiveAssignedTeamIds;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              actor.role == UserRole.admin ? 'إدارة المخدومين' : 'مخدومي',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
                onPressed: () {
                  context.read<StudentDataBloc>().add(
                    StudentsRefreshRequested(actor: actor),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: _canManage(actor)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      studentEdit,
                      arguments: StudentEditArgs(actor: actor),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('إضافة مخدوم'),
                )
              : null,
          body: BlocConsumer<StudentDataBloc, StudentDataState>(
            listener: (context, state) {
              if (state is StudentDataError) {
                AppSnackbars.showError(context, state.message);
              }
              if (state is StudentDataOperationSuccess) {
                AppSnackbars.showSuccess(
                  context,
                  state.message,
                  backgroundColor: AppColors.secondary,
                );
              }
            },
            builder: (context, state) {
              final viewData = _buildViewData(state);

              return RefreshIndicator(
                onRefresh: () => _refresh(actor),
                child: CustomScrollView(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LiveSearchPanel(
                              controller: _searchController,
                              label: 'ابحث باسم المخدوم',
                              hint: 'ابحث بالاسم',
                              clearTooltip: 'مسح',
                              liveLabel: 'متصل بـ Firestore',
                              isLoading: viewData.isLoading,
                              onChanged: (v) => _onSearchChanged(actor, v),
                              onSubmitted: (v) => _dispatchSearch(
                                actor,
                                v,
                                teamId: _selectedTeamId,
                              ),
                              onClear: () => _clearSearch(actor),
                              bottom: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (actor.role == UserRole.servant)
                                    Text(
                                      assignedTeamIds.isNotEmpty
                                          ? 'نطاق الخادم: ${assignedTeamIds.length} فريق'
                                          : actor.groupId == null
                                          ? 'نطاق الخادم: غير مخصص'
                                          : 'نطاق الخادم: ${actor.groupId}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  AppSpacing.gapSm,
                                  TeamDropdown(
                                    groupId: actor.role == UserRole.admin
                                        ? null
                                        : (actor.groupId ?? 'year1'),
                                    showAllOption:
                                        actor.role == UserRole.admin ||
                                        (actor.role == UserRole.servant &&
                                            assignedTeamIds.length > 1),
                                    defaultTeamId:
                                        actor.role == UserRole.servant &&
                                            assignedTeamIds.length == 1
                                        ? assignedTeamIds.first
                                        : null,
                                    restrictToTeamIds:
                                        actor.role == UserRole.servant &&
                                            assignedTeamIds.isNotEmpty
                                        ? assignedTeamIds
                                        : null,
                                    label: 'تصفية حسب الفريق',
                                    onChanged: (teamId) =>
                                        _onTeamFilterChanged(actor, teamId),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        child: AppEmptyState(
                          title: 'لا يوجد مخدومون',
                          subtitle: 'جرّب بحثا مختلفا أو حدّث القائمة.',
                          onRefresh: () => _refresh(actor),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final student = viewData.students[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: _StudentCard(
                              key: ValueKey(student.docID),
                              actor: actor,
                              student: student,
                            ),
                          );
                        }, childCount: viewData.students.length),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StudentListViewData {
  final bool isLoading;
  final List<StudentModel> students;
  final bool showInitialLoading;
  final bool showEmptyState;

  const _StudentListViewData({
    required this.isLoading,
    required this.students,
    required this.showInitialLoading,
    required this.showEmptyState,
  });
}

class _StudentCard extends StatelessWidget {
  final AuthUser actor;
  final StudentModel student;

  const _StudentCard({super.key, required this.actor, required this.student});

  @override
  Widget build(BuildContext context) {
    return PersonListCard(
      name: student.name,
      subtitle: 'المجموعة ${student.group.name} • الصف ${student.grade}',
      onTap: () {
        Navigator.pushNamed(
          context,
          studentDetail,
          arguments: StudentDetailArgs(actor: actor, student: student),
        );
      },
    );
  }
}
