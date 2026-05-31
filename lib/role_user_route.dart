import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/di/injection.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_list_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RoleUserRoute extends StatelessWidget {
  final Widget child;
  final AuthUser user;

  const RoleUserRoute({super.key, required this.child, required this.user});

  @override
  Widget build(BuildContext context) {
    List<BlocProvider> featureProviders = [];

    switch (user.role) {
      case UserRole.servant:
      case UserRole.admin:
        featureProviders = [
          BlocProvider<StudentDataBloc>(
            create: (context) => StudentDataBloc(
              studentRepository: getIt<IStudentRepository>(),
              getStudentsList: getIt<GetStudentsListUseCase>(),
              canMutateStudent: getIt<CanMutateStudentUseCase>(),
              provisionUseCase: getIt<ProvisionStudentWithAuthUseCase>(),
            ),
          ),
          BlocProvider<ServantDataBloc>(
            create: (context) => ServantDataBloc(
              repository: getIt<IServantRepository>(),
              provisionUseCase: getIt<ProvisionServantWithAuthUseCase>(),
            ),
          ),
        ];
        break;
      case UserRole.student:
        featureProviders = [
          BlocProvider<StudentProfileBloc>(
            create: (context) => StudentProfileBloc(
              studentRepository: getIt<IStudentRepository>(),
            ),
          ),
        ];
        break;
    }

    if (featureProviders.isEmpty) {
      return child;
    }

    return MultiBlocProvider(providers: featureProviders, child: child);
  }
}
