import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/student/presentation/widgets/student_detail_view.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, required this.args});

  final StudentDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return StudentDetailView(args: args);
  }
}
