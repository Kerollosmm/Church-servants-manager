import 'package:church_managment_system/app.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  final studentService = StudentDataRepository();

  runApp(ChurchApp(appRoutes: AppRouter(), studentService: studentService));
}

class ChurchApp extends StatelessWidget {
  const ChurchApp({
    super.key,
    required this.appRoutes,
    required this.studentService,
  });

  final AppRouter appRoutes;
  final StudentDataRepository studentService;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              AuthBloc(authService: AuthService.firebase())
                ..add(const AuthEventCheckStatus()),
        ),
        BlocProvider(
          create: (_) => StudentDataBloc(studentRepository: studentService),
        ),
      ],
      child: MaterialApp(
        title: 'CSMS',
        debugShowCheckedModeBanner: false,
        onGenerateRoute: appRoutes.onGenerateRoute,
        home: const AppRoot(),
      ),
    );
  }
}
