import 'package:church_management_system/core/constants/routes.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/admin/presentation/widget/admin_gate.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_history_screen.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_session_create_screen.dart';
import 'package:church_management_system/features/attendance/presentation/screens/attendance_taking_screen.dart';
import 'package:church_management_system/features/attendance/presentation/screens/student_attendance_screen.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_history/attendance_history_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/session_admin/attendance_session_admin_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/attendance_taking/attendance_taking_cubit.dart';
import 'package:church_management_system/features/attendance/presentation/bloc/student_attendance/student_attendance_cubit.dart';
import 'package:church_management_system/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:church_management_system/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/login_screen.dart';
import 'package:church_management_system/features/auth/presentation/screens/register_screen.dart';
import 'package:church_management_system/core/routing/route_args.dart';
import 'package:church_management_system/features/devtools/presentation/dev_tools_screen.dart';
import 'package:church_management_system/features/student/domain/usecases/add_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/delete_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/restore_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/search_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/update_student_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/screens/student_detail_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_edit_screen.dart';
import 'package:church_management_system/features/student/presentation/screens/student_management_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_list_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/servant_detail_screen.dart';
import 'package:church_management_system/features/servant/presentation/screens/add_edit_servant_screen.dart';
import 'package:church_management_system/features/team/presentation/screens/team_management_screen.dart';
import 'package:church_management_system/features/team/presentation/screens/team_members_screen.dart';
import 'package:flutter/foundation.dart';
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

  Widget _withStudentDataBloc(Widget child) {
    // FIX [P1-A]: Remove BuildContext param; all deps now resolved via getIt
    // FIX [007]: Pass use cases directly; fallback constructors removed from
    // StudentDataBloc so every dependency must come through the DI container.
    return BlocProvider(
      create: (_) => StudentDataBloc(
        getStudentsUseCase: getIt<GetStudentsUseCase>(),
        searchStudentsUseCase: getIt<SearchStudentsUseCase>(),
        addStudentUseCase: getIt<AddStudentUseCase>(),
        updateStudentUseCase: getIt<UpdateStudentUseCase>(),
        deleteStudentUseCase: getIt<DeleteStudentUseCase>(),
        restoreStudentUseCase: getIt<RestoreStudentUseCase>(),
      ),
      child: child,
    );
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
      case studentList:
        return _buildPageRoute(
          builder: (_) => _withStudentDataBloc(
            const StudentManagementScreen(),
          ), // FIX [P1-A]: Remove context arg; getIt resolves all deps
          settings: settings,
        );
      case studentDetail:
        return _buildArgsValidatedRoute<StudentDetailArgs>(
          settings: settings,
          builder: (args) => _withStudentDataBloc(
            StudentDetailScreen(args: args),
          ), // FIX [P1-A]: Remove Builder+context; getIt resolves all deps
          invalidMessage: 'Invalid student data',
        );
      case studentEdit:
        return _buildArgsValidatedRoute<StudentEditArgs>(
          settings: settings,
          builder: (args) => _withStudentDataBloc(
            StudentEditScreen(args: args),
          ), // FIX [P1-A]: Remove Builder+context; getIt resolves all deps
          invalidMessage: 'Invalid student data',
        );
      // Servant Routes
      case servantList:
        return _buildPageRoute(
          builder: (_) => const AdminGate(child: ServantListScreen()),
          settings: settings,
        );
      case servantDetail:
        return _buildArgsValidatedRoute<ServantDetailArgs>(
          settings: settings,
          builder: (args) => AdminGate(child: ServantDetailScreen(args: args)),
          invalidMessage: 'Invalid servant data',
        );
      case servantEdit:
        return _buildArgsValidatedRoute<ServantEditArgs>(
          settings: settings,
          builder: (args) => AdminGate(child: AddEditServantScreen(args: args)),
          invalidMessage: 'Invalid servant data',
        );

      // FIX [004-M3]: devTools not accessible in release builds.
      case devTools:
        if (kDebugMode) {
          return _buildPageRoute(
            builder: (_) => const AdminGate(child: DevToolsScreen()),
            settings: settings,
          );
        }
        return _buildPageRoute(
          builder: (_) => const NotFoundScreen(),
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
          builder: (_) => AdminGate(
            child: BlocProvider<AdminDashboardCubit>(
              create: (_) => getIt<AdminDashboardCubit>(),
              child: const AdminDashboardScreen(),
            ),
          ),
          settings: settings,
        );
      case attendanceSessionCreate:
        return _buildPageRoute(
          builder: (_) => BlocProvider<AttendanceSessionAdminCubit>(
            create: (_) => getIt<AttendanceSessionAdminCubit>(),
            child: const AttendanceSessionCreateScreen(),
          ),
          settings: settings,
        );
      case attendanceTaking:
        return _buildArgsValidatedRoute<AttendanceTakingArgs>(
          settings: settings,
          builder: (args) => BlocProvider<AttendanceTakingCubit>(
            lazy: false,
            create: (_) =>
                getIt<AttendanceTakingCubit>()
                  ..initialize(teamId: args.teamId, sessionId: args.sessionId),
            child: AttendanceTakingScreen(args: args),
          ),
          invalidMessage: 'Invalid attendance session data',
        );
      case attendanceHistory:
        return _buildPageRoute(
          builder: (_) => BlocProvider<AttendanceHistoryCubit>(
            create: (_) => getIt<AttendanceHistoryCubit>(),
            child: const AttendanceHistoryScreen(),
          ),
          settings: settings,
        );
      case studentAttendance:
        return _buildArgsValidatedRoute<StudentAttendanceArgs>(
          settings: settings,
          builder: (args) => BlocProvider<StudentAttendanceCubit>(
            lazy: false,
            create: (_) =>
                getIt<StudentAttendanceCubit>()
                  ..load(args.studentId, teamId: args.filterTeamId),
            child: StudentAttendanceScreen(args: args),
          ),
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

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Not Found')));
}
