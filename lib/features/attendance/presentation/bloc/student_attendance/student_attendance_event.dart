import 'package:equatable/equatable.dart';

abstract class StudentAttendanceEvent extends Equatable {
  const StudentAttendanceEvent();

  @override
  List<Object?> get props => [];
}

class LoadForStudentEvent extends StudentAttendanceEvent {
  final String studentId;
  final String? teamId;

  const LoadForStudentEvent({required this.studentId, this.teamId});

  @override
  List<Object?> get props => [studentId, teamId];
}
