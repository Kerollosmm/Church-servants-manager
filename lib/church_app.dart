import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_managment_system/role_user_route.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/core/theme/app_theme.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_profile/student_profile_cubit.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:church_managment_system/features/team/presentation/bloc/team_cubit.dart';
import 'package:church_managment_system/features/admin/data/admin_team_service.dart';
import 'package:church_managment_system/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({
    super.key,
    required this.appRoutes,
    required this.authService,
    required this.studentService,
    required this.servantService,
    required this.teamRepository,
    required this.adminTeamService,
  });

  final AppRouter appRoutes;
  final AuthService authService;
  final StudentDataRepository studentService;
  final ServantDataRepository servantService;
  final TeamRepository teamRepository;
  final AdminTeamService adminTeamService;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TeamRepository>.value(value: teamRepository),
        RepositoryProvider<StudentDataRepository>.value(value: studentService),
        RepositoryProvider<ServantDataRepository>.value(value: servantService),
        RepositoryProvider<AdminTeamService>.value(value: adminTeamService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AuthBloc(authService: authService)
                  ..add(const AuthEventCheckStatus()),
          ),
          BlocProvider(
            create: (_) => StudentDataBloc(studentRepository: studentService),
          ),
          BlocProvider(
            create: (_) =>
                StudentProfileCubit(studentRepository: studentService),
          ),
          BlocProvider(
            create: (_) => ServantDataCubit(repository: servantService),
          ),
          BlocProvider(
            create: (_) => TeamCubit(
              teamRepository: teamRepository,
              adminTeamService: adminTeamService,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'اعداد خدام',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          onGenerateRoute: appRoutes.onGenerateRoute,
          home: const RoleUserRoute(),
        ),
      ),
    );
  }
}
