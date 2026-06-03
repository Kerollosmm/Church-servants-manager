import 'package:equatable/equatable.dart';

// Mock model for Activity Log until domain layer is implemented
class ActivityLog extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String type; // 'person', 'event', 'assignment'

  const ActivityLog({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
  });

  @override
  List<Object?> get props => [id, title, subtitle, time, type];
}

// Mock model for KPI Data
class DashboardKpiData extends Equatable {
  final int totalStudents;
  final int totalServants;
  final int totalTeams;
  final int totalSessions;
  final int totalPresent;
  final double attendanceRate;

  const DashboardKpiData({
    required this.totalStudents,
    required this.totalServants,
    required this.totalTeams,
    required this.totalSessions,
    required this.totalPresent,
    required this.attendanceRate,
  });

  @override
  List<Object?> get props => [
    totalStudents,
    totalServants,
    totalTeams,
    totalSessions,
    totalPresent,
    attendanceRate,
  ];
}

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final DashboardKpiData kpiData;
  final List<ActivityLog> recentActivity;

  const AdminDashboardLoaded({
    required this.kpiData,
    required this.recentActivity,
  });

  @override
  List<Object?> get props => [kpiData, recentActivity];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
