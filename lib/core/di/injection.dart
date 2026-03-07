import 'package:church_managment_system/core/routing/app_router.dart';
import 'package:church_managment_system/features/admin/data/admin_team_service.dart';
import 'package:church_managment_system/features/auth/data/services/auth_service.dart';
import 'package:church_managment_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:church_managment_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_managment_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_managment_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_managment_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Call once before [runApp].
void configureDependencies() {
  // ---- External ----
  getIt.registerLazySingleton<FirebaseFirestore>(() {
    final firestore = FirebaseFirestore.instance;
    // Explicitly configure offline persistence with bounded cache (100MB).
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024,
    );
    return firestore;
  });

  // ---- Services ----
  getIt.registerLazySingleton<FirebaseAuthProvider>(
    () => FirebaseAuthProvider(),
  );
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(provider: getIt<FirebaseAuthProvider>()),
  );

  // ---- Repositories ----
  getIt.registerLazySingleton<StudentDataRepository>(
    () => StudentDataRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<IStudentRepository>(
    () => getIt<StudentDataRepository>(),
  );
  getIt.registerLazySingleton<ServantDataRepository>(
    () => ServantDataRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<TeamRepository>(
    () => TeamRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<AdminTeamService>(
    () => AdminTeamService(firestore: getIt()),
  );

  // ---- UseCases ----
  getIt.registerFactory<GetStudentsStreamUseCase>(
    () => GetStudentsStreamUseCase(getIt<IStudentRepository>()),
  );
  getIt.registerFactory<CanMutateStudentUseCase>(
    () => const CanMutateStudentUseCase(),
  );

  // ---- Routing ----
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
}
