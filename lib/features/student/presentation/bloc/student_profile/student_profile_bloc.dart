import 'dart:developer' as developer;

import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_event.dart';
import 'package:church_management_system/features/student/presentation/bloc/student_profile/student_profile_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudentProfileBloc
    extends Bloc<StudentProfileEvent, StudentProfileState> {
  final IStudentRepository _studentRepository;

  StudentProfileBloc({required IStudentRepository studentRepository})
    : _studentRepository = studentRepository,
      super(const StudentProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<SetupProfileEvent>(_onSetupProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
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
        emit(
          const StudentProfileMissingProfile(
            'Your student profile has not been set up yet. Please complete your profile below.',
          ),
        );
        return;
      }

      emit(StudentProfileLoaded(profile));
    } catch (e) {
      developer.log(
        'Unable to load profile',
        error: e,
        name: 'StudentProfileBloc',
      );
      emit(
        const StudentProfileError('Unable to load profile. Please try again.'),
      );
    }
  }

  Future<void> _onSetupProfile(
    SetupProfileEvent event,
    Emitter<StudentProfileState> emit,
  ) async {
    emit(const StudentProfileLoading());
    try {
      // SECURITY GUARD: Ensure only a student can create their own profile.
      if (event.actor.role != UserRole.student) {
        emit(
          const StudentProfileError(
            'فقط المخدومين يمكنهم إنشاء ملفات شخصية مخدومة.',
          ),
        );
        return;
      }

      if (event.newStudent.uid != event.actor.uid) {
        emit(const StudentProfileError('لا يمكن إنشاء ملف شخصي لمستخدم آخر.'));
        return;
      }

      await _studentRepository.createStudent(event.newStudent);
      add(LoadProfileEvent(event.actor));
    } catch (e) {
      developer.log(
        'Unable to setup profile',
        error: e,
        name: 'StudentProfileBloc',
      );
      emit(
        const StudentProfileError('Unable to setup profile. Please try again.'),
      );
    }
  }
}
