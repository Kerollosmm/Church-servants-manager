import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/app_empty_state.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_list_tile.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_load_more_button.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantListBody extends StatelessWidget {
  const ServantListBody({
    super.key,
    required this.searchController,
    required this.showArchived,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onRefresh,
    required this.onOpenServantDetail,
    required this.onLoadMore,
  });

  final TextEditingController searchController;
  final bool showArchived;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final Future<void> Function() onRefresh;
  final Future<void> Function(ServantModel servant) onOpenServantDetail;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServantDataCubit, ServantDataState>(
      builder: (context, state) {
        final viewData = ServantListViewData.fromState(state);

        return RefreshIndicator(
          onRefresh: onRefresh,
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
                  child: ServantSearchBar(
                    controller: searchController,
                    isLoading: viewData.isLoading,
                    onChanged: onSearchChanged,
                    onSubmitted: onSearchSubmitted,
                    onClear: onClearSearch,
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
                    title: showArchived
                        ? 'لا يوجد خدام مؤرشفون'
                        : 'لا يوجد خدام',
                    subtitle: 'جرب البحث مرة أخرى أو قم بتحديث القائمة.',
                    refreshLabel: 'تحديث',
                    onRefresh: onRefresh,
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
                      child: ServantListTile(
                        servant: servant,
                        onTap: () => onOpenServantDetail(servant),
                      ),
                    );
                  }, childCount: viewData.servants.length),
                ),
              if (viewData.canLoadMore && viewData.loadedState != null)
                SliverToBoxAdapter(
                  child: ServantLoadMoreButton(
                    isLoading: viewData.loadedState!.isLoadingMore,
                    onPressed: onLoadMore,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ServantListViewData {
  const ServantListViewData({
    required this.isLoading,
    required this.servants,
    required this.loadedState,
    required this.showInitialLoading,
    required this.showEmptyState,
    required this.canLoadMore,
  });

  factory ServantListViewData.fromState(ServantDataState state) {
    final isLoading = state is ServantDataLoading;
    final servants = switch (state) {
      ServantDataLoaded() => state.servants,
      ServantDataLoading() => state.previousServants,
      _ => const <ServantModel>[],
    };
    final loadedState = state is ServantDataLoaded ? state : null;

    return ServantListViewData(
      isLoading: isLoading,
      servants: servants,
      loadedState: loadedState,
      showInitialLoading: isLoading && servants.isEmpty,
      showEmptyState: state is ServantDataLoaded && state.servants.isEmpty,
      canLoadMore:
          loadedState != null &&
          (loadedState.currentQuery == null ||
              loadedState.currentQuery!.isEmpty) &&
          loadedState.hasMore,
    );
  }

  final bool isLoading;
  final List<ServantModel> servants;
  final ServantDataLoaded? loadedState;
  final bool showInitialLoading;
  final bool showEmptyState;
  final bool canLoadMore;
}
