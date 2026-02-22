import 'package:church_managment_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:church_managment_system/features/auth/domain/failures/auth_exceptions.dart';
import 'package:church_managment_system/core/constants/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  bool get exists => true;
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockDb;
  late FirebaseAuthProvider provider;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockDb = MockFirebaseFirestore();
    provider = FirebaseAuthProvider(auth: mockAuth, db: mockDb);

    registerFallbackValue(const GetOptions());
    registerFallbackValue(SetOptions(merge: true));
  });

  group('Auth Caching', () {
    test(
      'getUserData should fetch from server once and then use cache',
      () async {
        final mockUser = MockUser();
        when(() => mockUser.uid).thenReturn('test-uid');
        when(() => mockUser.displayName).thenReturn('Test User');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.emailVerified).thenReturn(true);

        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();
        final mockSnapshot = MockDocumentSnapshot();

        when(() => mockDb.collection(any())).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
        when(() => mockDocRef.get(any())).thenAnswer((_) async => mockSnapshot);

        final userData = {
          'uid': 'test-uid',
          'name': 'Test User',
          'email': 'test@example.com',
          'role': 'student',
          'isEmailVerified': true,
        };
        when(() => mockSnapshot.data()).thenReturn(userData);

        // Call twice
        await provider.getUserData('test-uid');
        await provider.getUserData('test-uid');

        // Should be called exactly once total
        verify(() => mockDocRef.get(any())).called(1);
      },
    );

    test('getUserData forceRefresh should bypass cache', () async {
      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();

      when(() => mockDb.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
      when(() => mockDocRef.get(any())).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.data()).thenReturn(<String, dynamic>{
        'uid': 'test-uid',
        'name': 'Test User',
        'email': 'test@example.com',
        'role': 'student',
        'isEmailVerified': true,
      });

      await provider.getUserData('test-uid');
      await provider.getUserData('test-uid', forceRefresh: true);

      verify(() => mockDocRef.get(any())).called(2);
    });

    test(
      'createUser rolls back auth account when Firestore profile save fails',
      () async {
        final mockUser = MockUser();
        final mockCredential = MockUserCredential();
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(
          () => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockCredential);
        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockAuth.signOut()).thenAnswer((_) async {});

        when(() => mockUser.uid).thenReturn('new-uid');
        when(() => mockUser.email).thenReturn('new@example.com');
        when(() => mockUser.displayName).thenReturn('New User');
        when(() => mockUser.emailVerified).thenReturn(false);
        when(() => mockUser.delete()).thenAnswer((_) async {});

        when(() => mockDb.collection(any())).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
        when(
          () => mockDocRef.set(any(), any()),
        ).thenThrow(Exception('firestore write failed'));

        await expectLater(
          provider.createUser(
            email: 'new@example.com',
            password: 'Password123!',
            name: 'New User',
            role: UserRole.admin,
          ),
          throwsA(isA<GenericAuthException>()),
        );

        verify(() => mockUser.delete()).called(1);
        verify(() => mockAuth.signOut()).called(1);
        verifyNever(() => mockUser.sendEmailVerification());

        // If cache was retained incorrectly, this would return the app role (admin).
        expect(provider.currentUser?.role, UserRole.student);
      },
    );

    test(
      'createUser succeeds when verification email send fails after profile save',
      () async {
        final mockUser = MockUser();
        final mockCredential = MockUserCredential();
        final mockCollection = MockCollectionReference();
        final mockDocRef = MockDocumentReference();

        when(
          () => mockAuth.createUserWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockCredential);
        when(() => mockAuth.currentUser).thenReturn(mockUser);

        when(() => mockUser.uid).thenReturn('new-uid');
        when(() => mockUser.email).thenReturn('new@example.com');
        when(() => mockUser.displayName).thenReturn('New User');
        when(() => mockUser.emailVerified).thenReturn(false);
        when(
          () => mockUser.sendEmailVerification(),
        ).thenThrow(Exception('smtp unavailable'));

        when(() => mockDb.collection(any())).thenReturn(mockCollection);
        when(() => mockCollection.doc(any())).thenReturn(mockDocRef);
        when(() => mockDocRef.set(any(), any())).thenAnswer((_) async {});

        final user = await provider.createUser(
          email: 'new@example.com',
          password: 'Password123!',
          name: 'New User',
          role: UserRole.admin,
        );

        expect(user.uid, 'new-uid');
        expect(user.role, UserRole.admin);
        expect(provider.currentUser?.role, UserRole.admin);
        verify(() => mockDocRef.set(any(), any())).called(1);
        verify(() => mockUser.sendEmailVerification()).called(1);
        verifyNever(() => mockUser.delete());
      },
    );
  });
}
