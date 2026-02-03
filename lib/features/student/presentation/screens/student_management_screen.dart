import 'dart:async';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final actor = _currentActorOrNull();
    if (actor != null) {
      context.read<StudentDataBloc>().add(
            StudentsLoadRequested(actor: actor),
          );
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
    final colorScheme = theme.colorScheme;

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
                  context
                      .read<StudentDataBloc>()
                      .add(StudentsRefreshRequested(actor: actor));
                },
              ),
            ],
          ),
          floatingActionButton: _canManage(actor)
              ? FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.studentEdit,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is StudentDataOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: colorScheme.secondary,
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_done,
                                        size: 16,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Live Firestore',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
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
                            const SizedBox(height: 12),
                            Text(
                              'Search students',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 8),
                            if (actor.role == UserRole.servant)
                              Text(
                                actor.groupId == null
                                    ? 'Teacher scope: not assigned'
                                    : 'Teacher scope: ${actor.groupId}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
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
                        child: _EmptyState(
                          onRefresh: () => _refresh(actor),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final student = students[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _StudentCard(
                                actor: actor,
                                student: student,
                              ),
                            );
                          },
                          childCount: students.length,
                        ),
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
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No students found', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Try a different search or refresh the list.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
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
    final colorScheme = theme.colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRouter.studentDetail,
            arguments: StudentDetailArgs(actor: actor, student: student),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
            child: Text(
              student.name.isNotEmpty ? student.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Group ${student.group.name} • Grade ${student.grade}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: colorScheme.outline),
        ),
      ),
    );
  }
}

