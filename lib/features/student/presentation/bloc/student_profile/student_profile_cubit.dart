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

      // Auto-create profile only for the authenticated student user.
      if (profile == null) {
        emit(const StudentProfileProvisioning());
        debugPrint(
          'StudentProfileCubit: provisioning profile for ${actor.uid}',
        );
        profile = _createDefaultProfile(actor);
        await _studentRepository.upsertStudent(profile);
      }

      emit(StudentProfileLoaded(profile));
    } catch (e) {
      debugPrint('StudentProfileCubit: Unable to load profile - $e');
      emit(
        const StudentProfileError('Unable to load profile. Please try again.'),
      );
    }
  }

  /// Creates a default StudentModel for a new student user.
  StudentModel _createDefaultProfile(AuthUser user) {
    return StudentModel(
      uid: user.uid,
      docID: user.uid, // Use UID as document ID for easy lookup
      name: user.name,
      imageUrl: null,
      role: UserRole.student,
      mobile: '',
      group: Group.year1,
      teamName: '',
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: '',
      notes: null,
      classId: Group.year1.name,
    );
  }
}
