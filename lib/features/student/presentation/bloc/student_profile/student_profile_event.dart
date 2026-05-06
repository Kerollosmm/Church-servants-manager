import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:equatable/equatable.dart';

abstract class StudentProfileEvent extends Equatable {
  const StudentProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends StudentProfileEvent {
  final AuthUser actor;

  const LoadProfileEvent(this.actor);

  @override
  List<Object?> get props => [actor];
}

class SetupProfileEvent extends StudentProfileEvent {
  final StudentModel newStudent;
  final AuthUser actor;

  const SetupProfileEvent({required this.newStudent, required this.actor});

  @override
  List<Object?> get props => [newStudent, actor];
}
