import 'package:church_management_system/core/theme/app_spacing.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:flutter/material.dart';

List<ServantModel> dedupeServants(List<ServantModel> servants) {
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

String? normalizeAssignedServantId(String? rawId, List<ServantModel> servants) {
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

ServantModel? selectedServantByDocId(
  List<ServantModel> servants,
  String? selectedId,
) {
  if (selectedId == null) return null;
  for (final servant in servants) {
    if (servant.docID == selectedId) return servant;
  }
  return null;
}

class ServantPickerList extends StatefulWidget {
  const ServantPickerList({
    super.key,
    required this.servants,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ServantModel> servants;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  State<ServantPickerList> createState() => _ServantPickerListState();
}

class _ServantPickerListState extends State<ServantPickerList> {
  String _query = '';

  List<ServantModel> get _visibleServants {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.servants;
    return widget.servants
        .where((servant) {
          return servant.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final visibleServants = _visibleServants;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'ابحث عن خادم...',
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        AppSpacing.gapMd,
        _ServantChoiceTile(
          title: 'بدون تعيين',
          isSelected: widget.selectedId == null,
          onTap: () => widget.onChanged(null),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 240,
          width: double.maxFinite,
          child: visibleServants.isEmpty
              ? const Center(child: Text('لا توجد نتائج مطابقة.'))
              : ListView.separated(
                  itemCount: visibleServants.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final servant = visibleServants[index];
                    return _ServantChoiceTile(
                      title: servant.name,
                      isSelected: widget.selectedId == servant.docID,
                      onTap: () => widget.onChanged(servant.docID),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ServantChoiceTile extends StatelessWidget {
  const _ServantChoiceTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      selected: isSelected,
      onTap: onTap,
    );
  }
}
