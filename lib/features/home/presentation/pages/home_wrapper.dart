import 'package:church_managment_system/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/auth/presentation/pages/login_page.dart';
import 'package:church_managment_system/features/servant/presentation/pages/servant_dashboard_page.dart';
import 'package:church_managment_system/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:church_managment_system/shared/domain/entities/user_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          switch (state.user.role) {
            case UserRole.admin:
              return const AdminDashboardPage();
            case UserRole.servant:
              return const ServantDashboardPage();
            case UserRole.student:
              return const StudentDashboardPage();
          }
        } else if (state is AuthUnauthenticated) {
          return const LoginPage();
        }

        // Show loading or splash while checking status
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
