import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/domain/entities/student.dart';
import 'package:equatable/equatable.dart';

abstract class StudentProfileEvent extends Equatable {
  const StudentProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends StudentProfileEvent {
  final AuthUser actor;

  const LoadProfileEvent(this.actor);

  @override
  List<Object?> get props => [actor];
}

class SetupProfileEvent extends StudentProfileEvent {
  final Student newStudent;
  final AuthUser actor;

  const SetupProfileEvent({required this.newStudent, required this.actor});

  /// Creates a [SetupProfileEvent] from raw form fields, applying business defaults.
  factory SetupProfileEvent.fromForm({
    required AuthUser user,
    required String mobile,
    required String motherPhone,
    required String fatherPhone,
    required String fatherOfConfession,
    required int grade,
    required EducationStage educationStage,
    required Group group,
    String? school,
    String? address,
  }) {
    final student = Student(
      uid: user.uid,
      docID: user.uid,
      name: user.name,
      role: user.role,
      mobile: mobile,
      group: group,
      teamName: 'غير محدد',
      classId: 'unassigned',
      motherPhone: motherPhone,
      fatherPhone: fatherPhone,
      grade: grade,
      educationStage: educationStage,
      school: school,
      address: address,
      fatherOfConfession: fatherOfConfession,
    );
    return SetupProfileEvent(newStudent: student, actor: user);
  }

  @override
  List<Object?> get props => [newStudent, actor];
}
