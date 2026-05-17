import 'package:church_management_system/core/blocs/connectivity/connectivity_cubit.dart';
import 'package:church_management_system/core/blocs/sync/sync_cubit.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/hive_pruning_service.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/admin/data/services/admin_statistics_service.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_bloc.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_mark_repository.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_command_service.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_query_service.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_session_service.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/repos/firebase_auth_repository.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_local_store.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/data/services/firebase_identity_provider.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:church_management_system/features/results/data/datasources/results_local_datasource.dart';
import 'package:church_management_system/features/results/data/repos/results_repository.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:church_management_system/features/servant/data/local/servant_local_datasource.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/student/data/datasources/student_local_datasource.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_list_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
import 'package:church_management_system/features/team/data/datasources/team_local_datasource.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

/// Call once before [runApp].
void configureDependencies() {
  _registerCore();
  _registerServices();
  _registerRepositories();
  _registerUseCases();
  _registerBlocs();
  _registerRouting();
}

void _registerCore() {
  // ---- External ----
  getIt
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    // ---- Core Services ----
    ..registerLazySingleton<DeadLetterQueue>(DeadLetterQueue.new)
    ..registerLazySingleton<HivePruningService>(
      () => HivePruningService(deadLetterQueue: getIt<DeadLetterQueue>()),
    )
    ..registerLazySingleton<SyncService>(
      () => SyncService(
        attendanceRepository: getIt<IAttendanceRepository>(),
        studentRepository: getIt<IStudentRepository>(),
        resultsRepository: getIt<IResultsRepository>(),
        sessionRepository: getIt<AttendanceSessionRepository>(),
        deadLetterQueue: getIt<DeadLetterQueue>(),
      ),
    )
    ..registerFactory<SyncCubit>(
      () => SyncCubit(syncService: getIt<SyncService>()),
    )
    ..registerLazySingleton<ConnectivityCubit>(ConnectivityCubit.new);
}

void _registerServices() {
  // ---- Services (Low-level) ----
  getIt
    ..registerLazySingleton<FirebaseIdentityProvider>(
      () => FirebaseIdentityProvider(auth: FirebaseAuth.instance),
    )
    ..registerLazySingleton<AuthUserLocalStore>(AuthUserLocalStore.new)
    ..registerLazySingleton<AuthUserProfileStore>(
      () => AuthUserProfileStore(
        firestore: getIt(),
        localStore: getIt<AuthUserLocalStore>(),
      ),
    )
    ..registerLazySingleton<AdminStatisticsService>(
      AdminStatisticsService.new,
    )
    ..registerLazySingleton<StudentQueryService>(
      () => StudentQueryService(firestore: getIt()),
    )
    ..registerLazySingleton<StudentLinkedUserSyncService>(
      () => StudentLinkedUserSyncService(firestore: getIt()),
    );
}

void _registerRepositories() {
  // ---- Repositories ----
  getIt
    ..registerLazySingleton<IAttendanceRepository>(
      () => AttendanceRepository(firestore: getIt()),
    )
    ..registerLazySingleton<AttendanceQueryService>(
      () => AttendanceQueryService(firestore: getIt()),
    )
    ..registerLazySingleton<AttendanceCommandService>(
      () => AttendanceCommandService(firestore: getIt()),
    )
    ..registerLazySingleton<AttendanceMarkRepository>(
      () => AttendanceMarkRepository(
        firestore: getIt(),
        localDatasource: getIt<AttendanceLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<AttendanceSessionRepository>(
      () => AttendanceSessionRepository(
        firestore: getIt(),
        localDatasource: getIt<AttendanceSessionLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<AttendanceLocalDatasource>(
      AttendanceLocalDatasource.new,
    )
    ..registerLazySingleton<AttendanceSessionLocalDatasource>(
      AttendanceSessionLocalDatasource.new,
    )
    ..registerLazySingleton<StudentLocalDatasource>(StudentLocalDatasource.new)
    ..registerLazySingleton<IStudentRepository>(
      () => StudentDataRepository(
        firestore: getIt(),
        localDatasource: getIt<StudentLocalDatasource>(),
        enqueue: (entry) => getIt<SyncService>().enqueue(entry),
      ),
    )
    ..registerLazySingleton<ResultsLocalDatasource>(ResultsLocalDatasource.new)
    ..registerLazySingleton<IResultsRepository>(
      () => ResultsRepository(
        firestore: getIt(),
        localDatasource: getIt<ResultsLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<TeamLocalDatasource>(TeamLocalDatasource.new)
    ..registerLazySingleton<ITeamRepository>(
      () => TeamRepository(
        firestore: getIt(),
        localDatasource: getIt<TeamLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(
        identityProvider: getIt<FirebaseIdentityProvider>(),
        userProfileStore: getIt<AuthUserProfileStore>(),
        localAuthStore: getIt<AuthUserLocalStore>(),
        firestore: getIt<FirebaseFirestore>(),
      ),
    )
    ..registerLazySingleton<StudentDataRepository>(
      () => getIt<IStudentRepository>() as StudentDataRepository,
    )
    ..registerLazySingleton<ServantLocalDatasource>(ServantLocalDatasource.new)
    ..registerLazySingleton<IServantRepository>(
      () => ServantDataRepository(
        firestore: getIt(),
        localDatasource: getIt<ServantLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<TeamRepository>(
      () => getIt<ITeamRepository>() as TeamRepository,
    );
}

void _registerUseCases() {
  // ---- Domain Services / Use Cases ----
  getIt
    ..registerLazySingleton<AdminTeamService>(
      () => AdminTeamService(firestore: getIt()),
    )
    ..registerLazySingleton<AttendanceSessionService>(
      () => AttendanceSessionService(
        commandService: getIt<AttendanceCommandService>(),
      ),
    )
    ..registerLazySingleton<GetStudentsListUseCase>(
      () => GetStudentsListUseCase(getIt<IStudentRepository>()),
    )
    ..registerLazySingleton<CanMutateStudentUseCase>(
      () => const CanMutateStudentUseCase(),
    )
    ..registerLazySingleton<AdminTeamMembershipService>(
      AdminTeamMembershipService.new,
    )
    ..registerLazySingleton<AdminUserProvisioningService>(
      () => ClientAdminUserProvisioningService(
        userProfileStore: getIt<AuthUserProfileStore>(),
        authService: getIt<AuthRepository>(),
      ),
    )
    ..registerLazySingleton<ProvisionStudentWithAuthUseCase>(
      () => ProvisionStudentWithAuthUseCase(
        studentRepository: getIt<IStudentRepository>(),
        provisioningService: getIt<AdminUserProvisioningService>(),
      ),
    )
    ..registerLazySingleton<ProvisionServantWithAuthUseCase>(
      () => ProvisionServantWithAuthUseCase(
        servantRepository: getIt<IServantRepository>(),
        provisioningService: getIt<AdminUserProvisioningService>(),
      ),
    );
}

void _registerBlocs() {
  // ---- Dashboard Blocs ----
  getIt.registerFactory<AdminDashboardBloc>(
    () => AdminDashboardBloc(
      getIt<IStudentRepository>(),
      getIt<IServantRepository>(),
      getIt<ITeamRepository>(),
      getIt<AdminStatisticsService>(),
    ),
  );
}

void _registerRouting() {
  // ---- Routing ----
  getIt.registerLazySingleton<AppRouter>(AppRouter.new);
}
