import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/domain/repos/i_student_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_profile_state.dart';

class StudentProfileCubit extends Cubit<StudentProfileState> {
  final IStudentRepository _studentRepository;

  StudentProfileCubit({required IStudentRepository studentRepository})
    : _studentRepository = studentRepository,
      super(const StudentProfileInitial());

  Future<void> load(String linkedUserId) async {
    emit(const StudentProfileLoading());
    try {
      final normalizedLinkedUserId = linkedUserId.trim();
      if (normalizedLinkedUserId.isEmpty) {
        emit(const StudentProfileError('Unable to load profile.'));
        return;
      }

      final profile = await _studentRepository.getStudentByLinkedUserId(
        normalizedLinkedUserId,
      );
      if (profile == null) {
        emit(const StudentProfileError('Student profile not found.'));
        return;
      }

      emit(StudentProfileLoaded(profile));
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'StudentProfileCubit: Unable to load profile (${e.runtimeType})',
        );
      }
      emit(const StudentProfileError('Unable to load profile.'));
    }
  }
}
