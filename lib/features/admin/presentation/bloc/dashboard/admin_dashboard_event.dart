import 'package:equatable/equatable.dart';

abstract class AdminDashboardEvent extends Equatable {
  const AdminDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardData extends AdminDashboardEvent {
  const LoadDashboardData();
}
