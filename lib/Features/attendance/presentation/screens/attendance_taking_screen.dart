import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_taking_view.dart';
import 'package:flutter/material.dart';

class AttendanceTakingScreen extends StatelessWidget {
  const AttendanceTakingScreen({super.key, required this.args});

  final AttendanceTakingArgs args;

  @override
  Widget build(BuildContext context) {
    return AttendanceTakingView(args: args);
  }
}
