import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/core/widgets/cards/person_list_card.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/core/widgets/search/live_search_panel.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
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
    context.read<ServantDataCubit>().searchServants(actor: actor, query: '');
  }

  Future<void> _refresh(AuthUser actor) async {
    await context.read<ServantDataCubit>().refreshServants(actor: actor);
  }

  bool _canManage(AuthUser actor) => actor.role == UserRole.admin;

  _ServantListViewData _buildViewData(ServantDataState state) {
    final isLoading = state is ServantDataLoading;
    if (state is ServantDataLoaded) {
      _lastLoadedServants = state.servants;
      _hasLoadedServants = true;
    }

    final servants = state is ServantDataLoaded
        ? state.servants
        : (_hasLoadedServants ? _lastLoadedServants : const <ServantModel>[]);
    final loadedState = state is ServantDataLoaded ? state : null;
    final showInitialLoading = isLoading && servants.isEmpty;
    final showEmptyState = state is ServantDataLoaded && state.servants.isEmpty;
    final canLoadMore =
        loadedState != null &&
        (loadedState.currentQuery == null ||
            loadedState.currentQuery!.isEmpty) &&
        loadedState.hasMore;

    return _ServantListViewData(
      isLoading: isLoading,
      servants: servants,
      loadedState: loadedState,
      showInitialLoading: showInitialLoading,
      showEmptyState: showEmptyState,
      canLoadMore: canLoadMore,
    );
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
                AppSnackbars.showError(context, state.message);
              }
              if (state is ServantDataOperationSuccess) {
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
                              label: 'البحث عن خادم',
                              hint: 'الاسم',
                              clearTooltip: 'مسح',
                              liveLabel: 'متصل بـ Firestore',
                              isLoading: viewData.isLoading,
                              onChanged: (v) => _onSearchChanged(actor, v),
                              onSubmitted: (v) {
                                context.read<ServantDataCubit>().searchServants(
                                  actor: actor,
                                  query: v,
                                );
                              },
                              onClear: () => _clearSearch(actor),
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
                          title: 'لا يوجد خدام',
                          subtitle: 'جرب البحث مرة أخرى أو قم بتحديث القائمة.',
                          refreshLabel: 'تحديث',
                          onRefresh: () => _refresh(actor),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final servant = viewData.servants[index];
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              0,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            child: ServantCard(actor: actor, servant: servant),
                          );
                        }, childCount: viewData.servants.length),
                      ),
                    if (viewData.canLoadMore && viewData.loadedState != null)
                      SliverToBoxAdapter(
                        child: _LoadMoreServantsButton(
                          isLoading: viewData.loadedState!.isLoadingMore,
                          onPressed: () {
                            context.read<ServantDataCubit>().loadMoreServants(
                              actor: actor,
                            );
                          },
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

class _ServantListViewData {
  final bool isLoading;
  final List<ServantModel> servants;
  final ServantDataLoaded? loadedState;
  final bool showInitialLoading;
  final bool showEmptyState;
  final bool canLoadMore;

  const _ServantListViewData({
    required this.isLoading,
    required this.servants,
    required this.loadedState,
    required this.showInitialLoading,
    required this.showEmptyState,
    required this.canLoadMore,
  });
}

class _LoadMoreServantsButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoadMoreServantsButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more),
        label: Text(isLoading ? 'جاري تحميل المزيد...' : 'تحميل المزيد'),
      ),
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
    return PersonListCard(
      name: servant.name,
      subtitle: 'المجموعة: ${servant.teamName ?? '--'}',
      onTap: () {
        Navigator.pushNamed(
          context,
          servantDetail,
          arguments: ServantDetailArgs(actor: actor, servant: servant),
        );
      },
    );
  }
}
