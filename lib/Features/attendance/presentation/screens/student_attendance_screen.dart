import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/student_attendance_view.dart';
import 'package:flutter/material.dart';

class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key, required this.args});
  final StudentAttendanceArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('حضور ${args.studentName}')),
      body: StudentAttendanceView(args: args),
    );
  }
}
