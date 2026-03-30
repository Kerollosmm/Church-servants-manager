import 'package:church_management_system/features/attendance/presentation/widgets/attendance_empty_state.dart';
import 'package:church_management_system/features/attendance/presentation/widgets/attendance_session_create_coordinator.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttendanceSessionCreateScreen extends StatelessWidget {
  const AttendanceSessionCreateScreen({super.key});

  AuthUser? _resolveActor(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    return switch (state) {
      AuthAuthenticated(:final user) => user,
      AuthDegraded(:final user) => user,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final actor = _resolveActor(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء جلسة حضور')),
      body: actor == null
          ? const AttendanceEmptyState(
              icon: Icons.lock_outline,
              title: 'لا يمكن فتح الشاشة الآن',
              message: 'سجّل الدخول بحساب مصرح له لإنشاء جلسة حضور.',
            )
          : AttendanceSessionCreateCoordinator(actor: actor),
    );
  }
}
