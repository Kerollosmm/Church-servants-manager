import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_profile_state.dart';

class StudentProfileCubit extends Cubit<StudentProfileState> {
  final StudentDataRepository _studentRepository;

  StudentProfileCubit({required StudentDataRepository studentRepository})
    : _studentRepository = studentRepository,
      super(const StudentProfileInitial());

  Future<void> loadProfile(AuthUser actor) async {
    emit(const StudentProfileLoading());
    try {
      if (actor.role != UserRole.student) {
        emit(const StudentProfileError('Not allowed.'));
        return;
      }

      var profile = await _studentRepository.getStudentByUid(actor.uid);

      if (profile == null) {
        emit(
          const StudentProfileMissingProfile(
            'Your student profile has not been set up yet. Please contact an admin/teacher.',
          ),
        );
        return;
      }

      emit(StudentProfileLoaded(profile));
    } catch (e) {
      debugPrint('StudentProfileCubit: Unable to load profile - $e');
      emit(
        const StudentProfileError('Unable to load profile. Please try again.'),
      );
    }
  }
}
