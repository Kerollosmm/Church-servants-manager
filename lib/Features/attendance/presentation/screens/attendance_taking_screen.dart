import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_taking_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceTakingScreen extends StatelessWidget {
  const AttendanceTakingScreen({super.key, required this.args});
  final AttendanceTakingArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttendanceSessionAdminCubit>(),
      child: AttendanceTakingView(args: args),
    );
  }
}
