part of 'student_profile_bloc.dart';

sealed class StudentProfileEvent {
  const StudentProfileEvent();
}

final class StudentProfileLoadRequested extends StudentProfileEvent {
  final AuthUser actor;

  const StudentProfileLoadRequested({required this.actor});
}
