import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/admin/utils/data_seeder.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late DataSeeder seeder;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(() => mockUser.uid).thenReturn('test_uid_123');
    when(() => mockUser.email).thenReturn('testuser@example.com');
    when(() => mockUser.displayName).thenReturn('Test User');
    when(() => mockUser.emailVerified).thenReturn(true);

    seeder = DataSeeder(firestore: fakeFirestore, auth: mockAuth);
  });

  group('DataSeeder Debug Role Assignment', () {
    test('assignMeAsAdmin throws StateError when not signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(() => seeder.assignMeAsAdmin(), throwsA(isA<StateError>()));
    });

    test('assignMeAsAdmin successfully sets user role to admin', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await seeder.assignMeAsAdmin();

      final doc = await fakeFirestore
          .collection(FirestoreCollections.servants)
          .doc('test_uid_123')
          .get();

      expect(doc.exists, isTrue);
      final data = doc.data()!;
      expect(data['uid'], 'test_uid_123');
      expect(data['email'], 'testuser@example.com');
      expect(data['name'], 'Test User');
      expect(data['role'], UserRole.admin.name);
      expect(data['isEmailVerified'], isTrue);
    });

    test('assignMeAsTeacher throws StateError when not signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => seeder.assignMeAsTeacher(group: Group.year1),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'assignMeAsTeacher successfully sets user role to teacher/servant',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        await seeder.assignMeAsTeacher(group: Group.year1);

        final doc = await fakeFirestore
            .collection(FirestoreCollections.servants)
            .doc('test_uid_123')
            .get();

        expect(doc.exists, isTrue);
        final data = doc.data()!;
        expect(data['uid'], 'test_uid_123');
        expect(data['email'], 'testuser@example.com');
        expect(data['name'], 'Test User');
        expect(data['role'], UserRole.servant.name);
        expect(data['group'], Group.year1.name);
        expect(data['groupId'], Group.year1.name);
      },
    );

    test('assignMeAsStudentAndCreateProfile throws StateError when not signed in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => seeder.assignMeAsStudentAndCreateProfile(),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'assignMeAsStudentAndCreateProfile creates user and student profile',
      () async {
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        await seeder.assignMeAsStudentAndCreateProfile(group: Group.year2);

        final userDoc = await fakeFirestore
            .collection(FirestoreCollections.servants)
            .doc('test_uid_123')
            .get();

        expect(userDoc.exists, isTrue);
        final userData = userDoc.data()!;
        expect(userData['role'], UserRole.student.name);
        expect(userData['email'], 'testuser@example.com');

        final studentDoc = await fakeFirestore
            .collection(FirestoreCollections.students)
            .doc('test_uid_123')
            .get();

        expect(studentDoc.exists, isTrue);
        final studentData = studentDoc.data()!;
        expect(studentData['uid'], 'test_uid_123');
        expect(studentData['name'], 'Test User');
        expect(studentData['group'], Group.year2.name);
        expect(studentData['grade'], 2);
      },
    );
  });
}
