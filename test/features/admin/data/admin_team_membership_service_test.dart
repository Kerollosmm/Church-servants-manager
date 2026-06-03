import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late AdminTeamMembershipService service;

  final admin = const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  TeamModel team({bool isArchived = false}) => TeamModel(
    id: 'team-1',
    name: 'Team A',
    groupId: 'year1',
    isArchived: isArchived,
  );

  StudentModel student({
    required String id,
    String? classId,
    String? teamName,
    bool isArchived = false,
    String uid = 'u1',
  }) {
    return StudentModel(
      uid: uid,
      docID: id,
      name: 'Student $id',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: teamName ?? 'Team A',
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: '',
      notes: null,
      classId: classId,
      isArchived: isArchived,
    );
  }

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    service = AdminTeamMembershipService(firestore: mockFirestore);
  });

  group('setStudentsForTeam', () {
    test('assigns students to an empty team', () async {
      final s1 = student(id: 's1', teamName: '');

      // Pre-seed the fake firestore with the student
      await mockFirestore.collection('Students').doc('s1').set(s1.toMap());

      await service.setStudentsForTeam(
        actor: admin,
        team: team().toDomain(),
        selectedStudents: [s1.toDomain()],
      );

      // Verify assignment in Firestore
      final updatedStudent = await mockFirestore
          .collection('Students')
          .doc('s1')
          .get();
      expect(updatedStudent.data()?['classId'], 'team-1');
      expect(updatedStudent.data()?['team_name'], 'Team A');
    });

    test('throws when actor is not admin', () async {
      final servant = const AuthUser(
        uid: 'servant-1',
        email: 's@example.com',
        name: 'Servant',
        role: UserRole.servant,
        isEmailVerified: true,
      );

      expect(
        () => service.setStudentsForTeam(
          actor: servant,
          team: team().toDomain(),
          selectedStudents: [],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
