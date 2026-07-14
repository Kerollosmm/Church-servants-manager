import 'package:church_management_system/core/blocs/connectivity/connectivity_cubit.dart';
import 'package:church_management_system/core/blocs/sync/sync_cubit.dart';
import 'package:church_management_system/core/routing/app_router.dart';
import 'package:church_management_system/core/services/dead_letter_queue.dart';
import 'package:church_management_system/core/services/hive_pruning_service.dart';
import 'package:church_management_system/core/services/sync_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/admin/data/datasources/admin_dashboard_local_datasource.dart';
import 'package:church_management_system/features/admin/data/datasources/analytics_local_datasource.dart';
import 'package:church_management_system/features/admin/data/repos/analytics_repository_impl.dart';
import 'package:church_management_system/features/admin/data/services/admin_statistics_service.dart';
import 'package:church_management_system/features/admin/domain/repos/i_analytics_repository.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_bloc.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/local/attendance_session_local_datasource.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_repository.dart';
import 'package:church_management_system/features/attendance/data/repos/attendance_session_repository.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_command_service.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_query_service.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_season_sync_handler.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_session_service.dart';
import 'package:church_management_system/features/attendance/data/services/attendance_sync_handler.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/auth/data/repos/firebase_auth_repository.dart';
import 'package:church_management_system/features/auth/data/services/admin_user_provisioning_service.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_local_store.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:church_management_system/features/auth/data/services/firebase_identity_provider.dart';
import 'package:church_management_system/features/auth/domain/repos/auth_repository.dart';
import 'package:church_management_system/features/results/data/datasources/results_local_datasource.dart';
import 'package:church_management_system/features/results/data/repos/results_repository.dart';
import 'package:church_management_system/features/results/data/services/result_sync_handler.dart';
import 'package:church_management_system/features/results/domain/repos/i_results_repository.dart';
import 'package:church_management_system/features/servant/data/local/servant_local_datasource.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:church_management_system/features/servant/data/services/servant_sync_handler.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/servant/domain/usecases/provision_servant_with_auth_usecase.dart';
import 'package:church_management_system/features/student/data/datasources/pastoral_local_datasource.dart';
import 'package:church_management_system/features/student/data/datasources/student_local_datasource.dart';
import 'package:church_management_system/features/student/data/repos/pastoral_repository.dart';
import 'package:church_management_system/features/student/data/repos/student_data_repository.dart';
import 'package:church_management_system/features/student/data/services/pastoral_sync_handler.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/data/services/student_query_service.dart';
import 'package:church_management_system/features/student/data/services/student_sync_handler.dart';
import 'package:church_management_system/features/student/domain/repos/i_pastoral_repository.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/get_students_list_usecase.dart';
import 'package:church_management_system/features/student/domain/usecases/provision_student_with_auth_usecase.dart';
import 'package:church_management_system/features/team/data/datasources/team_local_datasource.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:church_management_system/features/team/data/services/team_sync_handler.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
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
    ..registerLazySingleton<Connectivity>(Connectivity.new)
    // ---- Sync Handlers ----
    ..registerLazySingleton<StudentSyncHandler>(
      () => StudentSyncHandler(getIt<IStudentRepository>()),
    )
    ..registerLazySingleton<AttendanceSyncHandler>(
      () => AttendanceSyncHandler(getIt<IAttendanceRepository>()),
    )
    ..registerLazySingleton<ResultsSyncHandler>(
      () => ResultsSyncHandler(getIt<IResultsRepository>()),
    )
    ..registerLazySingleton<AttendanceSessionSyncHandler>(
      () => AttendanceSessionSyncHandler(getIt<AttendanceSessionRepository>()),
    )
    ..registerLazySingleton<PastoralSyncHandler>(
      () => PastoralSyncHandler(getIt<IPastoralRepository>()),
    )
    ..registerLazySingleton<TeamSyncHandler>(
      () => TeamSyncHandler(getIt<ITeamRepository>()),
    )
    ..registerLazySingleton<ServantSyncHandler>(
      () => ServantSyncHandler(firestore: getIt<FirebaseFirestore>()),
    )
    // ---- Core Services ----
    ..registerLazySingleton<DeadLetterQueue>(DeadLetterQueue.new)
    ..registerLazySingleton<HivePruningService>(
      () => HivePruningService(deadLetterQueue: getIt<DeadLetterQueue>()),
    )
    ..registerLazySingleton<SyncService>(
      () => SyncService(
        deadLetterQueue: getIt<DeadLetterQueue>(),
        handlers: {
          'MARK_ATTENDANCE': getIt<AttendanceSyncHandler>(),
          'CLEAR_ATTENDANCE': getIt<AttendanceSyncHandler>(),
          'UPSERT_STUDENT': getIt<StudentSyncHandler>(),
          'ARCHIVE_STUDENT': getIt<StudentSyncHandler>(),
          'RESTORE_STUDENT': getIt<StudentSyncHandler>(),
          'UPDATE_RESULT': getIt<ResultsSyncHandler>(),
          'CREATE_SESSION': getIt<AttendanceSessionSyncHandler>(),
          'CLOSE_SESSION': getIt<AttendanceSessionSyncHandler>(),
          'CREATE_PASTORAL_RECORD': getIt<PastoralSyncHandler>(),
          'CREATE_TEAM': getIt<TeamSyncHandler>(),
          'UPDATE_TEAM': getIt<TeamSyncHandler>(),
          'DELETE_TEAM': getIt<TeamSyncHandler>(),
          'RESTORE_TEAM': getIt<TeamSyncHandler>(),
          'CREATE_SERVANT': getIt<ServantSyncHandler>(),
          'UPDATE_SERVANT': getIt<ServantSyncHandler>(),
          'ARCHIVE_SERVANT': getIt<ServantSyncHandler>(),
          'RESTORE_SERVANT': getIt<ServantSyncHandler>(),
        },
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
    ..registerLazySingleton<AdminStatisticsService>(AdminStatisticsService.new)
    ..registerLazySingleton<StudentQueryService>(
      () => StudentQueryService(
        firestore: getIt(),
        localDatasource: getIt<StudentLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<StudentLinkedUserSyncService>(
      () => StudentLinkedUserSyncService(firestore: getIt()),
    );
}

void _registerRepositories() {
  // ---- Repositories ----
  getIt
    ..registerLazySingleton<AttendanceLocalDatasource>(
      AttendanceLocalDatasource.new,
    )
    ..registerLazySingleton<AdminDashboardLocalDatasource>(
      AdminDashboardLocalDatasource.new,
    )
    ..registerLazySingleton<AttendanceSessionLocalDatasource>(
      AttendanceSessionLocalDatasource.new,
    )
    ..registerLazySingleton<IAttendanceRepository>(
      () => AttendanceRepository(
        firestore: getIt(),
        attendanceLocalDatasource: getIt<AttendanceLocalDatasource>(),
        syncServiceGetter: getIt.call,
      ),
    )
    ..registerLazySingleton<AttendanceQueryService>(
      () => AttendanceQueryService(firestore: getIt()),
    )
    ..registerLazySingleton<AttendanceCommandService>(
      () => AttendanceCommandService(
        firestore: getIt(),
        syncServiceGetter: getIt.call,
      ),
    )
    ..registerLazySingleton<AttendanceSessionRepository>(
      () => AttendanceSessionRepository(
        firestore: getIt(),
        localDatasource: getIt<AttendanceSessionLocalDatasource>(),
        syncServiceGetter: getIt.call,
      ),
    )
    ..registerLazySingleton<StudentLocalDatasource>(StudentLocalDatasource.new)
    ..registerLazySingleton<IStudentRepository>(
      () => StudentDataRepository(
        firestore: getIt(),
        queryService: getIt<StudentQueryService>(),
        syncServiceGetter: getIt.call,
        localDatasource: getIt<StudentLocalDatasource>(),
      ),
    )
    ..registerLazySingleton<ResultsLocalDatasource>(ResultsLocalDatasource.new)
    ..registerLazySingleton<IResultsRepository>(
      () => ResultsRepository(
        firestore: getIt(),
        syncServiceGetter: getIt.call,
        localDatasource: getIt<ResultsLocalDatasource>(),
        connectivity: getIt<Connectivity>(),
      ),
    )
    ..registerLazySingleton<TeamLocalDatasource>(TeamLocalDatasource.new)
    ..registerLazySingleton<ITeamRepository>(
      () => TeamRepository(
        firestore: getIt(),
        localDatasource: getIt<TeamLocalDatasource>(),
        syncServiceGetter: getIt.call,
        connectivity: getIt<Connectivity>(),
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
        syncService: getIt<SyncService>(),
        connectivity: getIt<Connectivity>(),
      ),
    )
    ..registerLazySingleton<TeamRepository>(
      () => getIt<ITeamRepository>() as TeamRepository,
    )
    ..registerLazySingleton<AttendanceRepository>(
      () => getIt<IAttendanceRepository>() as AttendanceRepository,
    )
    ..registerLazySingleton<PastoralLocalDatasource>(
      PastoralLocalDatasource.new,
    )
    ..registerLazySingleton<IPastoralRepository>(
      () => PastoralRepository(
        firestore: getIt(),
        localDatasource: getIt<PastoralLocalDatasource>(),
        syncServiceGetter: getIt.call,
      ),
    )
    ..registerLazySingleton<AnalyticsLocalDatasource>(
      AnalyticsLocalDatasource.new,
    )
    ..registerLazySingleton<IAnalyticsRepository>(
      () => AnalyticsRepositoryImpl(
        firestore: getIt(),
        localDatasource: getIt<AnalyticsLocalDatasource>(),
      ),
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
      getIt<AdminDashboardLocalDatasource>(),
    ),
  );
}

void _registerRouting() {
  // ---- Routing ----
  getIt.registerLazySingleton<AppRouter>(AppRouter.new);
}
