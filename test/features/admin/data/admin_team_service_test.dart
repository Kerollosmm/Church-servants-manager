import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminTeamService service;

  const admin = AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  const team = TeamModel(
    id: 'team-1',
    name: 'Team A',
    groupId: 'year1',
    assignedServantId: 'servant-1',
    assignedServantName: 'Old Servant',
  );

  const newServant = ServantModel(
    docID: 'servant-2',
    uid: 'servant-2',
    name: 'New Servant',
    role: UserRole.servant,
    teamName: 'year1',
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = AdminTeamService(firestore: firestore);

    await firestore.collection('Classes').doc(team.id).set({
      'name': team.name,
      'groupId': team.groupId,
      'assignedServantId': 'servant-1',
      'assignedServantName': 'Old Servant',
      'isArchived': false,
    });

    await firestore.collection('Users').doc('servant-1').set({
      'uid': 'servant-1',
      'name': 'Old Servant',
      'role': 'servant',
      'groupId': 'year1',
      'assignedTeamId': 'team-1',
      'assignedTeamIds': ['team-1'],
    });

    await firestore.collection('Users').doc(newServant.docID).set({
      'uid': newServant.uid,
      'name': newServant.name,
      'role': 'servant',
      'groupId': 'year1',
      'assignedTeamIds': ['team-2'],
    });
  });

  test('assignServantToTeam reassigns team without reading after writes', () async {
    await service.assignServantToTeam(
      actor: admin,
      team: team,
      servant: newServant,
    );

    final teamDoc = await firestore.collection('Classes').doc(team.id).get();
    final oldServantDoc = await firestore.collection('Users').doc('servant-1').get();
    final newServantDoc = await firestore
        .collection('Users')
        .doc(newServant.docID)
        .get();

    expect(teamDoc.data()!['assignedServantId'], newServant.docID);
    expect(teamDoc.data()!['assignedServantName'], newServant.name);
    expect(oldServantDoc.data()!['assignedTeamId'], isNull);
    expect(oldServantDoc.data()!['assignedTeamIds'], isNull);
    expect(
      List<String>.from(newServantDoc.data()!['assignedTeamIds'] as List),
      containsAll(<String>['team-1', 'team-2']),
    );
    expect(newServantDoc.data()!['assignedTeamId'], 'team-2');
  });
}
