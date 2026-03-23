import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_edit_coordinator.dart';
import 'package:flutter/material.dart';

class StudentEditScreen extends StatelessWidget {
  const StudentEditScreen({super.key, required this.args});

  final StudentEditArgs args;

  @override
  Widget build(BuildContext context) {
    return StudentEditCoordinator(args: args);
  }
}
