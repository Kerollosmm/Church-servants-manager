import 'package:church_management_system/core/constants/enums.dart';
import 'package:church_management_system/core/constants/firestore_collections.dart';
import 'package:church_management_system/features/student/data/models/student_model.dart';
import 'package:church_management_system/features/student/data/services/student_linked_user_sync_service.dart';
import 'package:church_management_system/features/student/domain/failures/student_failures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockStudentsCollection;
  late MockCollectionReference mockUsersCollection;
  late MockDocumentReference mockStudentDoc;
  late MockDocumentReference mockUserDoc;
  late MockWriteBatch mockBatch;
  late StudentLinkedUserSyncService syncService;

  setUpAll(() {
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue(MockDocumentReference());
  });

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockStudentsCollection = MockCollectionReference();
    mockUsersCollection = MockCollectionReference();
    mockStudentDoc = MockDocumentReference();
    mockUserDoc = MockDocumentReference();
    mockBatch = MockWriteBatch();

    when(
      () => mockFirestore.collection(FirestoreCollections.students),
    ).thenReturn(mockStudentsCollection);
    when(
      () => mockFirestore.collection(FirestoreCollections.servants),
    ).thenReturn(mockUsersCollection);

    when(() => mockStudentsCollection.doc(any())).thenReturn(mockStudentDoc);
    when(() => mockUsersCollection.doc(any())).thenReturn(mockUserDoc);

    when(() => mockFirestore.batch()).thenReturn(mockBatch);
    when(
      () => mockBatch.update(any(), any<Map<String, dynamic>>()),
    ).thenReturn(null);
    when(
      () =>
          mockBatch.set(any(), any<Map<String, dynamic>>(), any<SetOptions>()),
    ).thenReturn(null);
    when(() => mockBatch.commit()).thenAnswer((_) async => []);

    syncService = StudentLinkedUserSyncService(firestore: mockFirestore);
  });

  /// Note: StudentModel.uid is non-nullable.
  /// The app uses a blank string ('') to represent the "no-linked-user" state.
  StudentModel createMockStudent({
    required String uid,
    required String name,
    UserRole role = UserRole.student,
    Group group = Group.year1,
    String? classId,
  }) {
    return StudentModel(
      uid: uid,
      docID: 'student_123',
      name: name,
      imageUrl: null,
      role: role,
      mobile: '1234567890',
      group: group,
      teamName: 'teamA',
      motherPhone: '0987654321',
      fatherPhone: '1122334455',
      grade: 1,
      educationStage: EducationStage.preparatory,
      school: 'School',
      address: 'Address',
      birthdate: DateTime(2010),
      fatherOfConfession: 'Abouna',
      notes: null,
      classId: classId,
    );
  }

  group('StudentLinkedUserSyncService Tests - updateStudentAndSyncLinkedUserRole', () {
    test(
      '1. student name and email change updates linked Users doc metadata',
      () async {
        final student = createMockStudent(uid: 'user_123', name: 'New Name');

        await syncService.updateStudentAndSyncLinkedUserRole(
          updatedStudent: student,
          previousRole: UserRole.student,
          updatedEmail: 'new@email.com',
        );

        final capturedSet = verify(
          () => mockBatch.set(
            mockUserDoc,
            captureAny<Map<String, dynamic>>(),
            captureAny<SetOptions>(),
          ),
        ).captured;

        final payload = capturedSet[0] as Map<String, dynamic>;
        expect(payload['name'], 'New Name');
        expect(payload['email'], 'new@email.com');

        verify(
          () => mockBatch.update(mockStudentDoc, student.toMap()),
        ).called(1);
        verify(() => mockBatch.commit()).called(1);
      },
    );

    test(
      '2. no linked user (uid blank) performs no user sync and directly updates student',
      () async {
        // UID is blank representing no-linked-user
        final student = createMockStudent(uid: '', name: 'Will Not Sync');

        when(
          () => mockStudentDoc.update(any<Map<String, dynamic>>()),
        ).thenAnswer((_) async => {});

        await syncService.updateStudentAndSyncLinkedUserRole(
          updatedStudent: student,
          previousRole: UserRole.student,
        );

        verifyNever(() => mockFirestore.batch());
        verifyNever(() => mockUsersCollection.doc(any()));
        verify(() => mockStudentDoc.update(student.toMap())).called(1);
      },
    );

    test('3. Firestore write failure is mapped to StudentFailure', () async {
      final student = createMockStudent(
        uid: 'user_123',
        name: 'Failing Update',
      );

      when(() => mockBatch.commit()).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );

      expect(
        () => syncService.updateStudentAndSyncLinkedUserRole(
          updatedStudent: student,
          previousRole: UserRole.student,
        ),
        throwsA(isA<StudentFailure>()),
      );
    });

    test(
      '4. concurrent sync calls rely on idempotency (deduplication not strictly blocked by service)',
      () async {
        // Because the service uses Firestore batches with merge: true, duplicate requests
        // write safely over each other without creating multiple user documents.
        // We explicitly assert that the service issues the expected number of idempotent writes
        // rather than blocking concurrent attempts.
        final student = createMockStudent(
          uid: 'user_123',
          name: 'Concurrent Update',
        );

        await Future.wait([
          syncService.updateStudentAndSyncLinkedUserRole(
            updatedStudent: student,
            previousRole: UserRole.student,
          ),
          syncService.updateStudentAndSyncLinkedUserRole(
            updatedStudent: student,
            previousRole: UserRole.student,
          ),
        ]);

        verify(
          () => mockBatch.set(
            mockUserDoc,
            any<Map<String, dynamic>>(),
            any<SetOptions>(),
          ),
        ).called(2);
        verify(() => mockBatch.commit()).called(2);
      },
    );
  });
}
