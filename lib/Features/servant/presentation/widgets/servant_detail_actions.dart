import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/widgets/dialogs/generic_dialog.dart';

import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ServantDetailActions extends StatelessWidget {
  const ServantDetailActions({
    super.key,
    required this.args,
    required this.canEdit,
  });

  final ServantDetailArgs args;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final servant = args.servant;
    final canArchive = canEdit && !servant.isArchived;
    final canRestore = canEdit && servant.isArchived;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canEdit && !servant.isArchived)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل',
            onPressed: () {
              Navigator.pushNamed(
                context,
                servantEdit,
                arguments: ServantEditArgs(actor: args.actor, servant: servant),
              );
            },
          ),
        if (canArchive)
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            tooltip: 'أرشفة',
            onPressed: () => _handleMutation(
              context,
              title: 'أرشفة الخادم؟',
              content:
                  'سيتم إيقاف حساب ${servant.name} وإزالته من القوائم النشطة حتى تتم استعادته.',
              confirmLabel: 'أرشفة',
              action: () => context.read<ServantDataCubit>().deleteServant(
                actor: args.actor,
                docId: servant.docID,
              ),
            ),
          ),
        if (canRestore)
          IconButton(
            icon: const Icon(Icons.unarchive_outlined),
            tooltip: 'استعادة',
            onPressed: () => _handleMutation(
              context,
              title: 'استعادة الخادم؟',
              content:
                  'سيتم استعادة ${servant.name} وإرسال بريد إعادة تعيين كلمة المرور للحساب المرتبط. يلزم تعيين الفريق يدويا بعد الاستعادة.',
              confirmLabel: 'استعادة',
              action: () => context.read<ServantDataCubit>().restoreServant(
                actor: args.actor,
                docId: servant.docID,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleMutation(
    BuildContext context, {
    required String title,
    required String content,
    required String confirmLabel,
    required Future<void> Function() action,
  }) async {
    final shouldProceed = await showGenericDialog<bool>(
      context: context,
      title: title,
      content: content,
      optionBuilder: () => {'إلغاء': false, confirmLabel: true},
    );
    if (shouldProceed != true || !context.mounted) return;

    await action();
    if (!context.mounted) return;

    final currentState = context.read<ServantDataCubit>().state;
    if (currentState is ServantDataLoaded &&
        currentState.mutationStatus == ServantMutationStatus.success) {
      Navigator.pop(context, true);
    }
  }
}
