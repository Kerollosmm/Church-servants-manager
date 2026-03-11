import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/servant/data/models/servant_models.dart';
import 'package:church_management_system/features/servant/data/repo/servant_data_repository.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ServantDataRepository repository;

  ServantModel buildServant({String name = 'Servant Mina'}) {
    return ServantModel(
      uid: 'servant-1',
      docID: 'servant-1',
      name: name,
      role: UserRole.servant,
      email: 'servant@example.com',
      phone: '01234567890',
      teamName: 'year1',
    );
  }

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ServantDataRepository(firestore: firestore);
  });

  test('createServant writes createdAt and updatedAt', () async {
    await repository.createServant(buildServant());

    final doc = await firestore.collection('Users').doc('servant-1').get();
    expect(doc.data()!['createdAt'], isNotNull);
    expect(doc.data()!['updatedAt'], isNotNull);
  });

  test('updateServant preserves createdAt while refreshing updatedAt', () async {
    final existingCreatedAt = DateTime(2026, 3, 1, 10, 0);
    await firestore.collection('Users').doc('servant-1').set({
      ...buildServant().toMap(),
      'role': UserRole.servant.name,
      'createdAt': existingCreatedAt,
      'updatedAt': existingCreatedAt,
    });

    await repository.updateServant(buildServant(name: 'Updated Servant'));

    final doc = await firestore.collection('Users').doc('servant-1').get();
    final createdAt = doc.data()!['createdAt'] as Timestamp;
    expect(doc.data()!['name'], 'Updated Servant');
    expect(createdAt.toDate(), existingCreatedAt);
    expect(doc.data()!['updatedAt'], isNotNull);
  });
}
