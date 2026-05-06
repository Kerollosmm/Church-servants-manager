import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:equatable/equatable.dart';

sealed class StudentProfileState extends Equatable {
  const StudentProfileState();

  @override
  List<Object?> get props => [];
}

final class StudentProfileInitial extends StudentProfileState {
  const StudentProfileInitial();
}

final class StudentProfileLoading extends StudentProfileState {
  const StudentProfileLoading();
}

final class StudentProfileProvisioning extends StudentProfileState {
  const StudentProfileProvisioning();
}

final class StudentProfileMissingProfile extends StudentProfileState {
  final String message;

  const StudentProfileMissingProfile(this.message);

  @override
  List<Object?> get props => [message];
}

final class StudentProfileLoaded extends StudentProfileState {
  final StudentModel student;

  const StudentProfileLoaded(this.student);

  @override
  List<Object?> get props => [student];
}

final class StudentProfileError extends StudentProfileState {
  final String message;

  const StudentProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
