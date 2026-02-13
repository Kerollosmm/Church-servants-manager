import 'package:church_managment_system/church_app.dart';
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

  // -- Composition Root: Create all dependencies here --
  final firestore = FirebaseFirestore.instance;
  final authService = AuthService.firebase();

  final studentService = StudentDataRepository(firestore: firestore);
  final servantService = ServantDataRepository(firestore: firestore);
  final teamRepository = TeamRepository(firestore: firestore);

  runApp(
    ChurchApp(
      appRoutes: AppRouter(),
      authService: authService,
      studentService: studentService,
      servantService: servantService,
      teamRepository: teamRepository,
    ),
  );
}
