import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/admin/data/admin_team_membership_service.dart';
import 'package:church_management_system/features/admin/data/admin_team_service.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/team/data/models/team_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late AdminTeamMembershipService membershipService;
  late AdminTeamService service;

  final admin = const AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    name: 'Admin',
    role: UserRole.admin,
    isEmailVerified: true,
  );

  final servantActor = const AuthUser(
    uid: 'servant-1',
    email: 'servant@example.com',
    name: 'Servant',
    role: UserRole.servant,
    isEmailVerified: true,
  );

  TeamModel createTeam({
    String id = 'team-1',
    String name = 'Team A',
    String groupId = 'year1',
    bool isArchived = false,
  }) {
    return TeamModel(
      id: id,
      name: name,
      groupId: groupId,
      isArchived: isArchived,
    );
  }

  Map<String, dynamic> createServantJson({
    String docID = 'servant-1',
    String name = 'Servant 1',
    String role = 'servant',
    String groupId = 'year1',
    List<String> assignedTeamIds = const [],
    bool isArchived = false,
  }) {
    return {
      'docID': docID,
      'name': name,
      'role': role,
      'groupId': groupId,
      'assignedTeamIds': assignedTeamIds,
      'isArchived': isArchived,
    };
  }

  ServantModel createServant({
    String docID = 'servant-1',
    String name = 'Servant 1',
    String uid = 'u1',
    String groupId = 'year1',
    List<String> assignedTeamIds = const [],
    bool isArchived = false,
  }) {
    return ServantModel(
      uid: uid,
      docID: docID,
      name: name,
      phone: '01234567890',
      teamName: groupId,
      assignedTeamIds: assignedTeamIds,
      isArchived: isArchived,
    );
  }

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    membershipService = AdminTeamMembershipService(firestore: mockFirestore);
    service = AdminTeamService(
      firestore: mockFirestore,
      membershipService: membershipService,
    );
  });

  group('AdminTeamService', () {
    group('assignServantToTeam', () {
      test('throws StateError when actor is not admin', () async {
        final team = createTeam();
        final servant = createServant();

        expect(
          () => service.assignServantToTeam(
            actor: servantActor,
            team: team.toDomain(),
            servant: servant.toDomain(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('admin only'),
            ),
          ),
        );
      });

      test('throws StateError when team is archived', () async {
        final team = createTeam(isArchived: true);
        final servant = createServant();

        await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .set(team.toMap());
        await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .set(createServantJson());

        expect(
          () => service.assignServantToTeam(
            actor: admin,
            team: team.toDomain(),
            servant: servant.toDomain(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('archived team'),
            ),
          ),
        );
      });

      test('throws StateError when servant is not a servant role', () async {
        final team = createTeam();
        final servant = createServant();

        await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .set(team.toMap());
        await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .set(createServantJson(role: 'student'));

        expect(
          () => service.assignServantToTeam(
            actor: admin,
            team: team.toDomain(),
            servant: servant.toDomain(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('not a servant'),
            ),
          ),
        );
      });

      test('throws StateError when servant is archived', () async {
        final team = createTeam();
        final servant = createServant(isArchived: true);

        await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .set(team.toMap());
        await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .set(createServantJson(isArchived: true));

        expect(
          () => service.assignServantToTeam(
            actor: admin,
            team: team.toDomain(),
            servant: servant.toDomain(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('servant is archived'),
            ),
          ),
        );
      });

      test('throws StateError when group mismatch', () async {
        final team = createTeam();
        final servant = createServant(groupId: 'year2');

        await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .set(team.toMap());
        await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .set(createServantJson(groupId: 'year2'));

        expect(
          () => service.assignServantToTeam(
            actor: admin,
            team: team.toDomain(),
            servant: servant.toDomain(),
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Cannot assign servant from group'),
            ),
          ),
        );
      });

      test('successfully assigns new servant and updates team', () async {
        final team = createTeam(id: 't1');
        final servant = createServant(docID: 's1');

        await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .set(team.toMap());
        await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .set(createServantJson(docID: 's1'));

        await service.assignServantToTeam(
          actor: admin,
          team: team.toDomain(),
          servant: servant.toDomain(),
        );

        final teamDoc = await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .get();
        expect(teamDoc.data()?['assignedServantId'], 's1');
        expect(teamDoc.data()?['assignedServantName'], 'Servant 1');

        final servantDoc = await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .get();
        expect(servantDoc.data()?['assignedTeamIds'], contains('t1'));
      });

      test('re-assigning same servant is idempotent', () async {
        final team = createTeam(id: 't1');
        final servant = createServant(docID: 's1', assignedTeamIds: ['t1']);

        await mockFirestore.collection('Classes').doc(team.id).set({
          ...team.toMap(),
          'assignedServantId': 's1',
          'assignedServantName': 'Servant 1',
        });
        await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .set(createServantJson(docID: 's1', assignedTeamIds: ['t1']));

        await service.assignServantToTeam(
          actor: admin,
          team: team.toDomain(),
          servant: servant.toDomain(),
        );

        final servantDoc = await mockFirestore
            .collection('Users')
            .doc(servant.docID)
            .get();
        // Should only contain it once
        expect(servantDoc.data()?['assignedTeamIds'], ['t1']);
      });

      test('updates previous servant when new servant is assigned', () async {
        final team = createTeam(id: 't1');
        final oldServant = createServant(
          docID: 's1',
          assignedTeamIds: ['t1', 't2'],
        );
        final newServant = createServant(docID: 's2');

        await mockFirestore.collection('Classes').doc(team.id).set({
          ...team.toMap(),
          'assignedServantId': 's1',
        });
        await mockFirestore
            .collection('Users')
            .doc(oldServant.docID)
            .set(createServantJson(docID: 's1', assignedTeamIds: ['t1', 't2']));
        await mockFirestore
            .collection('Users')
            .doc(newServant.docID)
            .set(createServantJson(docID: 's2'));

        await service.assignServantToTeam(
          actor: admin,
          team: team.toDomain(),
          servant: newServant.toDomain(),
        );

        final oldServantDoc = await mockFirestore
            .collection('Users')
            .doc(oldServant.docID)
            .get();
        expect(oldServantDoc.data()?['assignedTeamIds'], ['t2']); // t1 removed

        final newServantDoc = await mockFirestore
            .collection('Users')
            .doc(newServant.docID)
            .get();
        expect(newServantDoc.data()?['assignedTeamIds'], ['t1']); // t1 added
      });
    });

    group('unassignServantFromTeam', () {
      test(
        'successfully removes servant from team and updates servant doc',
        () async {
          final team = createTeam(id: 't1');
          final servant = createServant(docID: 's1', assignedTeamIds: ['t1']);

          await mockFirestore.collection('Classes').doc(team.id).set({
            ...team.toMap(),
            'assignedServantId': 's1',
            'assignedServantName': 'Servant 1',
          });
          await mockFirestore
              .collection('Users')
              .doc(servant.docID)
              .set(createServantJson(docID: 's1', assignedTeamIds: ['t1']));

          await service.unassignServantFromTeam(
            actor: admin,
            team: team.toDomain(),
          );

          final teamDoc = await mockFirestore
              .collection('Classes')
              .doc(team.id)
              .get();
          expect(teamDoc.data()?.containsKey('assignedServantId'), isFalse);
          expect(teamDoc.data()?.containsKey('assignedServantName'), isFalse);

          final servantDoc = await mockFirestore
              .collection('Users')
              .doc(servant.docID)
              .get();
          expect(
            servantDoc.data()?.containsKey('assignedTeamIds'),
            isFalse,
          ); // Empty list causes field deletion
        },
      );

      test('no-op when no previous servant exists', () async {
        final team = createTeam(id: 't1');
        await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .set(team.toMap());

        await service.unassignServantFromTeam(
          actor: admin,
          team: team.toDomain(),
        );

        final teamDoc = await mockFirestore
            .collection('Classes')
            .doc(team.id)
            .get();
        expect(teamDoc.data()?.containsKey('assignedServantId'), isFalse);
      });
    });
  });
}
