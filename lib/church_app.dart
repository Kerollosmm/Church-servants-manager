import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/role_user_route.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_cubit.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TeamRepository>.value(
          value: getIt<TeamRepository>(),
        ),
        RepositoryProvider<StudentDataRepository>.value(
          value: getIt<StudentDataRepository>(),
        ),
        RepositoryProvider<ServantDataRepository>.value(
          value: getIt<ServantDataRepository>(),
        ),
        RepositoryProvider<AdminTeamService>.value(
          value: getIt<AdminTeamService>(),
        ),
        RepositoryProvider<AuthService>.value(value: getIt<AuthService>()),
        RepositoryProvider<AdminUserProvisioningService>.value(
          value: getIt<AdminUserProvisioningService>(),
        ),
        RepositoryProvider<GetStudentsStreamUseCase>.value(
          value: getIt<GetStudentsStreamUseCase>(),
        ),
        RepositoryProvider<CanMutateStudentUseCase>.value(
          value: getIt<CanMutateStudentUseCase>(),
        ),
        RepositoryProvider<AttendanceRepository>.value(
          value: getIt<AttendanceRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authService: context.read<AuthService>())
                  ..add(const AuthEventCheckStatus()),
          ),
          BlocProvider(
            create: (context) => StudentProfileCubit(
              studentRepository: context.read<StudentDataRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ServantDataCubit(
              repository: context.read<ServantDataRepository>(),
              adminUserProvisioningService: context
                  .read<AdminUserProvisioningService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'اعداد خدام',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
          home: const RoleUserRoute(),
        ),
      ),
    );
  }
}
