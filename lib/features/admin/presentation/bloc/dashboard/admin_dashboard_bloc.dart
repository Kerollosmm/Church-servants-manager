import 'dart:developer' as developer;

import 'package:church_management_system/features/admin/data/datasources/admin_dashboard_local_datasource.dart';
import 'package:church_management_system/features/admin/data/services/admin_statistics_service.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_event.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:church_management_system/features/servant/domain/entities/servant.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/team/domain/entities/team.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final IStudentRepository _studentRepository;
  final IServantRepository _servantRepository;
  final ITeamRepository _teamRepository;
  final AdminStatisticsService _statisticsService;
  final AdminDashboardLocalDatasource _localDatasource;

  AdminDashboardBloc(
    this._studentRepository,
    this._servantRepository,
    this._teamRepository,
    this._statisticsService,
    this._localDatasource,
  ) : super(AdminDashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<AdminDashboardState> emit,
  ) async {
    // 1. Try loading from cache first
    DashboardKpiData? cachedKpi;
    try {
      cachedKpi = await _localDatasource.getKpiData();
      if (cachedKpi != null) {
        emit(
          AdminDashboardLoaded(kpiData: cachedKpi, recentActivity: const []),
        );
      }
    } catch (e) {
      developer.log(
        'Failed to load cached dashboard KPI: $e',
        name: 'AdminDashboardBloc',
      );
    }

    // If no cached data, emit loading state
    if (cachedKpi == null) {
      emit(AdminDashboardLoading());
    }

    try {
      // 2. Fetch fresh data from remote sources in background
      final studentsFuture = _studentRepository
          .getAllStudents(includeArchived: false)
          .then<List<Student>?>((v) => v)
          .catchError((Object e, StackTrace st) {
            developer.log('Students fetch failed', error: e, stackTrace: st);
            return null;
          });
      final servantsFuture = _servantRepository
          .getAllServants()
          .then<List<Servant>?>((v) => v)
          .catchError((Object e, StackTrace st) {
            developer.log('Servants fetch failed', error: e, stackTrace: st);
            return null;
          });
      final teamsFuture = _teamRepository
          .getAllTeams(includeArchived: false)
          .then<List<Team>?>((v) => v)
          .catchError((Object e, StackTrace st) {
            developer.log('Teams fetch failed', error: e, stackTrace: st);
            return null;
          });

      // Change forceRefresh to false to allow cache TTL
      final statsFuture = _statisticsService
          .getGlobalDashboardStats()
          .then<GlobalDashboardStats?>((v) => v)
          .catchError((Object e, StackTrace st) {
            developer.log('Stats query failed', error: e, stackTrace: st);
            return null;
          });

      final results = await Future.wait([
        studentsFuture,
        servantsFuture,
        teamsFuture,
        statsFuture,
      ]);

      final students = results[0] as List<Student>?;
      final servants = results[1] as List<Servant>?;
      final teams = results[2] as List<Team>?;
      final stats = results[3] as GlobalDashboardStats?;

      final totalSessions =
          stats?.totalSessions ?? cachedKpi?.totalSessions ?? 0;
      final totalPresent = stats?.totalPresent ?? cachedKpi?.totalPresent ?? 0;
      final totalRosterEntries = stats?.totalRosterEntries ?? 0;

      final double attendanceRate;
      if (stats != null) {
        final rawRate = totalRosterEntries > 0
            ? (totalPresent / totalRosterEntries * 100)
            : 0.0;
        attendanceRate = double.parse(
          rawRate.clamp(0.0, 100.0).toStringAsFixed(1),
        );
      } else {
        attendanceRate = cachedKpi?.attendanceRate ?? 0.0;
      }

      final freshKpiData = DashboardKpiData(
        totalStudents: students != null
            ? students.length
            : (cachedKpi?.totalStudents ?? 0),
        totalServants: servants != null
            ? servants.length
            : (cachedKpi?.totalServants ?? 0),
        totalTeams: teams != null ? teams.length : (cachedKpi?.totalTeams ?? 0),
        totalSessions: totalSessions,
        totalPresent: totalPresent,
        attendanceRate: attendanceRate,
      );

      // 3. Save fresh KPI data to local cache
      await _localDatasource.saveKpiData(freshKpiData);

      emit(
        AdminDashboardLoaded(kpiData: freshKpiData, recentActivity: const []),
      );
    } catch (e, stack) {
      developer.log('Dashboard error', error: e, stackTrace: stack);
      // Only emit error if we don't have cached data to show
      if (cachedKpi == null) {
        emit(
          const AdminDashboardError(
            'تعذر تحميل بيانات لوحة التحكم. تأكد من الاتصال بالإنترنت.',
          ),
        );
      }
    }
  }
}
