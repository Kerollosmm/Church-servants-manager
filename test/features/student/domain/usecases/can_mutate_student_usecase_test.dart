import 'package:church_managment_system/core/constants/enums.dart';
import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/student/data/models/student_model.dart';
import 'package:church_managment_system/features/student/domain/usecases/can_mutate_student_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const useCase = CanMutateStudentUseCase();

  StudentModel buildStudent({required String classId, required Group group}) =>
      StudentModel(
        uid: 'student-1',
        docID: 'student-1',
        name: 'Student',
        imageUrl: null,
        role: UserRole.student,
        mobile: '0100000000',
        group: group,
        teamName: 'Team',
        motherPhone: '0100000000',
        fatherPhone: '0100000000',
        grade: 1,
        educationStage: EducationStage.preparatory,
        school: null,
        address: null,
        birthdate: null,
        fatherOfConfession: 'Fr.',
        notes: null,
        classId: classId,
      );

  test('admin can mutate any student', () {
    const actor = AuthUser(
      uid: 'admin-1',
      email: 'admin@test.com',
      name: 'Admin',
      role: UserRole.admin,
    );
    final student = buildStudent(classId: 'team-a', group: Group.year1);

    expect(useCase(actor, student), isTrue);
  });

  test('servant with assigned teams is constrained by classId', () {
    const actor = AuthUser(
      uid: 'servant-1',
      email: 'servant@test.com',
      name: 'Servant',
      role: UserRole.servant,
      groupId: 'year1',
      assignedTeamIds: ['team-a'],
    );
    final allowed = buildStudent(classId: 'team-a', group: Group.year2);
    final denied = buildStudent(classId: 'team-b', group: Group.year1);

    expect(useCase(actor, allowed), isTrue);
    expect(useCase(actor, denied), isFalse);
  });

  test('servant without assigned teams falls back to group scope', () {
    const actor = AuthUser(
      uid: 'servant-2',
      email: 'servant2@test.com',
      name: 'Servant 2',
      role: UserRole.servant,
      groupId: 'year3',
    );
    final allowed = buildStudent(classId: 'team-x', group: Group.year3);
    final denied = buildStudent(classId: 'team-x', group: Group.year1);

    expect(useCase(actor, allowed), isTrue);
    expect(useCase(actor, denied), isFalse);
  });
}
