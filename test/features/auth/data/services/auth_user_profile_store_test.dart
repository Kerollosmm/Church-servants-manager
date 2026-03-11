import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/features/auth/data/models/auth_user.dart';
import 'package:church_management_system/features/auth/data/services/auth_user_profile_store.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late AuthUserProfileStore store;

  const user = AuthUser(
    uid: 'user-1',
    email: 'user@example.com',
    name: 'User',
    role: UserRole.student,
    isEmailVerified: false,
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    store = AuthUserProfileStore(firestore: firestore);
  });

  test('saveUser writes createdAt for first-time profiles and preserves it later', () async {
    await store.saveUser(user);

    final firstDoc = await firestore.collection('Users').doc(user.uid).get();
    final firstCreatedAt = firstDoc.data()!['createdAt'] as Timestamp;
    expect(firstCreatedAt, isNotNull);
    expect(firstDoc.data()!['updatedAt'], isNotNull);

    await store.saveUser(user.copyWith(name: 'Updated User'));

    final secondDoc = await firestore.collection('Users').doc(user.uid).get();
    final secondCreatedAt = secondDoc.data()!['createdAt'] as Timestamp;
    expect(secondDoc.data()!['name'], 'Updated User');
    expect(secondCreatedAt.toDate(), firstCreatedAt.toDate());
    expect(secondDoc.data()!['updatedAt'], isNotNull);
  });
}
