import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_event.dart';
import 'package:church_management_system/features/admin/presentation/bloc/dashboard/admin_dashboard_state.dart';
import 'package:church_management_system/features/servant/domain/repos/i_servant_repository.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/team/domain/repos/i_team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@injectable
class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final IStudentRepository _studentRepository;
  final IServantRepository _servantRepository;
  final ITeamRepository _teamRepository;

  AdminDashboardBloc(
    this._studentRepository,
    this._servantRepository,
    this._teamRepository,
  ) : super(AdminDashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(AdminDashboardLoading());
    try {
      final students = await _studentRepository.getAllStudents(
        includeArchived: false,
      );
      final servants = await _servantRepository.getAllServants();
      final teams = await _teamRepository.getAllTeams(includeArchived: false);

      final kpiData = DashboardKpiData(
        totalStudents: students.length,
        totalServants: servants.length,
        totalTeams: teams.length,
        totalSessions: 0, // TODO: Implement real session count
        totalPresent: 0, // TODO: Implement real present count
        attendanceRate: 0.0, // TODO: Implement real attendance rate calculation
      );

      final activities = <ActivityLog>[]; // No recent activity backend yet

      emit(AdminDashboardLoaded(kpiData: kpiData, recentActivity: activities));
    } catch (e) {
      emit(
        const AdminDashboardError(
          'تعذر تحميل بيانات لوحة التحكم. تأكد من الاتصال بالإنترنت.',
        ),
      );
    }
  }
}
