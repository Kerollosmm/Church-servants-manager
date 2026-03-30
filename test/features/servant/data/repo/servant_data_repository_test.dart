import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ServantDataRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ServantDataRepository(firestore: firestore);
  });

  test('createServant persists lowercase name for search', () async {
    await repository.createServant(
      ServantModel(
        uid: 'servant-1',
        docID: 'servant-1',
        name: 'Mina George',
        role: UserRole.servant,
        email: 'servant@test.com',
        phone: '01234567890',
        imageUrl: null,
        teamName: 'Team 1',
        isEmailVerified: true,
        fatherOfConfession: 'Fr',
        birthdate: null,
        notes: null,
      ),
    );

    final doc = await firestore.collection('Users').doc('servant-1').get();
    expect(doc.data()!['nameLower'], 'mina george');
  });

  test('searchServants queries by normalized lowercase name', () async {
    await firestore.collection('Users').doc('servant-1').set({
      'uid': 'servant-1',
      'name': 'Mina George',
      'nameLower': 'mina george',
      'role': 'servant',
      'email': 'servant@test.com',
      'phone': '01234567890',
      'isEmailVerified': true,
      'teamName': 'Team 1',
    });

    final results = await repository.searchServants('MINA');
    expect(results, hasLength(1));
    expect(results.single.docID, 'servant-1');
  });
}
