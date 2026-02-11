part of 'student_profile_cubit.dart';

sealed class StudentProfileState {
  const StudentProfileState();
}

final class StudentProfileInitial extends StudentProfileState {
  const StudentProfileInitial();
}

final class StudentProfileLoading extends StudentProfileState {
  const StudentProfileLoading();
}

final class StudentProfileLoaded extends StudentProfileState {
  final StudentModel student;

  const StudentProfileLoaded(this.student);
}

final class StudentProfileError extends StudentProfileState {
  final String message;

  const StudentProfileError(this.message);
}
