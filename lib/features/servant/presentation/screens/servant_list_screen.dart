import 'dart:async';

import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/constants/routes.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/core/routing/route_args.dart';
import 'package:church_managment_system/core/theme/app_colors.dart';
import 'package:church_managment_system/core/theme/app_spacing.dart';
import 'package:church_managment_system/core/widgets/app_empty_state.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/servant/data/models/servant_models.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Displays a searchable list of servants with CRUD support.
class ServantListScreen extends StatefulWidget {
  const ServantListScreen({super.key});

  @override
  State<ServantListScreen> createState() => _ServantListScreenState();
}

class _ServantListScreenState extends State<ServantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<ServantModel> _lastLoadedServants = const <ServantModel>[];
  bool _hasLoadedServants = false;

  @override
  void initState() {
    super.initState();
    final actor = _currentActorOrNull();
    if (actor != null) {
      context.read<ServantDataCubit>().loadServants(actor: actor);
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
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    return null;
  }

  void _onSearchChanged(AuthUser actor, String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ServantDataCubit>().searchServants(
        actor: actor,
        query: value,
      );
    });
  }

  void _clearSearch(AuthUser actor) {
    _searchController.clear();
    setState(() {});
    context.read<ServantDataCubit>().searchServants(actor: actor, query: '');
  }

  Future<void> _refresh(AuthUser actor) async {
    await context.read<ServantDataCubit>().refreshServants(actor: actor);
  }

  bool _canManage(AuthUser actor) => actor.role == UserRole.admin;

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
          return const Scaffold(body: Center(child: Text('Not signed in.')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('الخدام'), // Arabic: Servants
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث', // Refresh
                onPressed: () {
                  context.read<ServantDataCubit>().refreshServants(
                    actor: actor,
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
                      servantEdit,
                      arguments: ServantEditArgs(actor: actor),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('إضافة خادم'), // Add Servant
                )
              : null,
          body: BlocConsumer<ServantDataCubit, ServantDataState>(
            listener: (context, state) {
              if (state is ServantDataError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
              if (state is ServantDataOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.secondary,
                  ),
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is ServantDataLoading;
              if (state is ServantDataLoaded) {
                _lastLoadedServants = state.servants;
                _hasLoadedServants = true;
              }
              final servants = state is ServantDataLoaded
                  ? state.servants
                  : (_hasLoadedServants
                        ? _lastLoadedServants
                        : const <ServantModel>[]);
              final showInitialLoading = isLoading && servants.isEmpty;
              final showEmptyState =
                  state is ServantDataLoaded && state.servants.isEmpty;

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
                              'البحث عن خادم', // Search for servant
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
                                context.read<ServantDataCubit>().searchServants(
                                  actor: actor,
                                  query: v,
                                );
                              },
                              decoration: InputDecoration(
                                hintText: 'الاسم', // Name
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.clear),
                                        tooltip: 'مسح', // Clear
                                        onPressed: () => _clearSearch(actor),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showInitialLoading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (showEmptyState)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: AppEmptyState(
                          title: 'لا يوجد خدام',
                          subtitle: 'جرب البحث مرة أخرى أو قم بتحديث القائمة.',
                          refreshLabel: 'تحديث',
                          onRefresh: () => _refresh(actor),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final servant = servants[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: ServantCard(actor: actor, servant: servant),
                          );
                        }, childCount: servants.length),
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

/// Card widget for displaying a single servant in a list.
class ServantCard extends StatelessWidget {
  final AuthUser actor;
  final ServantModel servant;

  const ServantCard({super.key, required this.actor, required this.servant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: () {
          Navigator.pushNamed(
            context,
            servantDetail,
            arguments: ServantDetailArgs(actor: actor, servant: servant),
          );
        },
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              servant.name.isNotEmpty ? servant.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            servant.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'المجموعة: ${servant.teamName ?? '--'}', // Team
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
