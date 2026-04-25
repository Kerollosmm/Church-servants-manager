import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/theme/app_theme.dart';
import 'package:church_management_system/features/auth/data/repos/firebase_auth_repository.dart';
import 'package:church_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_cubit.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_cubit.dart';
import 'package:church_management_system/role_user_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChurchApp extends StatelessWidget {
  const ChurchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              AuthBloc(authService: getIt<FirebaseAuthRepository>())
                ..add(const AuthEventCheckStatus()),
        ),
        BlocProvider(
          create: (context) => StudentProfileCubit(
            studentRepository: getIt<IStudentRepository>(),
          ),
        ),
        BlocProvider(
          create: (context) => StudentDataBloc(
            studentRepository: getIt<IStudentRepository>(),
            getStudentsStream: getIt<GetStudentsStreamUseCase>(),
            canMutateStudent: getIt<CanMutateStudentUseCase>(),
            provisionUseCase: getIt<ProvisionStudentWithAuthUseCase>(),
          ),
        ),
        BlocProvider(
          create: (context) => ServantDataCubit(
            repository: getIt<IServantRepository>(),
            provisionUseCase: getIt<ProvisionServantWithAuthUseCase>(),
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
    );
  }
}
