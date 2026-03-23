import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_data_feedback_listener.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_list_body.dart';
import 'package:flutter/material.dart';

class ServantListScaffold extends StatelessWidget {
  const ServantListScaffold({
    super.key,
    required this.actor,
    required this.showArchived,
    required this.searchController,
    required this.onToggleArchived,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onSearchSubmitted,
    required this.onClearSearch,
    required this.onOpenServantDetail,
    required this.onLoadMore,
  });

  final AuthUser actor;
  final bool showArchived;
  final TextEditingController searchController;
  final VoidCallback onToggleArchived;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onClearSearch;
  final Future<void> Function(ServantModel servant) onOpenServantDetail;
  final VoidCallback onLoadMore;

  bool get _canManage => actor.role == UserRole.admin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(showArchived ? 'الخدام المؤرشفون' : 'الخدام'),
        actions: [
          IconButton(
            icon: Icon(
              showArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
            ),
            tooltip: showArchived ? 'إخفاء المؤرشف' : 'عرض المؤرشف',
            onPressed: onToggleArchived,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: onRefresh,
          ),
        ],
      ),
      floatingActionButton: _canManage
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  servantEdit,
                  arguments: ServantEditArgs(actor: actor),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('إضافة خادم'),
            )
          : null,
      body: ServantDataFeedbackListener(
        child: ServantListBody(
          searchController: searchController,
          showArchived: showArchived,
          onSearchChanged: onSearchChanged,
          onSearchSubmitted: onSearchSubmitted,
          onClearSearch: onClearSearch,
          onRefresh: onRefresh,
          onOpenServantDetail: onOpenServantDetail,
          onLoadMore: onLoadMore,
        ),
      ),
    );
  }
}
