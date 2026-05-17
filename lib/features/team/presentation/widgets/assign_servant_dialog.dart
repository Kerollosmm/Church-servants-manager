import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/presentation/cubit/assign_servant_cubit.dart';
import 'package:church_management_system/features/team/presentation/cubit/assign_servant_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignServantCubit>(
      create: (_) => AssignServantCubit(
        servantRepository: getIt<ServantDataRepository>(),
      )..loadServants(widget.team.groupId),
      child: BlocConsumer<AssignServantCubit, AssignServantState>(
        listener: (context, state) {
          if (state is AssignServantLoaded && !_selectionInitialized) {
            final cubit = context.read<AssignServantCubit>();
            _selectedId = cubit.normalizeSelectedId(
              widget.team.assignedServantId,
              state.servants,
            );
            _selectionInitialized = true;
          }
        },
        builder: (context, state) {
          if (state is AssignServantError) {
            return AlertDialog(
              title: const Text('تعيين خادم'),
              content: Text(state.message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ],
            );
          }

          if (state is AssignServantLoaded) {
            final servants = state.servants;
            final cubit = context.read<AssignServantCubit>();

            final items = <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(child: Text('-- بدون تعيين --')),
              ...servants.map(
                (servant) => DropdownMenuItem<String?>(
                  value: servant.docID,
                  child: Text(servant.name),
                ),
              ),
            ];

            return AlertDialog(
              title: const Text('تعيين خادم للفريق'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختر الخادم الذي سيتم تعيينه لهذا الفريق:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedId,
                    items: items,
                    onChanged: (val) => setState(() => _selectedId = val),
                    decoration: const InputDecoration(
                      labelText: 'الخادم المسؤول',
                      border: OutlineInputBorder(),
                    ),
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
                    final selectedServant = cubit.findServant(
                      servants,
                      _selectedId,
                    );
                    Navigator.pop(context, selectedServant);
                  },
                  child: const Text('تعيين'),
                ),
              ],
            );
          }

          // Loading or initial state
          return const AlertDialog(
            title: Text('تعيين خادم'),
            content: SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        },
      ),
    );
  }
}
