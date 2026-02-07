import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/data/repos/student_data_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'student_profile_event.dart';
part 'student_profile_state.dart';

class StudentProfileBloc
    extends Bloc<StudentProfileEvent, StudentProfileState> {
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

      var profile = await _studentRepository.getStudentByUid(event.actor.uid);

      // Auto-create profile if student user doesn't have one yet
      if (profile == null) {
        debugPrint(
          'StudentProfileBloc: No profile found, creating default profile for ${event.actor.uid}',
        );
        profile = _createDefaultProfile(event.actor);
        await _studentRepository.upsertStudent(profile);
      }

      emit(StudentProfileLoaded(profile));
    } catch (e) {
      debugPrint('StudentProfileBloc: Unable to load profile - $e');
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
