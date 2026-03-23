import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/bloc/assign_servant_options_cubit.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_management_system/features/team/presentation/widgets/servant_picker_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssignServantDialogContent extends StatefulWidget {
  const AssignServantDialogContent({
    super.key,
    required this.actor,
    required this.team,
  });

  final AuthUser actor;
  final TeamModel team;

  @override
  State<AssignServantDialogContent> createState() =>
      _AssignServantDialogContentState();
}

class _AssignServantDialogContentState
    extends State<AssignServantDialogContent> {
  String? _selectedId;
  bool _selectionInitialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AssignServantOptionsCubit(
        servantRepository: context.read<ServantDataRepository>(),
      )..load(widget.team.groupId),
      child: BlocBuilder<AssignServantOptionsCubit, AssignServantOptionsState>(
        builder: (context, state) {
          if (state.errorMessage != null) {
            return AlertDialog(
              title: const Text('تعيين خادم'),
              content: Text(state.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
                FilledButton(
                  onPressed: () {
                    _selectionInitialized = false;
                    context.read<AssignServantOptionsCubit>().load(
                      widget.team.groupId,
                    );
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            );
          }

          if (state.isLoading) {
            return const AlertDialog(
              title: Text('تعيين خادم'),
              content: SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          final servants = dedupeServants(state.servants);
          if (!_selectionInitialized) {
            _selectedId = normalizeAssignedServantId(
              widget.team.assignedServantId,
              servants,
            );
            _selectionInitialized = true;
          }

          return AlertDialog(
            title: Text('تعيين خادم - ${widget.team.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.isFromCache)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppInfoBanner(
                      message:
                          'وضع عدم الاتصال: يتم عرض الخدام المخزنين مؤقتا.',
                      icon: Icons.cloud_off_outlined,
                      padding: EdgeInsets.all(AppSpacing.sm),
                    ),
                  ),
                ServantPickerList(
                  servants: servants,
                  selectedId: _selectedId,
                  onChanged: (value) => setState(() => _selectedId = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  final servant = selectedServantByDocId(servants, _selectedId);
                  final cubit = context.read<TeamCubit>();
                  if (servant == null) {
                    cubit.unassignServant(
                      actor: widget.actor,
                      team: widget.team,
                    );
                  } else {
                    cubit.assignServant(
                      actor: widget.actor,
                      team: widget.team,
                      servant: servant,
                    );
                  }
                  Navigator.pop(context);
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }
}
