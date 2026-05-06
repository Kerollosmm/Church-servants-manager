import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/core/widgets/not_found_screen.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/admin/presentation/widget/admin_gate.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_session_create_screen.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_taking_screen.dart';
import 'package:church_management_system/features/attendance/presentation/screens/student_attendance_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/forced_password_reset_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/register_screen.dart';
import 'package:church_management_system/features/devtools/presentation/dev_tools_screen.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
import 'package:church_management_system/features/servant/presentation/screens/add_edit_servant_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_detail_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_list_screen.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_list_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/screens/student_detail_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_edit_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_management_screen.dart';
import 'package:church_management_system/features/team/presentation/screens/team_management_screen.dart';
import 'package:church_management_system/features/team/presentation/screens/team_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  Route<dynamic> _buildPageRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  Route<dynamic> _buildMessageRoute({
    required RouteSettings settings,
    required String message,
  }) {
    return _buildPageRoute(
      settings: settings,
      builder: (_) => Scaffold(body: Center(child: Text(message))),
    );
  }

  Route<dynamic> _buildArgsValidatedRoute<T>({
    required RouteSettings settings,
    required Widget Function(T args) builder,
    required String invalidMessage,
  }) {
    final args = settings.arguments;
    if (args is T) {
      return _buildPageRoute(settings: settings, builder: (_) => builder(args));
    }
    return _buildMessageRoute(settings: settings, message: invalidMessage);
  }

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return _buildPageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case forgotPassword:
        return _buildPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case forcedPasswordReset:
        return _buildPageRoute(
          builder: (_) => const ForcedPasswordResetScreen(),
          settings: settings,
        );
      case studentList:
        return _buildPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => StudentDataBloc(
              studentRepository: getIt<IStudentRepository>(),
              getStudentsList: getIt<GetStudentsListUseCase>(),
              canMutateStudent: getIt<CanMutateStudentUseCase>(),
              provisionUseCase: getIt<ProvisionStudentWithAuthUseCase>(),
            ),
            child: const StudentManagementScreen(),
          ),
          settings: settings,
        );
      case studentDetail:
        return _buildArgsValidatedRoute<StudentDetailArgs>(
          settings: settings,
          builder: (args) => BlocProvider(
            create: (context) => StudentDataBloc(
              studentRepository: getIt<IStudentRepository>(),
              getStudentsList: getIt<GetStudentsListUseCase>(),
              canMutateStudent: getIt<CanMutateStudentUseCase>(),
              provisionUseCase: getIt<ProvisionStudentWithAuthUseCase>(),
            ),
            child: StudentDetailScreen(args: args),
          ),
          invalidMessage: 'Invalid student data',
        );
      case studentEdit:
        return _buildArgsValidatedRoute<StudentEditArgs>(
          settings: settings,
          builder: (args) => Builder(
            builder: (context) => BlocProvider(
              create: (context) => StudentDataBloc(
                studentRepository: getIt<IStudentRepository>(),
                getStudentsList: getIt<GetStudentsListUseCase>(),
                canMutateStudent: getIt<CanMutateStudentUseCase>(),
                provisionUseCase: getIt<ProvisionStudentWithAuthUseCase>(),
              ),
              child: StudentEditScreen(args: args),
            ),
          ),
          invalidMessage: 'Invalid student data',
        );
      // Servant Routes
      case servantList:
        return _buildPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => ServantDataBloc(
              repository: getIt<IServantRepository>(),
              provisionUseCase: getIt<ProvisionServantWithAuthUseCase>(),
            ),
            child: const AdminGate(child: ServantListScreen()),
          ),
          settings: settings,
        );
      case servantDetail:
        return _buildArgsValidatedRoute<ServantDetailArgs>(
          settings: settings,
          builder: (args) => BlocProvider(
            create: (context) => ServantDataBloc(
              repository: getIt<IServantRepository>(),
              provisionUseCase: getIt<ProvisionServantWithAuthUseCase>(),
            ),
            child: AdminGate(child: ServantDetailScreen(args: args)),
          ),
          invalidMessage: 'Invalid servant data',
        );
      case servantEdit:
        return _buildArgsValidatedRoute<ServantEditArgs>(
          settings: settings,
          builder: (args) => BlocProvider(
            create: (context) => ServantDataBloc(
              repository: getIt<IServantRepository>(),
              provisionUseCase: getIt<ProvisionServantWithAuthUseCase>(),
            ),
            child: AdminGate(child: AddEditServantScreen(args: args)),
          ),
          invalidMessage: 'Invalid servant data',
        );

      case devTools:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: DevToolsScreen()),
          settings: settings,
        );

      case teamManagement:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: TeamManagementScreen()),
          settings: settings,
        );
      case teamMembers:
        return _buildArgsValidatedRoute<TeamMembersArgs>(
          settings: settings,
          builder: (args) => AdminGate(child: TeamMembersScreen(args: args)),
          invalidMessage: 'Invalid team member data',
        );
      case adminScreen:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: AdminDashboardScreen()),
          settings: settings,
        );
      case attendanceSessionCreate:
        return _buildPageRoute(
          builder: (_) => const AttendanceSessionCreateScreen(),
          settings: settings,
        );
      case attendanceTaking:
        return _buildArgsValidatedRoute<AttendanceTakingArgs>(
          settings: settings,
          builder: (args) => AttendanceTakingScreen(args: args),
          invalidMessage: 'Invalid attendance session data',
        );
      case attendanceHistory:
        return _buildPageRoute(
          builder: (_) => const AttendanceHistoryScreen(),
          settings: settings,
        );
      case studentAttendance:
        return _buildArgsValidatedRoute<StudentAttendanceArgs>(
          settings: settings,
          builder: (args) => StudentAttendanceScreen(args: args),
          invalidMessage: 'Invalid student attendance data',
        );

      default:
        return _buildPageRoute(
          builder: (_) => const NotFoundScreen(),
          settings: settings,
        );
    }
  }
}
