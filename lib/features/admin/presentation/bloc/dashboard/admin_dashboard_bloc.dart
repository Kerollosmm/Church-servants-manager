import 'dart:developer' as developer;

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

  AdminDashboardBloc(
    this._studentRepository,
    this._servantRepository,
    this._teamRepository,
    this._statisticsService,
  ) : super(AdminDashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    try {
      // Fetch list data; fall back to empty lists if permissions or network
      // prevent access – we show partial data rather than killing the dashboard.
      final studentsFuture = _studentRepository
          .getAllStudents(includeArchived: false)
          .catchError((Object e, StackTrace st) {
            developer.log(
              'Students fetch failed – using empty list',
              error: e,
              stackTrace: st,
            );
            return <Student>[];
          });
      final servantsFuture = _servantRepository.getAllServants().catchError((
        Object e,
        StackTrace st,
      ) {
        developer.log(
          'Servants fetch failed – using empty list',
          error: e,
          stackTrace: st,
        );
        return <Servant>[];
      });
      final teamsFuture = _teamRepository
          .getAllTeams(includeArchived: false)
          .catchError((Object e, StackTrace st) {
            developer.log(
              'Teams fetch failed – using empty list',
              error: e,
              stackTrace: st,
            );
            return <Team>[];
          });

      // The stats call uses collectionGroup which may fail on Spark-tier
      // security rules or missing fields – fall back to zeros instead of
      // killing the entire dashboard.
      final statsFuture = _statisticsService
          .getGlobalDashboardStats(forceRefresh: true)
          .catchError((Object e, StackTrace st) {
            developer.log(
              'Stats collectionGroup failed – using defaults',
              error: e,
              stackTrace: st,
            );
            return GlobalDashboardStats(
              totalSessions: 0,
              totalPresent: 0,
              totalRosterEntries: 0,
              updatedAt: DateTime(2026),
            );
          });

      final results = await Future.wait([
        studentsFuture,
        servantsFuture,
        teamsFuture,
        statsFuture,
      ]);

      final students = results[0] as List<Student>;
      final servants = results[1] as List;
      final teams = results[2] as List<Team>;
      final stats = results[3] as GlobalDashboardStats;

      final totalSessions = stats.totalSessions;
      final totalPresent = stats.totalPresent;
      final totalRosterEntries = stats.totalRosterEntries;

      final attendanceRate = totalRosterEntries > 0
          ? (totalPresent / totalRosterEntries * 100).clamp(0.0, 100.0)
          : 0.0;

      final kpiData = DashboardKpiData(
        totalStudents: students.length,
        totalServants: servants.length,
        totalTeams: teams.length,
        totalSessions: totalSessions,
        totalPresent: totalPresent,
        attendanceRate: double.parse(attendanceRate.toStringAsFixed(1)),
      );

      final activities = <ActivityLog>[];

      emit(AdminDashboardLoaded(kpiData: kpiData, recentActivity: activities));
    } catch (e, stack) {
      developer.log('Dashboard error', error: e, stackTrace: stack);
      emit(
        const AdminDashboardError(
          'تعذر تحميل بيانات لوحة التحكم. تأكد من الاتصال بالإنترنت.',
        ),
      );
    }
  }
}
