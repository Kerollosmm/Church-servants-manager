import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/routing/role_router.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:church_management_system/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:church_management_system/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/auth/presentation/screens/splash_screen.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/add_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/delete_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/filter_servants_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/get_servants_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/restore_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/update_servant_usecase.dart';
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
        RepositoryProvider<IAttendanceRepository>.value(
          value: getIt<IAttendanceRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authService: context.read<AuthService>(),
              signInUseCase: getIt<SignInUseCase>(),
              signOutUseCase: getIt<SignOutUseCase>(),
              observeAuthStateUseCase: getIt<ObserveAuthStateUseCase>(),
            ),
          ),
          BlocProvider(
            create: (_) => getIt<StudentProfileCubit>(),
          ),
          BlocProvider(
            create: (context) => ServantDataCubit(
              repository: context.read<ServantDataRepository>(),
              adminUserProvisioningService: context
                  .read<AdminUserProvisioningService>(),
              getServantsUseCase: getIt<GetServantsUseCase>(),
              addServantUseCase: getIt<AddServantUseCase>(),
              updateServantUseCase: getIt<UpdateServantUseCase>(),
              deleteServantUseCase: getIt<DeleteServantUseCase>(),
              filterServantsUseCase: getIt<FilterServantsUseCase>(),
              restoreServantUseCase: getIt<RestoreServantUseCase>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'اعداد خدام',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          onGenerateRoute: getIt<AppRouter>().onGenerateRoute,
          builder: (context, child) {
            return MultiBlocListener(
              listeners: RoleRouter.listeners(),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
