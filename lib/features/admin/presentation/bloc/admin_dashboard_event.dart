part of 'admin_dashboard_bloc.dart';

abstract class AdminDashboardEvent {
  const AdminDashboardEvent();
}

class LoadStats extends AdminDashboardEvent {
  final String teamId;
  const LoadStats(this.teamId);
}

class ForceRefreshStats extends AdminDashboardEvent {
  final String teamId;
  const ForceRefreshStats(this.teamId);
}
