import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:flutter/material.dart';

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
  late final ServantDataRepository _servantRepo;

  @override
  void initState() {
    super.initState();
    _servantRepo = getIt<ServantDataRepository>();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<ServantModel> servants, bool isFromCache})>(
      future: _servantRepo.getServantsByGroupWithFallback(widget.team.groupId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AlertDialog(
            title: const Text('تعيين خادم'),
            content: Text(snapshot.error.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          );
        }

        if (!snapshot.hasData) {
          return const AlertDialog(
            title: Text('تعيين خادم'),
            content: SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final uniqueServants = _uniqueServants(snapshot.data!.servants);

        // Re-normalize and validate selected value whenever servants refresh
        final normalized = _normalizeToServantDocId(
          _selectionInitialized ? _selectedId : widget.team.assignedServantId,
          uniqueServants,
        );

        if (!_selectionInitialized || _selectedId != normalized) {
          _selectedId = normalized;
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
                final selectedServant = _selectedServant(
                  uniqueServants,
                  _selectedId,
                );
                // Dispatch update to TeamBloc
                // This logic should be handled by the parent or a Bloc
                Navigator.pop(context, selectedServant);
              },
              child: const Text('تعيين'),
            ),
          ],
        );
      },
    );
  }

  List<ServantModel> _uniqueServants(List<ServantModel> servants) {
    final seen = <String>{};
    return servants.where((s) => seen.add(s.docID)).toList();
  }

  String? _normalizeToServantDocId(String? id, List<ServantModel> servants) {
    if (id == null) return null;
    final exists = servants.any((s) => s.docID == id);
    return exists ? id : null;
  }

  ServantModel? _selectedServant(List<ServantModel> servants, String? id) {
    if (id == null) return null;
    try {
      return servants.firstWhere((s) => s.docID == id);
    } catch (_) {
      return null;
    }
  }
}
