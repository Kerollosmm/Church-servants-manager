import 'package:church_managment_system/core/di/injection.dart';
import 'package:church_managment_system/role_user_route.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/core/theme/app_theme.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_managment_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_profile/student_profile_cubit.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:church_managment_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_managment_system/features/admin/data/admin_team_service.dart';
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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AuthBloc(authService: getIt<AuthService>())
                  ..add(const AuthEventCheckStatus()),
          ),
          BlocProvider(
            create: (_) => StudentDataBloc(
              studentRepository: getIt<StudentDataRepository>(),
              getStudentsStream: getIt<GetStudentsStreamUseCase>(),
              canMutateStudent: getIt<CanMutateStudentUseCase>(),
            ),
          ),
          BlocProvider(
            create: (_) => StudentProfileCubit(
              studentRepository: getIt<StudentDataRepository>(),
            ),
          ),
          BlocProvider(
            create: (_) =>
                ServantDataCubit(repository: getIt<ServantDataRepository>()),
          ),
          BlocProvider(
            create: (_) => TeamCubit(
              teamRepository: getIt<TeamRepository>(),
              adminTeamService: getIt<AdminTeamService>(),
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
