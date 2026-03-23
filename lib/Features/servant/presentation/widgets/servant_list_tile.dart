import 'package:church_management_system/core/widgets/cards/person_list_card.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:flutter/material.dart';

class ServantListTile extends StatelessWidget {
  const ServantListTile({
    super.key,
    required this.servant,
    required this.onTap,
  });

  final ServantModel servant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PersonListCard(
      name: servant.name,
      subtitle: servant.isArchived
          ? 'خادم مؤرشف'
          : 'المجموعة: ${servant.teamName ?? '--'}',
      onTap: onTap,
    );
  }
}
