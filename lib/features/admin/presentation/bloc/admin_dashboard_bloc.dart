import 'package:church_management_system/features/admin/data/services/admin_statistics_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'admin_dashboard_event.dart';
part 'admin_dashboard_state.dart';

class AdminDashboardBloc
    extends Bloc<AdminDashboardEvent, AdminDashboardState> {
  final AdminStatisticsService _statisticsService;

  AdminDashboardBloc({required AdminStatisticsService statisticsService})
    : _statisticsService = statisticsService,
      super(const AdminDashboardInitial()) {
    on<LoadStats>(_onLoadStats);
    on<ForceRefreshStats>(_onForceRefreshStats);
  }

  Future<void> _onLoadStats(
    LoadStats event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    try {
      final stats = await _statisticsService.getWeeklyAttendanceStats(
        event.teamId,
      );
      emit(AdminDashboardLoaded(stats));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  Future<void> _onForceRefreshStats(
    ForceRefreshStats event,
    Emitter<AdminDashboardState> emit,
  ) async {
    emit(const AdminDashboardLoading());
    try {
      final stats = await _statisticsService.getWeeklyAttendanceStats(
        event.teamId,
        forceRefresh: true,
      );
      emit(AdminDashboardLoaded(stats));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }
}
