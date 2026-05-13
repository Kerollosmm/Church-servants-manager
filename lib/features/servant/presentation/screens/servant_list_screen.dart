import 'dart:async';

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/theme/app_colors.dart';
import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/core/widgets/app_error_state.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/common/ochre_button.dart';
import 'package:church_management_system/core/widgets/common/ochre_card.dart';
import 'package:church_management_system/core/widgets/common/ochre_text_field.dart';
import 'package:church_management_system/core/widgets/common/sanctuary_background.dart';
import 'package:church_management_system/core/widgets/feedback/app_snackbars.dart';
import 'package:church_management_system/core/widgets/sync_status_banner.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
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
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    final actor = _currentActorOrNull();
    if (actor != null) {
      context.read<ServantDataBloc>().add(
        ServantsLoadRequested(actor: actor, includeArchived: _showArchived),
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
    if (state is AuthAuthenticated) return state.user;
    if (state is AuthDegraded) return state.user;
    return null;
  }

  void _onSearchChanged(AuthUser actor, String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      context.read<ServantDataBloc>().add(
        ServantsSearchRequested(
          actor: actor,
          query: value,
          includeArchived: _showArchived,
        ),
      );
    });
  }

  void _clearSearch(AuthUser actor) {
    _searchController.clear();
    context.read<ServantDataBloc>().add(
      ServantsSearchRequested(
        actor: actor,
        query: '',
        includeArchived: _showArchived,
      ),
    );
  }

  Future<void> _refresh(AuthUser actor) async {
    context.read<ServantDataBloc>().add(ServantsRefreshRequested(actor: actor));
  }

  Future<void> _openServantDetail(AuthUser actor, ServantModel servant) async {
    final result = await Navigator.pushNamed(
      context,
      servantDetail,
      arguments: ServantDetailArgs(actor: actor, servant: servant),
    );
    if (!mounted || result != true) return;
    unawaited(_refresh(actor));
  }

  bool _canManage(AuthUser actor) => actor.role == UserRole.admin;

  _ServantListViewData _buildViewData(ServantDataState state) {
    final isLoading = state is ServantDataLoading;
    final servants = switch (state) {
      ServantDataLoaded() => state.servants,
      ServantDataLoading() => state.previousServants,
      _ => const <ServantModel>[],
    };
    final loadedState = state is ServantDataLoaded ? state : null;
    final showInitialLoading = isLoading && servants.isEmpty;
    final showEmptyState = state is ServantDataLoaded && state.servants.isEmpty;
    final canLoadMore =
        loadedState != null &&
        (loadedState.currentQuery == null ||
            loadedState.currentQuery!.isEmpty) &&
        loadedState.hasMore;

    final isFromCache = loadedState?.isFromCache ?? false;

    return _ServantListViewData(
      isLoading: isLoading,
      servants: servants,
      loadedState: loadedState,
      showInitialLoading: showInitialLoading,
      showEmptyState: showEmptyState,
      canLoadMore: canLoadMore,
      isFromCache: isFromCache,
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

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              _showArchived ? 'الخدام المؤرشفون' : 'الخدام',
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            actions: [
              IconButton(
                icon: Icon(
                  _showArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                tooltip: _showArchived ? 'إخفاء المؤرشف' : 'عرض المؤرشف',
                onPressed: () {
                  setState(() => _showArchived = !_showArchived);
                  context.read<ServantDataBloc>().add(
                    ServantsLoadRequested(
                      actor: actor,
                      includeArchived: _showArchived,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
                onPressed: () {
                  context.read<ServantDataBloc>().add(
                    ServantsRefreshRequested(actor: actor),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: _canManage(actor)
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      servantEdit,
                      arguments: ServantEditArgs(actor: actor),
                    );
                    if (result == true && mounted) {
                      await _refresh(actor);
                    }
                  },
                  child: const Icon(Icons.person_add),
                )
              : null,
          body: SanctuaryBackground(
            child: Column(
              children: [
                const SyncStatusBanner(),
                Expanded(
                  child: BlocConsumer<ServantDataBloc, ServantDataState>(
                    buildWhen: (prev, curr) {
                      if (prev.runtimeType != curr.runtimeType) return true;
                      if (curr is ServantDataLoaded &&
                          prev is ServantDataLoaded) {
                        return prev.servants != curr.servants ||
                            prev.mutationStatus != curr.mutationStatus ||
                            prev.isLoadingMore != curr.isLoadingMore;
                      }
                      return true;
                    },
                    listener: (context, state) {
                      if (state is ServantDataError) {
                        AppSnackbars.showError(context, state.message);
                      }
                      if (state is ServantDataLoaded &&
                          state.feedbackMessage != null &&
                          state.mutationStatus ==
                              ServantMutationStatus.success) {
                        AppSnackbars.showSuccess(
                          context,
                          state.feedbackMessage!,
                          backgroundColor: AppColors.secondary,
                        );
                      }
                      if (state is ServantDataLoaded &&
                          state.feedbackMessage != null &&
                          state.mutationStatus ==
                              ServantMutationStatus.failure) {
                        AppSnackbars.showError(context, state.feedbackMessage!);
                      }
                    },
                    builder: (context, state) {
                      final viewData = _buildViewData(state);

                      return RefreshIndicator(
                        onRefresh: () => _refresh(actor),
                        displacement: kToolbarHeight + 40,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            SliverToBoxAdapter(
                              child: SizedBox(height: kToolbarHeight + 20),
                            ),
                            SliverPersistentHeader(
                              pinned: true,
                              delegate: _SearchHeaderDelegate(
                                child: OchreCard(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  borderRadius: AppRadius.mdRadius,
                                  child: OchreTextField(
                                    controller: _searchController,
                                    label: 'البحث عن خادم',
                                    placeholder: 'الاسم...',
                                    prefixIcon: Icons.search,
                                    onChanged: (v) =>
                                        _onSearchChanged(actor, v),
                                    suffixIcon:
                                        _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () =>
                                                _clearSearch(actor),
                                          )
                                        : (viewData.isLoading
                                              ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : null),
                                  ),
                                ),
                              ),
                            ),
                            const SliverToBoxAdapter(child: AppSpacing.gapMd),
                            if (viewData.showInitialLoading)
                              const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            else if (state is ServantDataError)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: AppErrorState(
                                  message: state.message,
                                  onRetry: () =>
                                      context.read<ServantDataBloc>().add(
                                        ServantsLoadRequested(
                                          actor: actor,
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
                                      ? 'لا يوجد خدام مؤرشفون'
                                      : 'لا يوجد خدام',
                                  subtitle: viewData.isFromCache
                                      ? 'يرجى الاتصال بالإنترنت لتحميل البيانات لأول مرة.'
                                      : 'جرب البحث مرة أخرى أو أضف خادما جديدا.',
                                  onAction:
                                      _canManage(actor) && !viewData.isFromCache
                                      ? () async {
                                          final result =
                                              await Navigator.pushNamed(
                                                context,
                                                servantEdit,
                                                arguments: ServantEditArgs(
                                                  actor: actor,
                                                ),
                                              );
                                          if (result == true && mounted) {
                                            await _refresh(actor);
                                          }
                                        }
                                      : null,
                                  actionLabel: 'إضافة خادم',
                                  onRefresh: () => _refresh(actor),
                                ),
                              )
                            else ...[
                              if (viewData.isFromCache)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      0,
                                      AppSpacing.md,
                                      AppSpacing.md,
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
                                  final servant = viewData.servants[index];
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      0,
                                      AppSpacing.md,
                                      AppSpacing.md,
                                    ),
                                    child: ServantCard(
                                      actor: actor,
                                      servant: servant,
                                      onTap: () =>
                                          _openServantDetail(actor, servant),
                                    ),
                                  );
                                }, childCount: viewData.servants.length),
                              ),
                            ],
                            if (viewData.canLoadMore &&
                                viewData.loadedState != null)
                              SliverToBoxAdapter(
                                child: _LoadMoreServantsButton(
                                  isLoading:
                                      viewData.loadedState!.isLoadingMore,
                                  onPressed: () {
                                    context.read<ServantDataBloc>().add(
                                      ServantsLoadMoreRequested(actor: actor),
                                    );
                                  },
                                ),
                              ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: AppSpacing.xl),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SearchHeaderDelegate({required this.child});

  @override
  double get minExtent => 110;
  @override
  double get maxExtent => 110;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.transparent,
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SearchHeaderDelegate oldDelegate) => true;
}

class _ServantListViewData {
  final bool isLoading;
  final List<ServantModel> servants;
  final ServantDataLoaded? loadedState;
  final bool showInitialLoading;
  final bool showEmptyState;
  final bool canLoadMore;
  final bool isFromCache;

  const _ServantListViewData({
    required this.isLoading,
    required this.servants,
    required this.loadedState,
    required this.showInitialLoading,
    required this.showEmptyState,
    required this.canLoadMore,
    required this.isFromCache,
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
      child: OchreButton(
        text: isLoading ? 'جاري تحميل المزيد...' : 'تحميل المزيد',
        isLoading: isLoading,
        color: AppColors.surface,
        textColor: AppColors.primary,
        icon: Icons.expand_more,
        onPressed: onPressed,
      ),
    );
  }
}

/// Card widget for displaying a single servant in a list.
class ServantCard extends StatelessWidget {
  final AuthUser actor;
  final ServantModel servant;
  final VoidCallback onTap;

  const ServantCard({
    super.key,
    required this.actor,
    required this.servant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OchreCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              servant.name.isNotEmpty ? servant.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AppSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servant.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  servant.isArchived
                      ? 'خادم مؤرشف'
                      : 'المجموعة: ${servant.teamName ?? '--'}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}
