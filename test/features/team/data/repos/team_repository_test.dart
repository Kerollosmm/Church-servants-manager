import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:church_management_system/features/team/data/repos/team_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late TeamRepository repository;

  StudentModel student({
    required String id,
    required String uid,
    required String teamId,
    required String teamName,
  }) {
    return StudentModel(
      uid: uid,
      docID: id,
      name: 'Mina',
      imageUrl: null,
      role: UserRole.student,
      mobile: '01234567890',
      group: Group.year1,
      teamName: teamName,
      motherPhone: '',
      fatherPhone: '',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: null,
      address: null,
      birthdate: null,
      fatherOfConfession: 'Fr',
      notes: null,
      classId: teamId,
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = TeamRepository(firestore: firestore);
  });

  test('updateTeam propagates team name and group to linked students and users', () async {
    const originalTeam = TeamModel(id: 'team-1', name: 'Old Team', groupId: 'year1');
    const updatedTeam = TeamModel(id: 'team-1', name: 'New Team', groupId: 'year2');

    await firestore.collection('Classes').doc(originalTeam.id).set(originalTeam.toMap());
    await firestore.collection('Students').doc('student-1').set(
      student(
        id: 'student-1',
        uid: 'user-1',
        teamId: originalTeam.id,
        teamName: originalTeam.name,
      ).toMap(),
    );
    await firestore.collection('Users').doc('user-1').set({
      'uid': 'user-1',
      'name': 'Mina',
      'email': 'mina@example.com',
      'role': 'student',
      'classId': originalTeam.id,
      'team_name': originalTeam.name,
      'groupId': originalTeam.groupId,
      'isEmailVerified': false,
    });

    await repository.updateTeam(updatedTeam);

    final studentDoc = await firestore.collection('Students').doc('student-1').get();
    final userDoc = await firestore.collection('Users').doc('user-1').get();

    expect(studentDoc.data()!['team_name'], updatedTeam.name);
    expect(studentDoc.data()!['group'], updatedTeam.groupId);
    expect(userDoc.data()!['team_name'], updatedTeam.name);
    expect(userDoc.data()!['groupId'], updatedTeam.groupId);
  });

  test('deleteTeam archives the team even when students are still assigned', () async {
    const team = TeamModel(id: 'team-1', name: 'Team', groupId: 'year1');
    await firestore.collection('Classes').doc(team.id).set(team.toMap());
    await firestore.collection('Students').doc('student-1').set(
      student(id: 'student-1', uid: 'user-1', teamId: team.id, teamName: team.name)
          .toMap(),
    );

    await repository.deleteTeam(team.id);

    final teamDoc = await firestore.collection('Classes').doc(team.id).get();
    expect(teamDoc.data()!['isArchived'], isTrue);
  });

  test('deleteTeam archives the team when attendance history exists', () async {
    const team = TeamModel(id: 'team-1', name: 'Team', groupId: 'year1');
    await firestore.collection('Classes').doc(team.id).set(team.toMap());
    await firestore
        .collection('Classes')
        .doc(team.id)
        .collection('attendance_sessions')
        .doc('session-1')
        .set({'teamId': team.id});

    await repository.deleteTeam(team.id);

    final teamDoc = await firestore.collection('Classes').doc(team.id).get();
    expect(teamDoc.data()!['isArchived'], isTrue);
  });

  test('deleteTeam clears assigned servant references and archives team', () async {
    const team = TeamModel(
      id: 'team-1',
      name: 'Team',
      groupId: 'year1',
      assignedServantId: 'servant-1',
      assignedServantName: 'Servant',
    );
    await firestore.collection('Classes').doc(team.id).set(team.toMap());
    await firestore.collection('Users').doc('servant-1').set({
      'uid': 'servant-1',
      'name': 'Servant',
      'email': 'servant@example.com',
      'role': 'servant',
      'assignedTeamIds': ['team-1', 'team-2'],
      'assignedTeamId': 'team-1',
      'isEmailVerified': true,
    });

    await repository.deleteTeam(team.id);

    final teamDoc = await firestore.collection('Classes').doc(team.id).get();
    final servantDoc = await firestore.collection('Users').doc('servant-1').get();

    expect(teamDoc.exists, isTrue);
    expect(teamDoc.data()!['isArchived'], isTrue);
    expect(List<String>.from(servantDoc.data()!['assignedTeamIds']), ['team-2']);
    expect(servantDoc.data()!['assignedTeamId'], 'team-2');
  });

  test('restoreTeam marks team active again without servant assignment', () async {
    const team = TeamModel(
      id: 'team-1',
      name: 'Team',
      groupId: 'year1',
      isArchived: true,
    );
    await firestore.collection('Classes').doc(team.id).set(team.toMap());

    await repository.restoreTeam(team.id);

    final teamDoc = await firestore.collection('Classes').doc(team.id).get();
    expect(teamDoc.data()!['isArchived'], isFalse);
    expect(teamDoc.data()!['assignedServantId'], isNull);
  });
}
