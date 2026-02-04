import 'package:church_managment_system/app.dart';
import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/core/theme/app_theme.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_managment_system/features/servant/presentation/bloc/servant_data/servant_data_bloc.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_data/student_data_bloc.dart';
import 'package:church_managment_system/features/student/presentation/bloc/student_profile/student_profile_bloc.dart';
import 'package:church_managment_system/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    // Fallback for platforms without generated options.
    await Firebase.initializeApp();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await _initializeFirebase();

  final studentService = StudentDataRepository();
  final servantService = ServantDataRepository();

  runApp(
    ChurchApp(
      appRoutes: AppRouter(),
      studentService: studentService,
      servantService: servantService,
    ),
  );
}

class ChurchApp extends StatelessWidget {
  const ChurchApp({
    super.key,
    required this.appRoutes,
    required this.studentService,
    required this.servantService,
  });

  final AppRouter appRoutes;
  final StudentDataRepository studentService;
  final ServantDataRepository servantService;

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
        BlocProvider(
          create: (_) => StudentProfileBloc(studentRepository: studentService),
        ),
        BlocProvider(
          create: (_) => ServantDataBloc(repository: servantService),
        ),
      ],
      child: MaterialApp(
        title: 'CSMS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        onGenerateRoute: appRoutes.onGenerateRoute,
        home: const AppRoot(),
      ),
    );
  }
}
