import 'dart:async';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
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

  @override
  void initState() {
    super.initState();
    final actor = _currentActorOrNull();
    if (actor != null) {
      context.read<StudentDataBloc>().add(StudentsLoadRequested(actor: actor));
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  AuthUser? _currentActorOrNull() {
    final state = context.read<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user : null;
  }

  void _onSearchChanged(AuthUser actor, String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      context.read<StudentDataBloc>().add(
        StudentsSearchRequested(actor: actor, query: value),
      );
    });
  }

  void _clearSearch(AuthUser actor) {
    _searchController.clear();
    setState(() {});
    context.read<StudentDataBloc>().add(
      StudentsSearchRequested(actor: actor, query: ''),
    );
  }

  Future<void> _refresh(AuthUser actor) async {
    final bloc = context.read<StudentDataBloc>();
    final future = bloc.stream.firstWhere((s) => s is! StudentDataLoading);
    bloc.add(StudentsRefreshRequested(actor: actor));
    await future;
  }

  bool _canManage(AuthUser actor) =>
      actor.role == UserRole.admin || actor.role == UserRole.servant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Not signed in.')));
        }

        final actor = authState.user;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              actor.role == UserRole.admin ? 'Manage Students' : 'My Students',
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
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
                  label: const Text('Add Student'),
                )
              : null,
          body: BlocConsumer<StudentDataBloc, StudentDataState>(
            listener: (context, state) {
              if (state is StudentDataError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
              if (state is StudentDataOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is StudentDataLoading;
              final students = state is StudentDataLoaded
                  ? state.students
                  : <StudentModel>[];

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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_done,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Live Firestore',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                if (isLoading)
                                  const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                            AppSpacing.gapMd,
                            Text(
                              'Search students',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            AppSpacing.gapSm,
                            TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onChanged: (v) => _onSearchChanged(actor, v),
                              onSubmitted: (v) {
                                context.read<StudentDataBloc>().add(
                                  StudentsSearchRequested(
                                    actor: actor,
                                    query: v,
                                  ),
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by name',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'Clear',
                                        onPressed: () => _clearSearch(actor),
                                      ),
                              ),
                            ),
                            AppSpacing.gapSm,
                            if (actor.role == UserRole.servant)
                              Text(
                                actor.groupId == null
                                    ? 'Teacher scope: not assigned'
                                    : 'Teacher scope: ${actor.groupId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (isLoading && students.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state is StudentDataLoaded && students.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(onRefresh: () => _refresh(actor)),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final student = students[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: _StudentCard(actor: actor, student: student),
                          );
                        }, childCount: students.length),
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

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.outline),
            AppSpacing.gapMd,
            Text('No students found', style: theme.textTheme.titleMedium),
            AppSpacing.gapSm,
            Text(
              'Try a different search or refresh the list.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapMd,
            FilledButton.icon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final AuthUser actor;
  final StudentModel student;

  const _StudentCard({required this.actor, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: () {
          Navigator.pushNamed(
            context,
            studentDetail,
            arguments: StudentDetailArgs(actor: actor, student: student),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            student.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Group ${student.group.name} • Grade ${student.grade}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: AppColors.outline),
        ),
      ),
    );
  }
}
