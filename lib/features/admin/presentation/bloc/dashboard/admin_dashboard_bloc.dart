import 'dart:developer' as developer;

import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_event.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:church_management_system/features/attendance/domain/repos/i_attendance_repository.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final IStudentRepository _studentRepository;
  final IServantRepository _servantRepository;
  final ITeamRepository _teamRepository;
  final IAttendanceRepository _attendanceRepository;

  AdminDashboardBloc(
    this._studentRepository,
    this._servantRepository,
    this._teamRepository,
    this._attendanceRepository,
  ) : super(AdminDashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    try {
      final results = await Future.wait([
        _studentRepository.getAllStudents(includeArchived: false),
        _servantRepository.getAllServants(),
        _teamRepository.getAllTeams(includeArchived: false),
      ]);

      final students = results[0] as List<StudentModel>;
      final servants = results[1] as List;
      final teams = results[2] as List<TeamModel>;

      var totalSessions = 0;
      var totalPresent = 0;
      var totalRosterEntries = 0;

      for (final team in teams) {
        try {
          final id = team.id;
          if (id.isEmpty) continue;
          final stats = await _attendanceRepository.getTeamAttendanceStats(
            teamId: id,
          );
          totalSessions += stats.totalSessions;
          totalPresent += stats.attendedCount;
          totalRosterEntries += stats.totalRosterEntries;
        } catch (_) {
          // Skip teams with no attendance data
        }
      }

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
