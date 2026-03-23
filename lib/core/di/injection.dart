import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/data/services/auth_service.dart';
import 'package:church_management_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:church_management_system/features/auth/domain/usecases/observe_auth_state_usecase.dart';
import 'package:church_management_system/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:church_management_system/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/add_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/delete_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/filter_servants_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/get_servants_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/restore_servant_usecase.dart';
import 'package:church_management_system/features/servant/domain/usecases/update_servant_usecase.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/add_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/delete_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_stream_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/restore_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/search_students_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/update_student_usecase.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/usecases/assign_servant_to_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/create_team_usecase.dart';
import 'package:church_management_system/features/team/domain/usecases/get_teams_usecase.dart';
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
  getIt.registerLazySingleton<AuthUserProfileStore>(
    () => AuthUserProfileStore(firestore: getIt()),
  );
  getIt.registerLazySingleton<FirebaseAuthProvider>(
    () => FirebaseAuthProvider(userProfileStore: getIt<AuthUserProfileStore>()),
  );
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(provider: getIt<FirebaseAuthProvider>()),
  );
  getIt.registerLazySingleton<AuthRepository>(() => getIt<AuthService>());
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
  getIt.registerLazySingleton<IStudentRepository>(
    () => getIt<StudentDataRepository>(),
  );
  getIt.registerLazySingleton<ServantDataRepository>(
    () => ServantDataRepository(firestore: getIt()),
  );
  getIt.registerLazySingleton<StudentQueryService>(
    () => StudentQueryService(firestore: getIt()),
  );
  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepository(
      firestore: getIt(),
      studentQueryService: getIt<StudentQueryService>(),
    ),
  );
  getIt.registerLazySingleton<IAttendanceRepository>(
    () => getIt<AttendanceRepository>(),
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
  getIt.registerFactory<SignInUseCase>(
    () => SignInUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory<SignOutUseCase>(
    () => SignOutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory<ObserveAuthStateUseCase>(
    () => ObserveAuthStateUseCase(getIt<AuthService>()),
  );
  getIt.registerFactory<GetServantsUseCase>(
    () => GetServantsUseCase(getIt<ServantDataRepository>()),
  );
  getIt.registerFactory<AddServantUseCase>(
    () => AddServantUseCase(
      getIt<ServantDataRepository>(),
      getIt<AdminUserProvisioningService>(),
    ),
  );
  getIt.registerFactory<UpdateServantUseCase>(
    () => UpdateServantUseCase(getIt<ServantDataRepository>()),
  );
  getIt.registerFactory<DeleteServantUseCase>(
    () => DeleteServantUseCase(
      getIt<ServantDataRepository>(),
      getIt<AdminUserProvisioningService>(),
    ),
  );
  getIt.registerFactory<FilterServantsUseCase>(
    () => const FilterServantsUseCase(),
  );
  getIt.registerFactory<RestoreServantUseCase>(
    () => RestoreServantUseCase(
      getIt<ServantDataRepository>(),
      getIt<AdminUserProvisioningService>(),
    ),
  );
  getIt.registerFactory<GetStudentsStreamUseCase>(
    () => GetStudentsStreamUseCase(getIt<IStudentRepository>()),
  );
  getIt.registerFactory<CanMutateStudentUseCase>(
    () => const CanMutateStudentUseCase(),
  );
  getIt.registerFactory<GetStudentsUseCase>(
    () => GetStudentsUseCase(
      getIt<StudentDataRepository>(),
      getIt<GetStudentsStreamUseCase>(),
    ),
  );
  getIt.registerFactory<SearchStudentsUseCase>(
    () => const SearchStudentsUseCase(),
  );
  getIt.registerFactory<AddStudentUseCase>(
    () => AddStudentUseCase(
      getIt<StudentDataRepository>(),
      getIt<CanMutateStudentUseCase>(),
      getIt<AdminUserProvisioningService>(),
    ),
  );
  getIt.registerFactory<UpdateStudentUseCase>(
    () => UpdateStudentUseCase(
      getIt<StudentDataRepository>(),
      getIt<CanMutateStudentUseCase>(),
    ),
  );
  getIt.registerFactory<DeleteStudentUseCase>(
    () => DeleteStudentUseCase(
      getIt<StudentDataRepository>(),
      getIt<CanMutateStudentUseCase>(),
      getIt<AdminUserProvisioningService>(),
    ),
  );
  getIt.registerFactory<RestoreStudentUseCase>(
    () => RestoreStudentUseCase(
      getIt<StudentDataRepository>(),
      getIt<AdminUserProvisioningService>(),
    ),
  );
  getIt.registerFactory<GetTeamsUseCase>(
    () => GetTeamsUseCase(getIt<TeamRepository>()),
  );
  getIt.registerFactory<CreateTeamUseCase>(
    () => CreateTeamUseCase(getIt<TeamRepository>()),
  );
  getIt.registerFactory<AssignServantToTeamUseCase>(
    () => AssignServantToTeamUseCase(getIt<AdminTeamService>()),
  );

  // ---- Routing ----
  getIt.registerLazySingleton<AppRouter>(() => AppRouter());
}
