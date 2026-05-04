import 'dart:developer' as developer;
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_profile_state.dart';

class StudentProfileCubit extends Cubit<StudentProfileState> {
  final IStudentRepository _studentRepository;

  StudentProfileCubit({required IStudentRepository studentRepository})
    : _studentRepository = studentRepository,
      super(const StudentProfileInitial());

  Future<void> loadProfile(AuthUser actor) async {
    emit(const StudentProfileLoading());
    try {
      if (actor.role != UserRole.student) {
        emit(const StudentProfileError('Not allowed.'));
        return;
      }

      final profile = await _studentRepository.getStudentByUid(actor.uid);

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
        name: 'StudentProfileCubit',
      );
      emit(
        const StudentProfileError('Unable to load profile. Please try again.'),
      );
    }
  }

  Future<void> setupProfile(StudentModel newStudent, AuthUser actor) async {
    emit(const StudentProfileLoading());
    try {
      // SECURITY GUARD: Ensure only a student can create their own profile.
      if (actor.role != UserRole.student) {
        emit(
          const StudentProfileError(
            'فقط المخدومين يمكنهم إنشاء ملفات شخصية مخدومة.',
          ),
        );
        return;
      }

      if (newStudent.uid != actor.uid) {
        emit(const StudentProfileError('لا يمكن إنشاء ملف شخصي لمستخدم آخر.'));
        return;
      }

      await _studentRepository.createStudent(newStudent);
      await loadProfile(actor);
    } catch (e) {
      developer.log(
        'Unable to setup profile',
        error: e,
        name: 'StudentProfileCubit',
      );
      emit(
        const StudentProfileError('Unable to setup profile. Please try again.'),
      );
    }
  }
}
