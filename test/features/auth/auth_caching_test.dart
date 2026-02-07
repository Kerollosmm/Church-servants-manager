import 'package:church_managment_system/features/auth/data/models/auth_user.dart';
import 'package:church_managment_system/features/auth/data/services/firebase_auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUser extends Mock implements User {}
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}
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
  });

  group('Auth Caching', () {
    test('getUserData should fetch from server once and then use cache', () async {
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
    });
  });
}
