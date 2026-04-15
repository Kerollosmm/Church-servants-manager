import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/core/widgets/common/app_info_banner.dart';
import 'package:church_management_system/core/widgets/form/app_dropdown_field.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/bloc/assign_servant_options_cubit.dart';
import 'package:church_management_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:church_management_system/core/di/injection.dart';

class AssignServantDialog extends StatefulWidget {
  final AuthUser actor;
  final TeamModel team;

  const AssignServantDialog({
    super.key,
    required this.actor,
    required this.team,
  });

  @override
  State<AssignServantDialog> createState() => _AssignServantDialogState();
}

class _AssignServantDialogState extends State<AssignServantDialog> {
  String? _selectedId;
  var _selectionInitialized = false;
  late AssignServantOptionsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AssignServantOptionsCubit(
      servantRepository: getIt<ServantDataRepository>(),
    )..load(widget.team.groupId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
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
                    _cubit.load(widget.team.groupId);
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

          final uniqueServants = _uniqueServants(state.servants);

          if (!_selectionInitialized) {
            _selectedId = _normalizeToServantDocId(
              widget.team.assignedServantId,
              uniqueServants,
            );
            _selectionInitialized = true;
          }

          final items = <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(child: Text('-- بدون تعيين --')),
            ...uniqueServants.map(
              (servant) => DropdownMenuItem<String?>(
                value: servant.docID,
                child: Text(servant.name),
              ),
            ),
          ];

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
                AppDropdownField<String?>(
                  initialValue: _selectedId,
                  isExpanded: true,
                  labelText: 'الخادم المسؤول',
                  prefixIcon: Icons.person_outline,
                  items: items,
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
                  final selectedServant = _selectedServant(
                    uniqueServants,
                    _selectedId,
                  );
                  if (selectedServant == null) {
                    context.read<TeamCubit>().unassignServant(
                      actor: widget.actor,
                      team: widget.team,
                    );
                  } else {
                    context.read<TeamCubit>().assignServant(
                      actor: widget.actor,
                      team: widget.team,
                      servant: selectedServant,
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

  List<ServantModel> _uniqueServants(List<ServantModel> servants) {
    final uniqueServants = <ServantModel>[];
    final seenDocIds = <String>{};
    for (final servant in servants) {
      final docId = servant.docID.trim();
      if (docId.isEmpty || seenDocIds.contains(docId)) continue;
      seenDocIds.add(docId);
      uniqueServants.add(servant);
    }
    return uniqueServants;
  }

  String? _normalizeToServantDocId(String? rawId, List<ServantModel> servants) {
    if (rawId == null) return null;
    final id = rawId.trim();
    if (id.isEmpty) return null;

    for (final servant in servants) {
      if (servant.docID == id) return servant.docID;
    }
    for (final servant in servants) {
      if (servant.uid == id) return servant.docID;
    }
    return null;
  }

  ServantModel? _selectedServant(
    List<ServantModel> servants,
    String? selectedId,
  ) {
    if (selectedId == null) return null;
    for (final servant in servants) {
      if (servant.docID == selectedId) return servant;
    }
    return null;
  }
}
