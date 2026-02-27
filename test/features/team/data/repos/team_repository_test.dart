import 'package:church_managment_system/core/constants/firestore_collections.dart';
import 'package:church_managment_system/features/team/data/models/team_model.dart';
import 'package:church_managment_system/features/team/data/repos/team_repository.dart';
import 'package:church_managment_system/features/team/domain/failures/team_failures.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late TeamRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = TeamRepository(firestore: fakeFirestore);
  });

  group('TeamRepository - Unit Tests', () {
    final tTeam1 = TeamModel(id: 'team_1', name: 'Alpha', groupId: 'year1');
    final tTeam2 = TeamModel(id: 'team_2', name: 'Beta', groupId: 'year1');

    test(
      'createTeam should add a document to Firestore and return ID',
      () async {
        final id = await repository.createTeam(tTeam1);

        expect(id, isNotEmpty);
        final doc = await fakeFirestore
            .collection(FirestoreCollections.classes)
            .doc(id)
            .get();
        expect(doc.exists, true);
        expect(doc.data()!['name'], 'Alpha');
      },
    );

    test('getTeamById should return correct TeamModel', () async {
      await fakeFirestore
          .collection(FirestoreCollections.classes)
          .doc(tTeam1.id)
          .set(tTeam1.toMap());

      final result = await repository.getTeamById(tTeam1.id);

      expect(result, isNotNull);
      expect(result!.id, tTeam1.id);
      expect(result.name, tTeam1.name);
    });

    test(
      'getTeamsByGroup should retrieve from cache or server properly ordered',
      () async {
        await fakeFirestore
            .collection(FirestoreCollections.classes)
            .doc(tTeam2.id)
            .set(tTeam2.toMap());
        await fakeFirestore
            .collection(FirestoreCollections.classes)
            .doc(tTeam1.id)
            .set(tTeam1.toMap());

        final teams = await repository.getTeamsByGroup('year1');

        expect(teams.length, 2);
        // Alpha should be first due to ordering by name
        expect(teams[0].name, 'Alpha');
        expect(teams[1].name, 'Beta');
      },
    );

    test('updateTeam should modify existing data successfully', () async {
      await fakeFirestore
          .collection(FirestoreCollections.classes)
          .doc(tTeam1.id)
          .set(tTeam1.toMap());

      final updatedTeam = tTeam1.copyWith(name: 'Alpha Updated');
      await repository.updateTeam(updatedTeam);

      final doc = await fakeFirestore
          .collection(FirestoreCollections.classes)
          .doc(tTeam1.id)
          .get();
      expect(doc.data()!['name'], 'Alpha Updated');
    });

    test('watchTeamsByGroup stream should emit updates instantly', () async {
      // 1. Initial snapshot has no teams
      final snapshot1 = await repository.watchTeamsByGroup('year1').first;
      expect(snapshot1.isEmpty, true);

      // 2. Add team
      await repository.createTeam(tTeam1);

      // 3. Next snapshot should reflect addition
      final snapshot2 = await repository.watchTeamsByGroup('year1').first;
      expect(snapshot2.length, 1);
      expect(snapshot2[0].name, 'Alpha');
    });

    test('deleteTeam should remove the document', () async {
      final docRef = fakeFirestore
          .collection(FirestoreCollections.classes)
          .doc(tTeam1.id);
      await docRef.set(tTeam1.toMap());

      await repository.deleteTeam(tTeam1.id);

      final doc = await docRef.get();
      expect(doc.exists, false);
    });
  });
}
