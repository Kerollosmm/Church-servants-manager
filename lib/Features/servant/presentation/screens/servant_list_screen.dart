import 'package:church_management_system/features/servant/presentation/widgets/servant_list_coordinator.dart';
import 'package:flutter/material.dart';

/// Displays a searchable list of servants with CRUD support.
class ServantListScreen extends StatelessWidget {
  const ServantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ServantListCoordinator();
  }
}
