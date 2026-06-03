import 'package:equatable/equatable.dart';

abstract class AttendanceHistoryEvent extends Equatable {
  const AttendanceHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadForTeamEvent extends AttendanceHistoryEvent {
  final String teamId;

  const LoadForTeamEvent(this.teamId);

  @override
  List<Object?> get props => [teamId];
}
