import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminTeamMembershipService service;

  const actor = AuthUser(
    uid: 'admin-1',
    email: 'admin@test.com',
    name: 'Admin',
    role: UserRole.admin,
  );

  StudentModel student({
    required String id,
    required String uid,
    String? classId,
  }) {
    return StudentModel(
      uid: uid,
      docID: id,
      name: 'Student $id',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: classId ?? '',
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: 'Fr',
      notes: null,
      classId: classId,
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    service = AdminTeamMembershipService(firestore: firestore);
  });

  test(
    'setStudentsForTeam updates team projection and actor metadata',
    () async {
      const team = TeamModel(id: 'team-1', name: 'Team 1', groupId: 'year1');
      await firestore.collection('Classes').doc(team.id).set(team.toMap());
      final selected = student(id: 'student-1', uid: 'user-1');
      await firestore
          .collection('Students')
          .doc(selected.docID)
          .set(selected.toMap());
      await firestore.collection('Users').doc(selected.uid).set({
        'uid': selected.uid,
        'role': 'student',
        'email': 'student@test.com',
        'name': 'Student 1',
      });

      await service.setStudentsForTeam(
        actor: actor,
        team: team,
        selectedStudents: [selected],
      );

      final teamDoc = await firestore.collection('Classes').doc(team.id).get();
      final studentDoc = await firestore
          .collection('Students')
          .doc(selected.docID)
          .get();
      final userDoc = await firestore
          .collection('Users')
          .doc(selected.uid)
          .get();

      expect(List<String>.from(teamDoc.data()!['student_ids']), ['student-1']);
      expect(teamDoc.data()!['membersUpdatedByUserId'], actor.uid);
      expect(studentDoc.data()!['membershipUpdatedByUserId'], actor.uid);
      expect(userDoc.data()!['membershipUpdatedByUserId'], actor.uid);
    },
  );
}
