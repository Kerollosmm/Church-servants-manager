import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/features/auth/domain/auth_freshness_policy.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_mark_repository.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_session_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
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

  // ---- Auth Freshness ----
  getIt.registerLazySingleton<AuthFreshnessPolicy>(() => AuthFreshnessPolicy());

  // ---- Services ----
  getIt.registerLazySingleton<AuthUserProfileStore>(
    () => AuthUserProfileStore(firestore: getIt()),
  );
  getIt.registerLazySingleton<FirebaseAuthProvider>(
    () => FirebaseAuthProvider(userProfileStore: getIt<AuthUserProfileStore>()),
  );
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(provider: getIt<FirebaseAuthProvider>()),
  );
  getIt.registerLazySingleton<AdminUserProvisioningService>(
    () => ClientAdminUserProvisioningService(
      userProfileStore: getIt<AuthUserProfileStore>(),
      authService: getIt<AuthService>(),
    ),
  );

  // ---- Repositories ----
  getIt.registerLazySingleton<StudentDataRepository>(
    () => StudentDataRepository(
      firestore: getIt(),
      queryService: getIt<StudentQueryService>(),
      linkedUserSyncService: getIt<StudentLinkedUserSyncService>(),
    ),
  );
  getIt.registerLazySingleton<ServantDataRepository>(
    () => ServantDataRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<StudentQueryService>(
    () => StudentQueryService(firestore: getIt()),
  );
  // ---- Attendance ----
  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepository(
      firestore: getIt(),
      studentQueryService: getIt<StudentQueryService>(),
    ),
  );
  getIt.registerLazySingleton<AttendanceSessionRepository>(
    () => AttendanceSessionRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<AttendanceMarkRepository>(
    () => AttendanceMarkRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<AttendanceSessionService>(
    () => AttendanceSessionService(
      sessionRepository: getIt<AttendanceSessionRepository>(),
      studentQueryService: getIt<StudentQueryService>(),
    ),
  );
  getIt.registerLazySingleton<StudentLinkedUserSyncService>(
    () => StudentLinkedUserSyncService(firestore: getIt()),
  );
  getIt.registerLazySingleton<TeamRepository>(
    () => TeamRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<AdminTeamMembershipService>(
    () => AdminTeamMembershipService(firestore: getIt()),
  );
  getIt.registerLazySingleton<AdminTeamService>(
    () => AdminTeamService(
      firestore: getIt(),
      membershipService: getIt<AdminTeamMembershipService>(),
    ),
  );

  // ---- UseCases ----
  getIt.registerFactory<GetStudentsStreamUseCase>(
    () => GetStudentsStreamUseCase(getIt<StudentDataRepository>()),
  );
  getIt.registerFactory<CanMutateStudentUseCase>(
    () => const CanMutateStudentUseCase(),
  );

  // ---- Routing ----
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
}
