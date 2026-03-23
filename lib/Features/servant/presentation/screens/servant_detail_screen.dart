import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_detail_actions.dart';
import 'package:church_management_system/features/servant/presentation/widgets/servant_detail_content.dart';
import 'package:flutter/material.dart';

class ServantDetailScreen extends StatelessWidget {
  final ServantDetailArgs args;

  const ServantDetailScreen({super.key, required this.args});

  bool _canEdit() {
    final actor = args.actor;
    return actor.role == UserRole.admin;
  }

  @override
  Widget build(BuildContext context) {
    final servant = args.servant;
    final canEdit = _canEdit();

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الخادم'),
        actions: [ServantDetailActions(args: args, canEdit: canEdit)],
      ),
      body: ServantDetailContent(servant: servant, canEdit: canEdit),
    );
  }
}
