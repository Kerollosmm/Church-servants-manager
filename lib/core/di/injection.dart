import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_mark_repository.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_session_service.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:church_management_system/features/auth/domain/auth_freshness_policy.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Call once before [runApp].
void configureDependencies() {
  // ---- External ----
  getIt
    ..registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    )

    // ---- Auth Freshness ----
    // Note: AuthFreshnessPolicy.initialize() must be called after login
    // and on app cold start to restore persisted state.
    ..registerFactory<AuthFreshnessPolicy>(AuthFreshnessPolicy.new)

    // ---- Services ----
    ..registerLazySingleton<AuthUserProfileStore>(
      () => AuthUserProfileStore(firestore: getIt()),
    )
    ..registerLazySingleton<FirebaseAuthProvider>(
      () =>
          FirebaseAuthProvider(userProfileStore: getIt<AuthUserProfileStore>()),
    )
    ..registerLazySingleton<AuthService>(
      () => AuthService(provider: getIt<FirebaseAuthProvider>()),
    )
    ..registerLazySingleton<AdminUserProvisioningService>(
      () => ClientAdminUserProvisioningService(
        userProfileStore: getIt<AuthUserProfileStore>(),
        authService: getIt<AuthService>(),
      ),
    )

    // ---- Repositories ----
    // Register under interface types (dependency inversion)
    // Also register concrete types as aliases for backward compatibility
    ..registerLazySingleton<IStudentRepository>(
      () => StudentDataRepository(
        firestore: getIt(),
        queryService: getIt<StudentQueryService>(),
        linkedUserSyncService: getIt<StudentLinkedUserSyncService>(),
      ),
    )
    ..registerLazySingleton<StudentDataRepository>(
      () => getIt<IStudentRepository>() as StudentDataRepository,
    )
    ..registerLazySingleton<IServantRepository>(
      () => ServantDataRepository(firestore: getIt()),
    )
    ..registerLazySingleton<ServantDataRepository>(
      () => getIt<IServantRepository>() as ServantDataRepository,
    )
    ..registerLazySingleton<IAttendanceRepository>(
      () => AttendanceRepository(
        firestore: getIt(),
        studentQueryService: getIt<StudentQueryService>(),
      ),
    )
    ..registerLazySingleton<AttendanceRepository>(
      () => getIt<IAttendanceRepository>() as AttendanceRepository,
    )
    ..registerLazySingleton<StudentQueryService>(
      () => StudentQueryService(firestore: getIt()),
    )
    // ---- Attendance ----
    ..registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepository(
        firestore: getIt(),
        studentQueryService: getIt<StudentQueryService>(),
      ),
    )
    ..registerLazySingleton<AttendanceSessionRepository>(
      () => AttendanceSessionRepository(firestore: getIt()),
    )
    ..registerLazySingleton<AttendanceMarkRepository>(
      () => AttendanceMarkRepository(firestore: getIt()),
    )
    ..registerLazySingleton<AttendanceSessionService>(
      () => AttendanceSessionService(
        sessionRepository: getIt<AttendanceSessionRepository>(),
        studentQueryService: getIt<StudentQueryService>(),
      ),
    )
    ..registerLazySingleton<StudentLinkedUserSyncService>(
      () => StudentLinkedUserSyncService(firestore: getIt()),
    )
    ..registerLazySingleton<TeamRepository>(
      () => TeamRepository(firestore: getIt()),
    )
    ..registerLazySingleton<AdminTeamMembershipService>(
      () => AdminTeamMembershipService(firestore: getIt()),
    )
    ..registerLazySingleton<AdminTeamService>(
      () => AdminTeamService(
        firestore: getIt(),
        membershipService: getIt<AdminTeamMembershipService>(),
      ),
    )

    // ---- UseCases ----
    ..registerLazySingleton<GetStudentsStreamUseCase>(
      () => GetStudentsStreamUseCase(getIt<IStudentRepository>()),
    )
    ..registerLazySingleton<CanMutateStudentUseCase>(
      () => const CanMutateStudentUseCase(),
    )

    // ---- Routing ----
    ..registerLazySingleton<AppRouter>(AppRouter.new);
}
