import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/core/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_profile_event.dart';
part 'student_profile_state.dart';

class StudentProfileBloc extends Bloc<StudentProfileEvent, StudentProfileState> {
  final StudentDataRepository _studentRepository;

  StudentProfileBloc({required StudentDataRepository studentRepository})
      : _studentRepository = studentRepository,
        super(const StudentProfileInitial()) {
    on<StudentProfileLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    StudentProfileLoadRequested event,
    Emitter<StudentProfileState> emit,
  ) async {
    emit(const StudentProfileLoading());
    try {
      if (event.actor.role != UserRole.student) {
        emit(const StudentProfileError('Not allowed.'));
        return;
      }

      final profile = await _studentRepository.getStudentByUid(event.actor.uid);
      if (profile == null) {
        emit(const StudentProfileError('Profile not found.'));
        return;
      }
      emit(StudentProfileLoaded(profile));
    } catch (e) {
      debugPrint('StudentProfileBloc: Unable to load profile - $e');
      emit(const StudentProfileError('Unable to load profile. Please try again.'));
    }
  }
}

